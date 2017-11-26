
# Common parameters of create and run targets
define DOCKER_CONTAINER_PARAMETERS
--tty \
--sysctl "net.core.somaxconn=32768" \
--sysctl "net.ipv4.ip_local_port_range=1024 65535" \
--sysctl "net.ipv4.route.flush=1" \
--ulimit memlock=$(ULIMIT_MEMLOCK) \
--ulimit nofile=$(ULIMIT_NOFILE) \
--ulimit nproc=$(ULIMIT_NPROC) \
--name $(DOCKER_NAME) \
--restart $(DOCKER_RESTART_POLICY) \
--env "HAPROXY_SSL_CERTIFICATE=$(HAPROXY_SSL_CERTIFICATE)" \
--env "HAPROXY_CONFIG=$(HAPROXY_CONFIG)" \
--env "HAPROXY_HOST_NAMES=$(HAPROXY_HOST_NAMES)" \
--env "SSH_AUTOSTART_SSHD=$(SSH_AUTOSTART_SSHD)" \
--env "SSH_AUTOSTART_SSHD_BOOTSTRAP=$(SSH_AUTOSTART_SSHD_BOOTSTRAP)"
endef

DOCKER_PUBLISH := $(shell \
	if [[ $(DOCKER_PORT_MAP_TCP_80) != NULL ]]; then printf -- '--publish %s:80\n' $(DOCKER_PORT_MAP_TCP_80); fi; \
	if [[ $(DOCKER_PORT_MAP_TCP_443) != NULL ]]; then printf -- '--publish %s:443\n' $(DOCKER_PORT_MAP_TCP_443); fi; \
)
