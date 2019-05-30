# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
readonly DOCKER_USER=jdeathe
readonly DOCKER_IMAGE_NAME=centos-ssh-haproxy

# Tag validation patterns
readonly DOCKER_IMAGE_TAG_PATTERN='^(latest|centos-[6-7]|((1|2|centos-(6-1|7-2))\.[0-9]+\.[0-9]+))$'
readonly DOCKER_IMAGE_RELEASE_TAG_PATTERN='^(1|2|centos-(6-1|7-2))\.[0-9]+\.[0-9]+$'

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------

# Docker image/container settings
DOCKER_CONTAINER_OPTS="${DOCKER_CONTAINER_OPTS:-}"
DOCKER_IMAGE_TAG="${DOCKER_IMAGE_TAG:-latest}"
DOCKER_NAME="${DOCKER_NAME:-haproxy.1}"
DOCKER_PORT_MAP_TCP_80="${DOCKER_PORT_MAP_TCP_80:-80}"
DOCKER_PORT_MAP_TCP_443="${DOCKER_PORT_MAP_TCP_443:-443}"
DOCKER_RESTART_POLICY="${DOCKER_RESTART_POLICY:-always}"

# Docker build --no-cache parameter
NO_CACHE="${NO_CACHE:-false}"

# Directory path for release packages
DIST_PATH="${DIST_PATH:-./dist}"

# Number of seconds expected to complete container startup including bootstrap.
STARTUP_TIME="${STARTUP_TIME:-2}"

# Docker --sysctl settings
SYSCTL_NET_CORE_SOMAXCONN="${SYSCTL_NET_CORE_SOMAXCONN:-32768}"
SYSCTL_NET_IPV4_IP_LOCAL_PORT_RANGE="${SYSCTL_NET_IPV4_IP_LOCAL_PORT_RANGE:-1024 65535}"
SYSCTL_NET_IPV4_ROUTE_FLUSH="${SYSCTL_NET_IPV4_ROUTE_FLUSH:-1}"

# Docker --ulimit settings
ULIMIT_MEMLOCK="${ULIMIT_MEMLOCK:-82000}"
ULIMIT_NOFILE="${ULIMIT_NOFILE:-131072}"
ULIMIT_NPROC="${ULIMIT_NPROC:-9223372036854775807}"

# ETCD register service settings
REGISTER_ETCD_PARAMETERS="${REGISTER_ETCD_PARAMETERS:-}"
REGISTER_TTL="${REGISTER_TTL:-60}"
REGISTER_UPDATE_INTERVAL="${REGISTER_UPDATE_INTERVAL:-55}"

# ------------------------------------------------------------------------------
# Application container configuration
# ------------------------------------------------------------------------------
HAPROXY_SSL_CERTIFICATE="${HAPROXY_SSL_CERTIFICATE:-}"
HAPROXY_CONFIG="${HAPROXY_CONFIG:-/etc/haproxy/haproxy.cfg}"
HAPROXY_HOST_NAMES="${HAPROXY_HOST_NAMES:-localhost.localdomain}"
