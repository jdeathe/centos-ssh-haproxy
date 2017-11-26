# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
readonly DOCKER_USER=jdeathe
readonly DOCKER_IMAGE_NAME=centos-ssh-haproxy

# Tag validation patterns
readonly DOCKER_IMAGE_TAG_PATTERN='^(latest|centos-6|((1|centos-6-1)\.[0-9]+\.[0-9]+))$'
readonly DOCKER_IMAGE_RELEASE_TAG_PATTERN='^(1|centos-6-1)\.[0-9]+\.[0-9]+$'

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

# Docker image/container settings
DOCKER_CONTAINER_OPTS="${DOCKER_CONTAINER_OPTS:-}"
DOCKER_IMAGE_TAG="${DOCKER_IMAGE_TAG:-latest}"
DOCKER_NAME="${DOCKER_NAME:-varnish.pool-1.1.1}"
DOCKER_PORT_MAP_TCP_22="${DOCKER_PORT_MAP_TCP_22:-NULL}"
DOCKER_PORT_MAP_TCP_80="${DOCKER_PORT_MAP_TCP_80:-80}"
DOCKER_PORT_MAP_TCP_443="${DOCKER_PORT_MAP_TCP_443:-443}"
DOCKER_RESTART_POLICY="${DOCKER_RESTART_POLICY:-always}"

# Docker build --no-cache parameter
NO_CACHE="${NO_CACHE:-false}"

# Directory path for release packages
DIST_PATH="${DIST_PATH:-./dist}"

# Number of seconds expected to complete container startup including bootstrap.
STARTUP_TIME="${STARTUP_TIME:-2}"

# Docker --ulimit settings
ULIMIT_MEMLOCK="${ULIMIT_MEMLOCK:-82000}"
ULIMIT_NOFILE="${ULIMIT_NOFILE:-131072}"
ULIMIT_NPROC="${ULIMIT_NPROC:-9223372036854775807}"

# ETCD register service settings
REGISTER_ETCD_PARAMETERS="${REGISTER_ETCD_PARAMETERS:-}"
REGISTER_TTL="${REGISTER_TTL:-60}"
REGISTER_UPDATE_INTERVAL="${REGISTER_UPDATE_INTERVAL:-55}"

# -----------------------------------------------------------------------------
# Application container configuration
# -----------------------------------------------------------------------------
SSH_AUTHORIZED_KEYS="${SSH_AUTHORIZED_KEYS:-}"
SSH_AUTOSTART_SSHD="${SSH_AUTOSTART_SSHD:-true}"
SSH_AUTOSTART_SSHD_BOOTSTRAP="${SSH_AUTOSTART_SSHD_BOOTSTRAP:-true}"
SSH_CHROOT_DIRECTORY="${SSH_CHROOT_DIRECTORY:-%h}"
SSH_INHERIT_ENVIRONMENT="${SSH_INHERIT_ENVIRONMENT:-false}"
SSH_SUDO="${SSH_SUDO:-ALL=(ALL) ALL}"
SSH_USER="${SSH_USER:-app-admin}"
SSH_USER_FORCE_SFTP="${SSH_USER_FORCE_SFTP:-false}"
SSH_USER_HOME="${SSH_USER_HOME:-/home/%u}"
SSH_USER_ID="${SSH_USER_ID:-500:500}"
SSH_USER_PASSWORD="${SSH_USER_PASSWORD:-}"
SSH_USER_PASSWORD_HASHED="${SSH_USER_PASSWORD_HASHED:-false}"
SSH_USER_SHELL="${SSH_USER_SHELL:-/bin/bash}"
# -----------------------------------------------------------------------------
HAPROXY_CERTIFICATE="${HAPROXY_CERTIFICATE:-}"
HAPROXY_CONFIG="${HAPROXY_CONFIG:-/etc/haproxy/haproxy.cfg}"
HAPROXY_HOST_NAMES="${HAPROXY_HOST_NAMES:-localhost.localdomain}"
