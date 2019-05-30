
# Handle incrementing the docker host port for instances unless a port range is defined.
DOCKER_PUBLISH=
if [[ ${DOCKER_PORT_MAP_TCP_80} != NULL ]]
then
	if grep -qE \
			'^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:)?[1-9][0-9]*$' \
			<<< "${DOCKER_PORT_MAP_TCP_80}" \
		&& grep -qE \
			'^.+\.[0-9]+(\.[0-9]+)?$' \
			<<< "${DOCKER_NAME}"
	then
		printf -v \
			DOCKER_PUBLISH \
			-- '%s --publish %s%s:80' \
			"${DOCKER_PUBLISH}" \
			"$(
				grep -o \
					'^[0-9\.]*:' \
					<<< "${DOCKER_PORT_MAP_TCP_80}"
			)" \
			"$(( 
				$(
					grep -oE \
						'[0-9]+$' \
						<<< "${DOCKER_PORT_MAP_TCP_80}"
				) \
				+ $(
					grep -oE \
						'([0-9]+)(\.[0-9]+)?$' \
						<<< "${DOCKER_NAME}" \
					| awk -F. \
						'{ print $1; }'
				) \
				- 1
			))"
	else
		printf -v \
			DOCKER_PUBLISH \
			-- '%s --publish %s:80' \
			"${DOCKER_PUBLISH}" \
			"${DOCKER_PORT_MAP_TCP_80}"
	fi
fi

if [[ ${DOCKER_PORT_MAP_TCP_443} != NULL ]]
then
	if grep -qE \
			'^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:)?[1-9][0-9]*$' \
			<<< "${DOCKER_PORT_MAP_TCP_443}" \
		&& grep -qE \
			'^.+\.[0-9]+(\.[0-9]+)?$' \
			<<< "${DOCKER_NAME}"
	then
		printf -v \
			DOCKER_PUBLISH \
			-- '%s --publish %s%s:443' \
			"${DOCKER_PUBLISH}" \
			"$(
				grep -o \
					'^[0-9\.]*:' \
					<<< "${DOCKER_PORT_MAP_TCP_443}"
			)" \
			"$(( 
				$(
					grep -oE \
						'[0-9]+$' \
						<<< "${DOCKER_PORT_MAP_TCP_443}"
				) \
				+ $(
					grep -oE \
						'([0-9]+)(\.[0-9]+)?$' \
						<<< "${DOCKER_NAME}" \
					| awk -F. \
						'{ print $1; }'
				) \
				- 1
			))"
	else
		printf -v \
			DOCKER_PUBLISH \
			-- '%s --publish %s:443' \
			"${DOCKER_PUBLISH}" \
			"${DOCKER_PORT_MAP_TCP_443}"
	fi
fi

# Common parameters of create and run targets
DOCKER_CONTAINER_PARAMETERS="--tty \
--name ${DOCKER_NAME} \
--restart ${DOCKER_RESTART_POLICY} \
--sysctl \"net.core.somaxconn=${SYSCTL_NET_CORE_SOMAXCONN}\" \
--sysctl \"net.ipv4.ip_local_port_range=${SYSCTL_NET_IPV4_IP_LOCAL_PORT_RANGE}\" \
--sysctl \"net.ipv4.route.flush=${SYSCTL_NET_IPV4_ROUTE_FLUSH}\" \
--ulimit \"memlock=${ULIMIT_MEMLOCK}\" \
--ulimit \"nofile=${ULIMIT_NOFILE}\" \
--ulimit \"nproc=${ULIMIT_NPROC}\" \
--env \"HAPROXY_SSL_CERTIFICATE=${HAPROXY_SSL_CERTIFICATE}\" \
--env \"HAPROXY_CONFIG=${HAPROXY_CONFIG}\" \
--env \"HAPROXY_HOST_NAMES=${HAPROXY_HOST_NAMES}\" \
${DOCKER_PUBLISH}"
