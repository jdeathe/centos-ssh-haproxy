
# Tag validation patterns
DOCKER_IMAGE_TAG_PATTERN := ^(latest|(centos-[6-7])|(centos-(6-1|7-2).[0-9]+.[0-9]+))$
DOCKER_IMAGE_RELEASE_TAG_PATTERN := ^centos-(6-1|7-2).[0-9]+.[0-9]+$

# Docker image/container settings
DOCKER_USER := jdeathe
DOCKER_IMAGE_NAME := centos-ssh-haproxy
DOCKER_IMAGE_TAG ?= latest
DOCKER_NAME ?= haproxy.pool-1.1.1
DOCKER_PORT_MAP_TCP_22 ?= 
DOCKER_PORT_MAP_TCP_80 ?= 80
DOCKER_PORT_MAP_TCP_442 ?= 442
DOCKER_PORT_MAP_TCP_443 ?= 443
DOCKER_RESTART_POLICY ?= always # {no,on-failure[:max-retries],always,unless-stopped}

# Docker build --no-cache parameter
NO_CACHE ?= false

# Directory path for release packages
PACKAGE_PATH ?= ./packages/jdeathe

# VOLUME_CONFIG_NAME := volume-config.${SERVICE_UNIT_NAME}
# VOLUME_CONFIG_NAME := volume-config.${SERVICE_UNIT_NAME}.${SERVICE_UNIT_SHARED_GROUP}
VOLUME_CONFIG_NAME := volume-config.haproxy.pool-1.1.1

# Use of a configuration volume requires additional maintenance and access to the
# filesystem of the docker host so is disabled by default.
VOLUME_CONFIG_ENABLED := false

# Using named volumes allows for easier identification of files located in
# /var/lib/docker/volumes/ on the docker host. If set to true, the value of
# VOLUME_CONFIG_NAME is used in place of an automatically generated ID.
# NOTE: When using named volumes you need to copy the contents of the directory
# into the configuration "data" volume container.
VOLUME_CONFIG_NAMED := false

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
SSH_USER_PASSWORD ?=
SSH_USER_PASSWORD_HASHED ?= false
SSH_USER_SHELL ?= /bin/bash
SSH_USER_ID ?= 500:500
# ------------------------------------------------------------------------------
HAPROXY_CONFIG ?= /etc/haproxy/haproxy.cfg
HAPROXY_SERVER_ADDRESS_1 ?= 192.168.99.100
HAPROXY_SERVER_ADDRESS_2 ?= 192.168.99.101
HAPROXY_SERVER_ADDRESS_3 ?= 192.168.99.102
