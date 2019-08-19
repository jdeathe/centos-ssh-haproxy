# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
DOCKER_IMAGE_NAME := centos-ssh-haproxy
DOCKER_IMAGE_RELEASE_TAG_PATTERN := ^[1-2]\.[0-9]+\.[0-9]+$
DOCKER_IMAGE_TAG_PATTERN := ^(latest|[1-2]\.[0-9]+\.[0-9]+)$
DOCKER_USER := jdeathe
SHPEC_ROOT := test/shpec

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
DIST_PATH ?= ./dist
DOCKER_CONTAINER_OPTS ?=
DOCKER_IMAGE_TAG ?= latest
DOCKER_NAME ?= haproxy.1
DOCKER_PORT_MAP_TCP_80 ?= 80
DOCKER_PORT_MAP_TCP_443 ?= 443
DOCKER_RESTART_POLICY ?= always
NO_CACHE ?= false
RELOAD_SIGNAL ?= HUP
STARTUP_TIME ?= 2
SYSCTL_NET_CORE_SOMAXCONN ?= 32768
SYSCTL_NET_IPV4_IP_LOCAL_PORT_RANGE ?= 1024 65535
SYSCTL_NET_IPV4_ROUTE_FLUSH ?= 1
ULIMIT_MEMLOCK ?= 82000
ULIMIT_NOFILE ?= 131072
ULIMIT_NPROC ?= 9223372036854775807

# ------------------------------------------------------------------------------
# Application container configuration
# ------------------------------------------------------------------------------
HAPROXY_CONFIG ?= /etc/haproxy/haproxy.cfg
HAPROXY_HOST_NAMES ?= localhost.localdomain
HAPROXY_SSL_CERTIFICATE ?=
SYSTEM_TIMEZONE ?= UTC
