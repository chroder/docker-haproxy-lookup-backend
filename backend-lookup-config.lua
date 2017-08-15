local config = {
  -- The API endpoint to hit. It will be called liket his:
  --
  --     GET http://127.0.0.1:5666/backend-lookup.txt?domain=example.com
  --
  -- The API must return PLAIN TEXT with k=v pairs one per line:
  --
  --     backend_name = The backend name
  --     x-foo-bar = custom header
  --
  -- Only backend_name is required. Any other vars provided will be passed
  -- on as custom headers.
  api_endpoint = "http://127.0.0.1:5666/backend-lookup.txt";

  -- Store this many of the last requested lookups
  cache_size = 500;

  -- The max age (when using the cache)
  set_max_age = 5;

  -- The backend to use if the API call fails
  -- or contians an invalid result
  default_backend_name = "offline";

  -- Custom request headers to send with the request (e.g. auth)
  request_headers = {}
}

return config
