readonly STARTUP_TIME=2
readonly TEST_DIRECTORY="test"

# These should ideally be a static value but hosts might be using this port so 
# need to allow for alternatives.
DOCKER_PORT_MAP_TCP_22="${DOCKER_PORT_MAP_TCP_22:-NULL}"
DOCKER_PORT_MAP_TCP_80="${DOCKER_PORT_MAP_TCP_80:-80}"
DOCKER_PORT_MAP_TCP_443="${DOCKER_PORT_MAP_TCP_443:-443}"

function __destroy ()
{
	local -r backend_alias_1="httpd_1"
	local -r backend_alias_2="httpd_2"
	local -r backend_name_1="apache-php.pool-1.1.1"
	local -r backend_name_2="apache-php.pool-1.1.2"
	local -r backend_network="bridge_t1"

	# Destroy the backend
	__terminate_container \
		${backend_name_1} \
	&> /dev/null

	__terminate_container \
		${backend_name_2} \
	&> /dev/null

	# Destroy the bridge network
	if [[ -n $(docker network ls -q -f name="${backend_network}") ]]; then
		docker network rm \
			${backend_network} \
		&> /dev/null
	fi
}

function __get_container_port ()
{
	local container="${1:-}"
	local port="${2:-}"
	local value=""

	value="$(
		docker port \
			${container} \
			${port}
	)"
	value=${value##*:}

	printf -- \
		'%s' \
		"${value}"
}

# container - Docker container name.
# counter - Timeout counter in seconds.
# process_pattern - Regular expression pattern used to match running process.
# bootstrap_lock_file - Path to the bootstrap lock file.
function __is_container_ready ()
{
	local bootstrap_lock_file="${4:-}"
	local container="${1:-}"
	local counter=$(
		awk \
			-v seconds="${2:-10}" \
			'BEGIN { print 10 * seconds; }'
	)
	local process_pattern="${3:-}"

	until (( counter == 0 )); do
		sleep 0.1

		if docker exec ${container} \
				bash -c "ps axo command" \
			| grep -qE "${process_pattern}" \
			> /dev/null 2>&1 \
			&& docker exec ${container} \
				bash -c "[[ ! -e ${bootstrap_lock_file} ]]"
		then
			break
		fi

		(( counter -= 1 ))
	done

	if (( counter == 0 )); then
		return 1
	fi

	return 0
}

function __setup ()
{
	local -r backend_alias_1="httpd_1"
	local -r backend_alias_2="httpd_2"
	local -r backend_name_1="apache-php.pool-1.1.1"
	local -r backend_name_2="apache-php.pool-1.1.2"
	local -r backend_network="bridge_t1"
	local -r backend_release="2.2.1"

	# Create the bridge network
	if [[ -z $(docker network ls -q -f name="${backend_network}") ]]; then
		docker network create \
			--driver bridge \
			${backend_network} \
		&> /dev/null
	fi

	# Create the backend container
	__terminate_container \
		${backend_name_1} \
	&> /dev/null

	docker run \
		--detach \
		--name ${backend_name_1} \
		--network ${backend_network} \
		--network-alias ${backend_alias_1} \
		--volume ${PWD}/test/fixture/apache/var/www/public_html:/opt/app/public_html:ro \
		jdeathe/centos-ssh-apache-php:${backend_release} \
	&> /dev/null

	__terminate_container \
		${backend_name_2} \
	&> /dev/null

	docker run \
		--detach \
		--name ${backend_name_2} \
		--network ${backend_network} \
		--network-alias ${backend_alias_2} \
		--volume ${PWD}/test/fixture/apache/var/www/public_html:/opt/app/public_html:ro \
		jdeathe/centos-ssh-apache-php:${backend_release} \
	&> /dev/null
}

# Custom shpec matcher
# Match a string with an Extended Regular Expression pattern.
function __shpec_matcher_egrep ()
{
	local pattern="${2:-}"
	local string="${1:-}"

	printf -- \
		'%s' \
		"${string}" \
	| grep -qE -- \
		"${pattern}" \
		-

	assert equal \
		"${?}" \
		0
}

function __terminate_container ()
{
	local container="${1}"

	if docker ps -aq \
		--filter "name=${container}" \
		--filter "status=paused" &> /dev/null; then
		docker unpause ${container} &> /dev/null
	fi

	if docker ps -aq \
		--filter "name=${container}" \
		--filter "status=running" &> /dev/null; then
		docker stop ${container} &> /dev/null
	fi

	if docker ps -aq \
		--filter "name=${container}" &> /dev/null; then
		docker rm -vf ${container} &> /dev/null
	fi
}

