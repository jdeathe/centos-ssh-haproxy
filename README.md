### Tags and respective `Dockerfile` links

- `centos-7`, `2.2.0` [(centos-7/Dockerfile)](https://github.com/jdeathe/centos-ssh-haproxy/blob/centos-7/Dockerfile)
- `centos-6`, `1.2.0` [(centos-6/Dockerfile)](https://github.com/jdeathe/centos-ssh-haproxy/blob/centos-6/Dockerfile)

## Overview

This build uses the base image [jdeathe/centos-ssh](https://github.com/jdeathe/centos-ssh) so inherits it's features but with `sshd` disabled by default. [Supervisor](http://supervisord.org/) is used to start the [haproxy](http://www.haproxy.org/) daemon when a docker container based on this image is run.

To manage HAProxy both [HATop](http://feurix.org/projects/hatop/) and [socat](http://www.dest-unreach.org/socat/) are included to provide both a UI and low level cli management interface respectively.

### Image variants

- [HAProxy 1.8 / HATop 0.7 - CentOS-7](https://github.com/jdeathe/centos-ssh-haproxy/blob/centos-7)
- [HAProxy 1.5 / HATop 0.7 - CentOS-6](https://github.com/jdeathe/centos-ssh-haproxy/blob/centos-6)

## Quick start

> For production use, it is recommended to select a specific release tag as shown in the examples.

Run up a container named `haproxy.1` from the docker image `jdeathe/centos-ssh-haproxy` on port 80 and 443 of your docker host. 2 backend hosts, `httpd_1` and `httpd_2`, are defined with IP addresses `172.17.8.101` and `172.17.8.101`; this is required to identify the backend hosts from within the HAProxy configuration file if not using docker network aliases.

```
$ docker run -d -t \
  --name haproxy.1 \
  -p 80:80 \
  -p 443:443 \
  --add-host httpd_1:172.17.8.101 \
  --add-host httpd_2:172.17.8.102 \
  jdeathe/centos-ssh-haproxy:2.2.0
```

Verify the named container's process status and health.

```
$ docker ps -a \
  -f "name=haproxy.1"
```

Verify successful initialisation of the named container.

```
$ docker logs haproxy.1
```

## Instructions

### Running

To run the a docker container from this image you can use the standard docker commands. Alternatively, there's a [docker-compose.yml](https://github.com/jdeathe/centos-ssh-haproxy/blob/centos-7/docker-compose.yml) example.

In the following example the http service is bound to port 80 and https on port 443 of the docker host. Also, the environment variable `HAPROXY_HOST_NAMES` has been used to set a list of 3 hostnames to be added to the auto-generated self-signed SAN certificate.

#### Using environment variables

```
$ docker stop haproxy.1 && \
  docker rm haproxy.1; \
  docker run \
  --detach \
  --tty \
  --name haproxy.1 \
  --publish 80:80 \
  --publish 443:443 \
  --sysctl "net.core.somaxconn=32768" \
  --sysctl "net.ipv4.ip_local_port_range=1024 65535" \
  --sysctl "net.ipv4.route.flush=1" \
  --ulimit memlock=82000 \
  --ulimit nofile=131072 \
  --ulimit nproc=65535 \
  --env "HAPROXY_HOST_NAMES=www.app.local app.local localhost.localdomain" \
  --add-host httpd_1:172.17.8.101 \
  --add-host httpd_2:172.17.8.102 \
  jdeathe/centos-ssh-haproxy:2.2.0
```

Now you can verify it is initialised and running successfully by inspecting the container's logs:

```
$ docker logs haproxy.1
```

#### Environment variables

There are several environmental variables defined at runtime which allows the operator to customise the running container.

##### HAPROXY_SSL_CERTIFICATE

The HAProxy SSL/TLS certificate can be defined using `HAPROXY_SSL_CERTIFICATE`. The value may be either a file path, a base64 encoded string of the certificate file contents or a multiline string containing a PEM formatted concatenation of private key and certificate. If set to a file path the contents may also be a base64 encoded string.

**Note:** If using a file path with base64 encoded content the on container path is not maintained so this feature is *not* suitable for use with orchestration secrets such as Docker Swarm secrets or config however use of unencoded file contents is.

##### HAPROXY_CONFIG

The HAProxy configuration file path, (or base64 encoded string of the configuration file contents), is set using `HAPROXY_CONFIG`. The default http configuration is located at the path `/etc/haproxy/haproxy-http.example.cfg` and will be copied into the runnning configuration path `/etc/haproxy/haproxy-http.example.cfg`. There's also an example tcp configuration in the path `/etc/haproxy/haproxy-tcp.example.cfg`. 

**Note:** In most situations it will be necessary to define a custom configuration where the use of the base64 encoded string option is recommended. However if using a file path with base64 encoded content the on container path is not maintained so this feature is *not* suitable for use with orchestration secrets such as Docker Swarm secrets or config so when using these unencoded file contents is recommended.

##### HAPROXY_HOST_NAMES

The `HAPROXY_HOST_NAMES` can be used to set a, space separated, list of hostnames to be added to the automatically generated self-signed SAN certificate.

**Note:** The value is unused if `HAPROXY_SSL_CERTIFICATE` has a valid value set.
