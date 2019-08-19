# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
readonly DOCKER_IMAGE_NAME=centos-ssh-haproxy
readonly DOCKER_IMAGE_RELEASE_TAG_PATTERN='^[1-2]\.[0-9]+\.[0-9]+$'
readonly DOCKER_IMAGE_TAG_PATTERN='^(latest|[1-2]\.[0-9]+\.[0-9]+)$'
readonly DOCKER_USER=jdeathe

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
DIST_PATH="${DIST_PATH:-./dist}"
DOCKER_CONTAINER_OPTS="${DOCKER_CONTAINER_OPTS:-}"
DOCKER_IMAGE_TAG="${DOCKER_IMAGE_TAG:-latest}"
DOCKER_NAME="${DOCKER_NAME:-haproxy.1}"
DOCKER_PORT_MAP_TCP_80="${DOCKER_PORT_MAP_TCP_80:-80}"
DOCKER_PORT_MAP_TCP_443="${DOCKER_PORT_MAP_TCP_443:-443}"
DOCKER_RESTART_POLICY="${DOCKER_RESTART_POLICY:-always}"
NO_CACHE="${NO_CACHE:-false}"
REGISTER_ETCD_PARAMETERS="${REGISTER_ETCD_PARAMETERS:-}"
REGISTER_TTL="${REGISTER_TTL:-60}"
REGISTER_UPDATE_INTERVAL="${REGISTER_UPDATE_INTERVAL:-55}"
STARTUP_TIME="${STARTUP_TIME:-2}"
SYSCTL_NET_CORE_SOMAXCONN="${SYSCTL_NET_CORE_SOMAXCONN:-32768}"
SYSCTL_NET_IPV4_IP_LOCAL_PORT_RANGE="${SYSCTL_NET_IPV4_IP_LOCAL_PORT_RANGE:-"1024 65535"}"
SYSCTL_NET_IPV4_ROUTE_FLUSH="${SYSCTL_NET_IPV4_ROUTE_FLUSH:-1}"
ULIMIT_MEMLOCK="${ULIMIT_MEMLOCK:-82000}"
ULIMIT_NOFILE="${ULIMIT_NOFILE:-131072}"
ULIMIT_NPROC="${ULIMIT_NPROC:-9223372036854775807}"

# ------------------------------------------------------------------------------
# Application container configuration
# ------------------------------------------------------------------------------
HAPROXY_CONFIG="${HAPROXY_CONFIG:-/etc/haproxy/haproxy.cfg}"
HAPROXY_HOST_NAMES="${HAPROXY_HOST_NAMES:-localhost.localdomain}"
HAPROXY_SSL_CERTIFICATE="${HAPROXY_SSL_CERTIFICATE:-}"
SYSTEM_TIMEZONE="${SYSTEM_TIMEZONE:-UTC}"
