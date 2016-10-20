# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
DOCKER_USER := jdeathe
DOCKER_IMAGE_NAME := centos-ssh-haproxy

# Tag validation patterns
DOCKER_IMAGE_TAG_PATTERN := ^(latest|(centos-[6-7])|(centos-(6-1|7-2).[0-9]+.[0-9]+))$
DOCKER_IMAGE_RELEASE_TAG_PATTERN := ^centos-(6-1|7-2).[0-9]+.[0-9]+$

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

# Docker image/container settings
DOCKER_CONTAINER_OPTS ?=
DOCKER_IMAGE_TAG ?= latest
DOCKER_NAME ?= haproxy.pool-1.1.1
DOCKER_PORT_MAP_TCP_22 ?= 
DOCKER_PORT_MAP_TCP_80 ?= 80
DOCKER_PORT_MAP_TCP_442 ?= NULL
DOCKER_PORT_MAP_TCP_443 ?= 443
DOCKER_RESTART_POLICY ?= always

# Docker build --no-cache parameter
NO_CACHE ?= false

# Directory path for release packages
DIST_PATH ?= ./dist

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
HAPROXY_CONFIG ?= /etc/haproxy/haproxy.cfg
HAPROXY_SERVER_ADDRESS_1 ?= 192.168.99.100
HAPROXY_SERVER_ADDRESS_2 ?= 192.168.99.101
HAPROXY_SERVER_ADDRESS_3 ?= 192.168.99.102
