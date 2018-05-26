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
# ready_test - Command used to test if the service is ready.
function __is_container_ready ()
{
	local container="${1:-}"
	local counter=$(
		awk \
			-v seconds="${2:-10}" \
			'BEGIN { print 10 * seconds; }'
	)
	local process_pattern="${3:-}"
	local ready_test="${4:-true}"

	until (( counter == 0 )); do
		sleep 0.1

		if docker exec ${container} \
			bash -c "ps axo command \
				| grep -qE \"${process_pattern}\" \
				&& eval \"${ready_test}\"" \
			&> /dev/null
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
	local -r backend_release="2.2.5"

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
		--env "APACHE_SERVER_NAME=www.app.local" \
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
		--env "APACHE_SERVER_NAME=www.app.local" \
		--network ${backend_network} \
		--network-alias ${backend_alias_2} \
		--volume ${PWD}/test/fixture/apache/var/www/public_html:/opt/app/public_html:ro \
		jdeathe/centos-ssh-apache-php:${backend_release} \
	&> /dev/null

	# Generate a self-signed certificate
	openssl req \
		-x509 \
		-sha256 \
		-nodes \
		-newkey rsa:2048 \
		-days 365 \
		-subj "/CN=www.app.local" \
		-keyout /tmp/www.app.local.pem \
		-out /tmp/www.app.local.pem \
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
	local -r content="$(< test/fixture/apache/var/www/public_html/index.html)"

	local backend_content=""
	local container_port_80=""
	local container_port_443=""

	describe "Basic HAProxy operations"
		trap "__terminate_container haproxy.pool-1.1.1 &> /dev/null; \
			__destroy; \
			exit 1" \
			INT TERM EXIT

		__terminate_container \
			haproxy.pool-1.1.1 \
		&> /dev/null

		describe "Runs named container"
			docker run \
				--detach \
				--name haproxy.pool-1.1.1 \
				--network ${backend_network} \
				--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
				--publish ${DOCKER_PORT_MAP_TCP_443}:443 \
				jdeathe/centos-ssh-haproxy:latest \
			&> /dev/null
	
			it "Can publish ${DOCKER_PORT_MAP_TCP_80}:80."
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
			"/usr/bin/healthcheck"
		then
			exit 1
		fi

		describe "HTTP requests"
			describe "Unencrypted response"
				it "Is unaltered."
					backend_content="$(
						curl -s \
							-H "Host: ${backend_hostname}" \
							http://127.0.0.1:${container_port_80}/
					)"

					assert equal \
						"${backend_content}" \
						"${content}"
				end
			end

			describe "Encrypted response"
				it "Is unaltered."
					backend_content="$(
						curl -sk \
							-H "Host: ${backend_hostname}" \
							https://127.0.0.1:${container_port_443}/
					)"

					assert equal \
						"${backend_content}" \
						"${content}"
				end
			end
		end

		__terminate_container \
			haproxy.pool-1.1.1 \
		&> /dev/null

		trap - \
			INT TERM EXIT
	end
}

function test_custom_configuration ()
{
	local -r backend_hostname="www.app.local"
	local -r backend_network="bridge_t1"
	local -r content="$(< test/fixture/apache/var/www/public_html/index.html)"

	local backend_content=""
	local certificate_fingerprint_file=""
	local certificate_fingerprint_server=""
	local certificate_pem_base64=""
	local container_port_80=""
	local container_port_443=""

	describe "Customised HAProxy operations"
		trap "__terminate_container haproxy.pool-1.1.1 &> /dev/null; \
			__destroy; \
			exit 1" \
			INT TERM EXIT

		describe "SSL/TLS"
			describe "Static certificate."
				if [[ -s /tmp/www.app.local.pem ]]; then
					certificate_fingerprint_file="$(
						cat \
							/tmp/www.app.local.pem \
						| sed \
							-n \
							-e '/^-----BEGIN CERTIFICATE-----$/,/^-----END CERTIFICATE-----$/p' \
						| openssl x509 \
							-fingerprint \
							-noout \
						| sed \
							-e 's~SHA1 Fingerprint=~~'
					)"

					if [[ $(uname) == "Darwin" ]]; then
						certificate_pem_base64="$(
							base64 \
								-i /tmp/www.app.local.pem
						)"
					else
						certificate_pem_base64="$(
							base64 \
								-w 0 \
								-i /tmp/www.app.local.pem
						)"
					fi
				fi

				it "Sets from file path value."		
					__terminate_container \
						haproxy.pool-1.1.1 \
					&> /dev/null

					docker run \
						--detach \
						--name haproxy.pool-1.1.1 \
						--env HAPROXY_SSL_CERTIFICATE="/var/run/tmp/www.app.local.pem" \
						--network ${backend_network} \
						--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
						--publish ${DOCKER_PORT_MAP_TCP_443}:443 \
						--volume /tmp:/var/run/tmp:ro \
						jdeathe/centos-ssh-haproxy:latest \
					&> /dev/null

					container_port_443="$(
						__get_container_port \
							haproxy.pool-1.1.1 \
							443/tcp
					)"

					if ! __is_container_ready \
						haproxy.pool-1.1.1 \
						${STARTUP_TIME} \
						"/usr/sbin/haproxy " \
						"/usr/bin/healthcheck"
					then
						exit 1
					fi

					certificate_fingerprint_server="$(
						echo -n \
						| openssl s_client \
							-connect 127.0.0.1:${container_port_443} \
							-CAfile /tmp/www.app.local.pem \
							-nbio \
							2>&1 \
						| sed \
							-n \
							-e '/^-----BEGIN CERTIFICATE-----$/,/^-----END CERTIFICATE-----$/p' \
						| openssl \
							x509 \
							-fingerprint \
							-noout \
						| sed \
							-e 's~SHA1 Fingerprint=~~'
					)"

					assert equal \
						"${certificate_fingerprint_server}" \
						"${certificate_fingerprint_file}"
				end
			end
		end

		__terminate_container \
			haproxy.pool-1.1.1 \
		&> /dev/null

		trap - \
			INT TERM EXIT
	end
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
