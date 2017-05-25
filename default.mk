
# Common parameters of create and run targets
define DOCKER_CONTAINER_PARAMETERS
--tty \
--privileged \
--name $(DOCKER_NAME) \
--restart $(DOCKER_RESTART_POLICY) \
--env "HAPROXY_CONFIG=$(HAPROXY_CONFIG)" \
--env "SSH_AUTOSTART_SSHD=$(SSH_AUTOSTART_SSHD)" \
--env "SSH_AUTOSTART_SSHD_BOOTSTRAP=$(SSH_AUTOSTART_SSHD_BOOTSTRAP)"
endef

DOCKER_PUBLISH := $(shell \
	if [[ $(DOCKER_PORT_MAP_TCP_80) != NULL ]]; then printf -- '--publish %s:80\n' $(DOCKER_PORT_MAP_TCP_80); fi; \
	if [[ $(DOCKER_PORT_MAP_TCP_443) != NULL ]]; then printf -- '--publish %s:443\n' $(DOCKER_PORT_MAP_TCP_443); fi; \
)
