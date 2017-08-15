HAProxy only logs to stdout. This is a simple wrapper that implements syslog and
redirects all logs to stdout for docker to handle normally.

You can modify `ENTRYPOINT` value in the Dockerfile to remove the syslog-init call if you
have your own syslog server capable of accepting logs (make sure you set the proper `log` directive in `haproxy.cfg` too).

This wrapper is written by [@yosifkit](https://github.com/yosifkit). See https://github.com/yosifkit/syslog-init.
