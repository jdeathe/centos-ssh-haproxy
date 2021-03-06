# Change Log

## 2 - centos-7

Summary of release changes.

### 2.3.1 - 2019-10-10

- Deprecate Makefile target `logs-delayed`; replaced with `logsdef`.
- Updates `rsyslog` package to 8.24.0-41.el7_7.
- Updates source image to [2.6.1](https://github.com/jdeathe/centos-ssh/releases/tag/2.6.1).
- Updates `test/health_status` helper script with for consistency.
- Updates Makefile target `logs` to accept `[OPTIONS]` (e.g `make -- logs -ft`).
- Updates `healthcheck` script; state file existence confirms bootstrap completion.
- Updates healthcheck failure messages to remove EOL character that is rendered in status response.
- Updates wrapper script; only emit "waiting on" info message if bootstrap hasn't completed.
- Updates ordering of Tags and respective Dockerfile links in README.md for readability.
- Adds improved test workflow; added `test-setup` target to Makefile.
- Adds Makefile target `logsdef` to handle deferred logs output within a target chain.
- Adds `/docs` directory for supplementary documentation and simplify README.
- Fixes docker-compose example configuration files to work on CentOS-7 hosts.
- Fixes validation failure of 0 second --timeout value in `test/health_status`.

### 2.3.0 - 2019-08-20

- Updates `haproxy18u` packages to 1.8.20-1.
- Updates source image to [2.6.0](https://github.com/jdeathe/centos-ssh/releases/tag/2.6.0).
- Updates CHANGELOG.md to simplify maintenance.
- Updates README.md to simplify contents and improve readability.
- Updates README-short.txt to apply to all image variants.
- Updates Dockerfile `org.deathe.description` metadata LABEL for consistency.
- Updates supervisord configuration to send error log output to stderr.
- Updates haproxy-bootstrap supervisord configuration file/priority to `20-haproxy-bootstrap.conf`/`20`.
- Updates resyslogd-wrapper supervisord configuration file/priority to `50-rsyslogd-wrapper.conf`/`50`.
- Updates haproxy-wrapper supervisord configuration file/priority to `90-haproxy-wrapper.conf`/`90`.
- Updates docker-compose example with redis session store replacing memcached for the apache-php service.
- Updates wrapper scripts timer to use UTC date timestamps.
- Updates default timeout values.
- Updates proxy (varnish) configuration examples to use uri balance algorithm.
- Updates proxy (varnish) configuration examples to use both backends (removes backup).
- Fixes docker host connection status check in Makefile.
- Fixes docker-compose examples; volume mount errors on CentOS host.
- Adds `inspect`, `reload` and `top` Makefile targets.
- Adds improved `clean` Makefile target; includes exited containers and dangling images.
- Adds `SYSTEM_TIMEZONE` handling to Makefile, scmi, systemd unit and docker-compose templates.
- Adds system time zone validation to healthcheck.
- Adds lock/state file to wrapper scripts.
- Adds maintenance feature controlled via acl file `/etc/haproxy/maint-blacklist.acl`.
- Adds maintenance whitelist via acl file `/etc/haproxy/maint-whitelist.acl`.
- Removes support for long image tags (i.e. centos-7-2.x.x).
- Removes `dontlog-normal` from all configuration defaults and add to listeners.

### 2.2.0 - 2019-05-30

- Updates `haproxy18u` packages to 1.8.19-1.
- Updates source image to [2.5.1](https://github.com/jdeathe/centos-ssh/releases/tag/2.5.1).
- Updates and restructures Dockerfile.
- Updates container naming conventions and readability of `Makefile`.
- Updates healthcheck retries to 4.
- Updates docker-compose configuration examples.
- Updates default tls/ssl certificate name from `localhost.localdomain.crt` to `localhost.crt`.
- Fixes issue with unexpected published port in run templates when `DOCKER_PORT_MAP_TCP_80` or `DOCKER_PORT_MAP_TCP_443` is set to an empty string or 0.
- Fixes binary paths in systemd unit files for compatibility with both EL and Ubuntu hosts.
- Fixes environment variable name typo in README for `HAPROXY_CONFIG`.
- Adds port incrementation to Makefile's run template for container names with an instance suffix.
- Adds placeholder replacement of `RELEASE_VERSION` docker argument to systemd service unit template.
- Adds improvement to pull logic in systemd unit install template.
- Adds `SSH_AUTOSTART_SUPERVISOR_STDOUT` with a value "false", disabling startup of `supervisor_stdout`.
- Adds improved logging output.
- Adds consideration for event lag into test cases for unhealthy health_status events.
- Adds error messages to healthcheck script and includes supervisord check.
- Adds improved `healtchcheck`, `haproxy-wrapper` and `rsyslogd-wrapper` scripts.
- Adds improved lock/state file implementation in wrapper scripts.
- Adds config path and tls/ssl certificate fingerprint to `haproxy-wrapper` Details output.
- Adds support for hitless reload via `haproxy-wrapper`.
- Adds configuration of Apache certificate via `APACHE_SSL_CERTIFICATE` in `.env` for the tcp example.
- Adds SNI forwarding in the TLS/SSL tcp example configuration.
- Adds `/status` (`monitor-uri`) endpoints and custom error responses to http example configuration.
- Adds `socat` package to the image to allow for non-interactive HAProxy CLI usage.
- Removes use of `/etc/services-config` paths.
- Removes the unused group element from the default container name.
- Removes the node element from the default container name.
- Removes unused environment variables from Makefile and scmi configuration.
- Removes X-Fleet section from etcd register template unit-file.
- Removes use of `stick-table` in `haproxy-tcp.cfg` as it should not be necessary for web backends that support shared persistence/session data stores.

### 2.1.1 - 2018-12-27

- Updates `haproxy18u` packages to 1.8.14-1.
- Updates `rsyslog` packages to 8.24.0-34.
- Updates source image to [2.4.1](https://github.com/jdeathe/centos-ssh/releases/tag/2.4.1).
- Updates image versions in tests and docker-compose examples.
- Adds required `--sysctl` settings to docker run templates.
- Fixes haproxy-wrapper return error and normalises scripts.
- Fixes example docker-compose Setup instructions.

### 2.1.0 - 2018-10-04

- Updates `haproxy18u` packages to 1.8.12-1.
- Updates `rsyslog` packages to 8.24.0-16.el7_5.4.
- Updates source image to [2.4.0](https://github.com/jdeathe/centos-ssh/releases/tag/2.4.0).

### 2.0.0 - 2018-07-16

- Initial release
- HAProxy [1.8.9](http://www.haproxy.org/download/1.8/src/CHANGELOG)
- HATop [0.7.7](http://feurix.org/projects/hatop/changes/#hatop-0-7-7)
