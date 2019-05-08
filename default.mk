
# Handle incrementing the docker host port for instances unless a port range is defined.
DOCKER_PUBLISH := $(shell \
	if [[ "$(DOCKER_PORT_MAP_TCP_80)" != NULL ]]; \
	then \
		if grep -qE \
				'^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:)?[1-9][0-9]*$$' \
				<<< "$(DOCKER_PORT_MAP_TCP_80)" \
			&& grep -qE \
				'^.+\.[0-9]+(\.[0-9]+)?$$' \
				<<< "$(DOCKER_NAME)"; \
		then \
			printf -- ' --publish %s%s:80/tcp' \
				"$$(\
					grep -o '^[0-9\.]*:' \
						<<< "$(DOCKER_PORT_MAP_TCP_80)" \
				)" \
				"$$(( \
					$$(\
						grep -oE \
							'[0-9]+$$' \
							<<< "$(DOCKER_PORT_MAP_TCP_80)" \
					) \
					+ $$(\
						grep -oE \
							'([0-9]+)(\.[0-9]+)?$$' \
							<<< "$(DOCKER_NAME)" \
						| awk -F. \
							'{ print $$1; }' \
					) \
					- 1 \
				))"; \
		else \
			printf -- ' --publish %s:80/tcp' \
				"$(DOCKER_PORT_MAP_TCP_80)"; \
		fi; \
	fi; \
	if [[ "$(DOCKER_PORT_MAP_TCP_443)" != NULL ]]; \
	then \
		if grep -qE \
				'^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:)?[1-9][0-9]*$$' \
				<<< "$(DOCKER_PORT_MAP_TCP_443)" \
			&& grep -qE \
				'^.+\.[0-9]+(\.[0-9]+)?$$' \
				<<< "$(DOCKER_NAME)"; \
		then \
			printf -- ' --publish %s%s:443/tcp' \
				"$$(\
					grep -o '^[0-9\.]*:' \
						<<< "$(DOCKER_PORT_MAP_TCP_443)" \
				)" \
				"$$(( \
					$$(\
						grep -oE \
							'[0-9]+$$' \
							<<< "$(DOCKER_PORT_MAP_TCP_443)" \
					) \
					+ $$(\
						grep -oE \
							'([0-9]+)(\.[0-9]+)?$$' \
							<<< "$(DOCKER_NAME)" \
						| awk -F. \
							'{ print $$1; }' \
					) \
					- 1 \
				))"; \
		else \
			printf -- ' --publish %s:443/tcp' \
				"$(DOCKER_PORT_MAP_TCP_443)"; \
		fi; \
	fi; \
)

# Common parameters of create and run targets
define DOCKER_CONTAINER_PARAMETERS
--tty \
--sysctl "net.core.somaxconn=$(SYSCTL_NET_CORE_SOMAXCONN)" \
--sysctl "net.ipv4.ip_local_port_range=$(SYSCTL_NET_IPV4_IP_LOCAL_PORT_RANGE)" \
--sysctl "net.ipv4.route.flush=$(SYSCTL_NET_IPV4_ROUTE_FLUSH)" \
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
