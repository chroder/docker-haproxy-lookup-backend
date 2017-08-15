# About

This container runs an HAProxy instance with a custom Lua script that looks up
the request domain against an API to decide which backend to use. The result
can optionally be cached locally to improve subsequent requests.

* Source on Github: https://github.com/chroder/docker-haproxy-lookup-backend
* Image on Docker Hub: https://hub.docker.com/r/chroder/haproxy-lookup-backend/~/settings/automated-builds/
* Issues: https://github.com/chroder/docker-haproxy-lookup-backend/issues

# Build

(1.) Create your own `haproxy.cfg` file. Use the default one as an example.

(2.) Create your own `backend-lookup-config.lua` file to define the lookup service.
   See below for info about the lookup service.

(3.) Build the container:

```
docker build -t haproxy-lookup-backend .
```

(4.) Run the container:

```
# http://localhost:4000/ -> haproxy port 80
docker run -p 4000:80 haproxy-lookup-backend
```

# Quick Run

You can mount the config files so you don't need to rebuild every time you run.
Useful for testing.

```
docker run -p 4000:80 \
  -v `pwd`/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg \
  -v `pwd`/backend-lookup.lua:/usr/local/etc/haproxy/backend-lookup.lua \
  haproxy-lookup-backend
```

# Lookup Service

* MUST accept a query paramter named `domain`
* MUST return `k=v` pairs, one per line
* MUST return a `backend_name` key, which is the name of the backend to use
* MAY return any other key-value pairs. These will be added to the request as custom headers.

Example request:

```
Host: my-api.example.com
GET /lookup.txt?domain=foobar.com
```

Example response:

```
backend_name = php7_backend
x-custom-header = value
x-something-else = value
```