function test_basic_operations ()
{
	local -r backend_hostname="localhost.localdomain"
	local -r backend_network="bridge_t1"

	local container_port_80=""
	local container_port_443=""

	trap "__terminate_container haproxy.pool-1.1.1 &> /dev/null; \
		__destroy; \
		exit 1" \
		INT TERM EXIT

	describe "Basic HAProxy operations"
		describe "Runs named container."
			__terminate_container \
				haproxy.pool-1.1.1 \
			&> /dev/null

			it "Can publish ${DOCKER_PORT_MAP_TCP_80}:80."
				docker run \
					--detach \
					--name haproxy.pool-1.1.1 \
					--network ${backend_network} \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--publish ${DOCKER_PORT_MAP_TCP_443}:443 \
					jdeathe/centos-ssh-haproxy:latest \
				&> /dev/null

				container_port_80="$(
					__get_container_port \
						haproxy.pool-1.1.1 \
						80/tcp
				)"

				if [[ ${DOCKER_PORT_MAP_TCP_80} == 0 ]] \
					|| [[ -z ${DOCKER_PORT_MAP_TCP_80} ]]; then
					assert gt \
						"${container_port_80}" \
						"30000"
				else
					assert equal \
						"${container_port_80}" \
						"${DOCKER_PORT_MAP_TCP_80}"
				fi
			end

			it "Can publish ${DOCKER_PORT_MAP_TCP_443}:443."
				container_port_443="$(
					__get_container_port \
						haproxy.pool-1.1.1 \
						443/tcp
				)"

				if [[ ${DOCKER_PORT_MAP_TCP_443} == 0 ]] \
					|| [[ -z ${DOCKER_PORT_MAP_TCP_443} ]]; then
					assert gt \
						"${container_port_443}" \
						"30000"
				else
					assert equal \
						"${container_port_443}" \
						"${DOCKER_PORT_MAP_TCP_443}"
				fi
			end
		end

		if ! __is_container_ready \
			haproxy.pool-1.1.1 \
			${STARTUP_TIME} \
			"/usr/sbin/haproxy " \
			"/var/lock/subsys/haproxy-bootstrap"
		then
			exit 1
		fi
	end

	describe "Response to HTTP requests"
		describe "Backend HTML content"
			it "Is unaltered."
				curl -s \
					-H "Host: ${backend_hostname}" \
					http://127.0.0.1:${container_port_80}/ \
				| grep -q '{{BODY}}'

				assert equal \
					"${?}" \
					0
			end
		end
	end

	__terminate_container \
		haproxy.pool-1.1.1 \
	&> /dev/null

	trap - \
		INT TERM EXIT
}

function test_custom_configuration ()
{
	:
}

function test_healthcheck ()
{
	local -r backend_network="bridge_t1"
	local -r interval_seconds=0.5
	local -r retries=4
	local health_status=""

	trap "__terminate_container haproxy.pool-1.1.1 &> /dev/null; \
		__destroy; \
		exit 1" \
		INT TERM EXIT

	describe "Healthcheck"
		describe "Default configuration"
			__terminate_container \
				haproxy.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name haproxy.pool-1.1.1 \
				--network ${backend_network} \
				jdeathe/centos-ssh-haproxy:latest \
			&> /dev/null

			it "Returns a valid status on starting."
				health_status="$(
					docker inspect \
						--format='{{json .State.Health.Status}}' \
						haproxy.pool-1.1.1
				)"

				assert __shpec_matcher_egrep \
					"${health_status}" \
					"\"(starting|healthy|unhealthy)\""
			end

			sleep $(
				awk \
					-v interval_seconds="${interval_seconds}" \
					-v startup_time="${STARTUP_TIME}" \
					'BEGIN { print 1 + interval_seconds + startup_time; }'
			)

			it "Returns healthy after startup."
				health_status="$(
					docker inspect \
						--format='{{json .State.Health.Status}}' \
						haproxy.pool-1.1.1
				)"

				assert equal \
					"${health_status}" \
					"\"healthy\""
			end

			it "Returns unhealthy on failure."
				docker exec -t \
					haproxy.pool-1.1.1 \
					bash -c "mv \
						/usr/sbin/haproxy \
						/usr/sbin/haproxy2" \
				&& docker exec -t \
					haproxy.pool-1.1.1 \
					bash -c "if [[ -n \$(pgrep -f '^/usr/sbin/haproxy ') ]]; then \
						kill -9 \$(pgrep -f '^/usr/sbin/haproxy ')
					fi"

				sleep $(
					awk \
						-v interval_seconds="${interval_seconds}" \
						-v retries="${retries}" \
						'BEGIN { print 1 + interval_seconds * retries; }'
				)

				health_status="$(
					docker inspect \
						--format='{{json .State.Health.Status}}' \
						haproxy.pool-1.1.1
				)"

				assert equal \
					"${health_status}" \
					"\"unhealthy\""
			end

			__terminate_container \
				haproxy.pool-1.1.1 \
			&> /dev/null
		end
	end

	trap - \
		INT TERM EXIT
}

if [[ ! -d ${TEST_DIRECTORY} ]]; then
	printf -- \
		"ERROR: Please run from the project root.\n" \
		>&2
	exit 1
fi

describe "jdeathe/centos-ssh-haproxy:latest"
	__destroy
	__setup
	test_basic_operations
	test_custom_configuration
	test_healthcheck
	__destroy
end
