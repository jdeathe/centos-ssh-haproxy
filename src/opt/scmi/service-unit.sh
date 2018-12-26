# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
readonly SERVICE_UNIT_ENVIRONMENT_KEYS="
 DOCKER_CONTAINER_OPTS
 DOCKER_IMAGE_PACKAGE_PATH
 DOCKER_IMAGE_TAG
 DOCKER_PORT_MAP_TCP_80
 DOCKER_PORT_MAP_TCP_443
 SYSCTL_NET_CORE_SOMAXCONN
 SYSCTL_NET_IPV4_IP_LOCAL_PORT_RANGE
 SYSCTL_NET_IPV4_ROUTE_FLUSH
 ULIMIT_MEMLOCK
 ULIMIT_NOFILE
 ULIMIT_NPROC
 HAPROXY_SSL_CERTIFICATE
 HAPROXY_CONFIG
 HAPROXY_HOST_NAMES
"

readonly SERVICE_UNIT_REGISTER_ENVIRONMENT_KEYS="
 REGISTER_ETCD_PARAMETERS
 REGISTER_TTL
 REGISTER_UPDATE_INTERVAL
"

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
SERVICE_UNIT_INSTALL_TIMEOUT=${SERVICE_UNIT_INSTALL_TIMEOUT:-5}
