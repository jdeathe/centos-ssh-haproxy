# Change Log

## centos-6

Summary of release changes for Version 1.

CentOS-6 6.9 x86_64 - HAProxy 1.5 / HATop 0.7.

### 1.0.3 - 2018-07-16

- Updates README with details of Version 2.
- Adds fix to healthcheck to account for alternative path to rsyslogd.
- Adds SAN certificate for use in docker-compose example.
- Updates rsyslog package to rsyslog-5.8.10-12.el6.
- Adds default healthcheck settings; 5s interval for normal operation and 3 checks before triggering up/down state.
- Adds updated docker-compose examples including variants for TCP and PROXY (Varnish).
- Adds custom HTML error files for error codes HAProxy may emit.
- Updates configuration used for header manipulation.

### 1.0.2 - 2018-05-28

- Updates source image to [1.8.4 tag](https://github.com/jdeathe/centos-ssh/releases/tag/1.8.4).
- Adds feature to set `HAPROXY_SSL_CERTIFICATE` via a file path. e.g. Docker Swarm secrets.
- Adds feature to set `HAPROXY_CONF` via a file path. e.g. Docker Swarm secrets.

### 1.0.1 - 2018-01-22

- Updates source image to [1.8.3 tag](https://github.com/jdeathe/centos-ssh/releases/tag/1.8.3).
- Adds generic ready state test function.

### 1.0.0 - 2017-11-28

- Initial release
- HAProxy [1.5.18](http://www.haproxy.org/download/1.5/src/CHANGELOG)
- HATop [0.7.7](http://feurix.org/projects/hatop/changes/#hatop-0-7-7)
