# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
DOCKER_USER := jdeathe
DOCKER_IMAGE_NAME := centos-ssh-haproxy
SHPEC_ROOT := test/shpec

# Tag validation patterns
DOCKER_IMAGE_TAG_PATTERN := ^(latest|centos-[6-7]|((1|2|centos-(6-1|7-2))\.[0-9]+\.[0-9]+))$
DOCKER_IMAGE_RELEASE_TAG_PATTERN := ^(1|2|centos-(6-1|7-2))\.[0-9]+\.[0-9]+$

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

# Docker image/container settings
DOCKER_CONTAINER_OPTS ?=
DOCKER_IMAGE_TAG ?= latest
DOCKER_NAME ?= haproxy.pool-1.1.1
DOCKER_PORT_MAP_TCP_22 ?= NULL
DOCKER_PORT_MAP_TCP_80 ?= 80
DOCKER_PORT_MAP_TCP_443 ?= 443
DOCKER_RESTART_POLICY ?= always

# Docker build --no-cache parameter
NO_CACHE ?= false

# Directory path for release packages
DIST_PATH ?= ./dist

# Number of seconds expected to complete container startup including bootstrap.
STARTUP_TIME ?= 2

# Docker --sysctl settings
SYSCTL_NET_CORE_SOMAXCONN ?= 32768
SYSCTL_NET_IPV4_IP_LOCAL_PORT_RANGE ?= 1024 65535
SYSCTL_NET_IPV4_ROUTE_FLUSH ?= 1

# Docker --ulimit settings
ULIMIT_MEMLOCK ?= 82000
ULIMIT_NOFILE ?= 131072
ULIMIT_NPROC ?= 9223372036854775807

# ------------------------------------------------------------------------------
# Application container configuration
# ------------------------------------------------------------------------------
SSH_AUTHORIZED_KEYS ?=
SSH_AUTOSTART_SSHD ?= false
SSH_AUTOSTART_SSHD_BOOTSTRAP ?= false
SSH_CHROOT_DIRECTORY ?= %h
SSH_INHERIT_ENVIRONMENT ?= false
SSH_SUDO ?= ALL=(ALL) ALL
SSH_USER ?= app-admin
SSH_USER_FORCE_SFTP ?= false
SSH_USER_HOME ?= /home/%u
SSH_USER_ID ?= 500:500
SSH_USER_PASSWORD ?=
SSH_USER_PASSWORD_HASHED ?= false
SSH_USER_SHELL ?= /bin/bash
# ------------------------------------------------------------------------------
HAPROXY_SSL_CERTIFICATE ?=
HAPROXY_CONFIG ?= /etc/haproxy/haproxy.cfg
HAPROXY_HOST_NAMES ?= localhost.localdomain
