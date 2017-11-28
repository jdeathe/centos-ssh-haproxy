centos-ssh-haproxy
==================

Docker Images of CentOS-6 6.9 x86_64 - HAProxy 1.5 / HATop 0.7.

- http://www.haproxy.org/
- http://feurix.org/projects/hatop/

## Overview & links

- `centos-6`, `centos-6-1.0.0`, `1.0.0` [(centos-6/Dockerfile)](https://github.com/jdeathe/centos-ssh-haproxy/blob/centos-6/Dockerfile)

#### centos-6

The latest CentOS-6 based release can be pulled from the `centos-6` Docker tag. It is recommended to select a specific release tag - the convention is `centos-6-1.0.0`or `1.0.0` for the [1.0.0](https://github.com/jdeathe/centos-ssh-haproxy/tree/1.0.0) release tag.

Included in the build are the [SCL](https://www.softwarecollections.org/), [EPEL](http://fedoraproject.org/wiki/EPEL) and [IUS](https://ius.io) repositories. Installed packages include [OpenSSH](http://www.openssh.com/portable.html) secure shell, [vim-minimal](http://www.vim.org/), are installed along with python-setuptools, [supervisor](http://supervisord.org/) and [supervisor-stdout](https://github.com/coderanger/supervisor-stdout).

Supervisor is used to start the haproxy (and optionally the sshd) daemon when a docker container based on this image is run. To enable simple viewing of stdout for the service's subprocess, supervisor-stdout is included. This allows you to see output from the supervisord controlled subprocesses with `docker logs {docker-container-name}`.

If enabling and configuring SSH access, it is by public key authentication and, by default, the [Vagrant](http://www.vagrantup.com/) [insecure private key](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant) is required.

### SSH Alternatives

SSH is not required in order to access a terminal for the running container. The simplest method is to use the docker exec command to run bash (or sh) as follows: 

```
$ docker exec -it {docker-name-or-id} bash
```

For cases where access to docker exec is not possible the preferred method is to use Command Keys and the nsenter command. See [command-keys.md](https://github.com/jdeathe/centos-ssh-haproxy/blob/centos-6/command-keys.md) for details on how to set this up.

## Quick Example

Run up a container named `haproxy.pool-1.1.1` from the docker image `jdeathe/centos-ssh-haproxy` on port 80 and 443 of your docker host. 2 backend hosts, `httpd_1` and `httpd_2`, are defined with IP addresses 172.17.8.101 and 172.17.8.101; this is required to identify the backend hosts from within the HAProxy configuration file if not using docker network aliases.

```
$ docker run -d -t \
  --name haproxy.pool-1.1.1 \
  -p 80:80 \
  -p 443:443 \
  --add-host httpd_1:172.17.8.101 \
  --add-host httpd_2:172.17.8.102 \
  jdeathe/centos-ssh-haproxy:centos-6
```

Now you can verify it is initialised and running successfully by inspecting the container's logs.

```
$ docker logs haproxy.pool-1.1.1
```

## Instructions

### Running

To run the a docker container from this image you can use the standard docker commands. Alternatively, there's a [docker-compose.yml](https://github.com/jdeathe/centos-ssh-haproxy/blob/centos-6/docker-compose.yml) example.

In the following example the http service is bound to port 80 and https on port 443 of the docker host. Also, the environment variable `HAPROXY_HOST_NAMES` has been used to set a list of 3 hostnames to be added to the auto-generated self-signed SAN certificate.

#### Using environment variables

```
$ docker stop haproxy.pool-1.1.1 && \
  docker rm haproxy.pool-1.1.1
$ docker run \
  --detach \
  --tty \
  --name haproxy.pool-1.1.1 \
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
  jdeathe/centos-ssh-haproxy:centos-6
```

Now you can verify it is initialised and running successfully by inspecting the container's logs:

```
$ docker logs haproxy.pool-1.1.1
```

#### Environment Variables

There are several environmental variables defined at runtime which allows the operator to customise the running container.

##### HAPROXY_SSL_CERTIFICATE

The HAProxy SSL/TLS certificate can be defined using `HAPROXY_SSL_CERTIFICATE`. The value may be either a file path, a base64 encoded string of the certificate file contents or a multiline string containing a PEM formatted concatenation of private key and certificate. If set to a file path the contents may also be a base64 encoded string.

##### HAPROXY_CONF

The HAProxy configuration file path, (or base64 encoded string of the configuration file contents), is set using `HAPROXY_CONF`. The default http configuration is located at the path `/etc/haproxy/haproxy-http.example.cfg` and will be copied into the runnning configuration path `/etc/haproxy/haproxy-http.example.cfg`. There's also an example tcp configuration in the path `/etc/haproxy/haproxy-tcp.example.cfg`. 

In most situations it will be necessary to define a custom configuration where the use of the base64 encoded string option is recommended.

##### HAPROXY_HOST_NAMES

The `HAPROXY_HOST_NAMES` can be used to set a, space separated, list of hostnames to be added to the automatically generated self-signed SAN certificate.

**Note:** The value is unused if `HAPROXY_SSL_CERTIFICATE` has a valid value set.
