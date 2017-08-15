require "luarocks.loader"

if core then
  config = require "/usr/local/etc/haproxy/backend-lookup-config"
else
  config = require("backend-lookup-config")
end

log_levels = {
  debug = 7;
  info = 6;
  notice = 5;
  warning = 4;
  err = 3;
  crit = 2;
  alert = 1;
  emerg = 0;
}

lru = require 'lru'
cache = lru.new(config.cache_size)

-- Logs a message
--
-- @param int    loglevel The log level (one of log_levels)
-- @param stirng msg      The message
function log(txn, loglevel, msg)
  if txn then
    txn:log(loglevel, msg)
  elseif core then
    core.log(loglevel, msg)
  else
    print("[log:"..loglevel.."] " .. string.gsub(msg, "\n", "\\n"))
  end
end


-- Lookup a domain.
--
-- The return array contains two keys:
-- * string backend_name  The name of the backend to use
-- * array  pass_headers  An array of all other values to pass as headers
--
-- @param TXN txn The transaction from haproxy
-- @param string domain The domain to Lookup
-- @return array
function lookup(txn, domain)
  log(txn, log_levels.debug, "Lookup: "..domain);

  if config.cache_size then
    local cached_result = cache:get(domain)
    if cached_result then
      if cached_result.expire_time > os.time() then
        log(txn, log_levels.debug, "Cache hit");
        return cached_result
      else
        cache:delete(domain)
      end
    end
  end

  local headers = config.request_headers
  headers["Accept"] = "text/plain"

  local http_request = require "http.request"
  local req = http_request.new_from_uri(config.api_endpoint.."?domain="..domain)
  for k,v in pairs(headers) do req.headers[k] = v end

  local res_headers, res_stream = assert(req:go())
  local body = assert(res_stream:get_body_as_string())

  log(txn, log_levels.debug, body);
  if res_headers:get ":status" ~= "200" then
    error(body)
  end

  local pass_headers = {}
  local backend_name = nil

  local body = body .. "\n"
  for name, value in string.gmatch(body, "%s*(.-)%s*=%s*(.-)%s*\n") do
    if name == "backend_name" then
      backend_name = value
    else
      pass_headers[name] = value
    end
  end

   if not backend_name then
     error("Response is missing any backend:\n-------\n" .. body)
   end

   local lookup_result = {
     backend_name = backend_name;
     pass_headers = pass_headers;
   }

   if config.cache_size then
     lookup_result.expire_time = os.time() + config.set_max_age;
     cache:set(domain, lookup_result)
   end

   return lookup_result
end

-- Called by haproxy to lookup the request
--
-- @param array txn
function lookup_txn(txn)
  local domain = txn.sf:hdr('host')
  local result, err = pcall(function() lookup(txn, domain) end)

  if result then
    txn:set_var('txn.backend_name', config.default_backend_name)
    for name, value in pairs(result.pass_headers) do
      txn.http:req_add_header(name, value)
    end
  else
    txn:set_var('txn.backend_name', config.default_backend_name)
    txn:set_var('txn.backend_lookup_fail', '1')
    log(txn, log_levels.warning, "Lookup failure on " .. domain .. ": " .. err .. "; setting backend to: " .. config.default_backend_name)
  end
end

if core then
  core.register_action("lookup_txn", { "http-req" }, lookup_txn)
else
  local result = lookup(null, arg[1])
  print("API Endpoint: ", config.api_endpoint)
  print("Looking up:   ", arg[1])
  print("backend_name: ", result.backend_name)
  print("Other headers:")
  for name, value in pairs(result.pass_headers) do
    print("\t" .. name .. ":" .. value)
  end
end
