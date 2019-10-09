readonly STARTUP_TIME=2
readonly TEST_DIRECTORY="test"

# These should ideally be a static value but hosts might be using this port so 
# need to allow for alternatives.
DOCKER_PORT_MAP_TCP_80="${DOCKER_PORT_MAP_TCP_80:-80}"
DOCKER_PORT_MAP_TCP_443="${DOCKER_PORT_MAP_TCP_443:-443}"

function __destroy ()
{
	local -r backend_alias_1="httpd_1"
	local -r backend_alias_2="httpd_2"
	local -r backend_name_1="apache-php.1"
	local -r backend_name_2="apache-php.2"
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
	local -r backend_name_1="apache-php.1"
	local -r backend_name_2="apache-php.2"
	local -r backend_network="bridge_t1"
	local -r backend_release="3.3.3"

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

# Custom shpec matcher
# Match a string with a case insensitive Extended Regular Expression pattern.
function __shpec_matcher_egrepi ()
{
	local pattern="${2:-}"
	local string="${1:-}"

	printf -- \
		'%s' \
		"${string}" \
	| grep -iqE -- \
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
	local -r backend_name_1="apache-php.1"
	local -r backend_name_2="apache-php.2"
	local -r backend_network="bridge_t1"
	local -r content="$(< test/fixture/apache/var/www/public_html/index.html)"

	local backend_content=""
	local backend_response_code=""
	local cli_server=""
	local cli_server_state="maint"
	local cli_servers="http/web_1 http/web_2 https/web_1 https/web_2"
	local container_port_80=""
	local container_port_443=""
	local logs_since=1
	local logs_timeout=60

	describe "Basic HAProxy operations"
		trap "__terminate_container haproxy.1 &> /dev/null; \
			__destroy; \
			exit 1" \
			INT TERM EXIT

		__terminate_container \
			haproxy.1 \
		&> /dev/null

		describe "Runs named container"
			docker run \
				--detach \
				--name haproxy.1 \
				--network ${backend_network} \
				--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
				--publish ${DOCKER_PORT_MAP_TCP_443}:443 \
				jdeathe/centos-ssh-haproxy:latest \
			&> /dev/null
	
			it "Can publish ${DOCKER_PORT_MAP_TCP_80}:80."
				container_port_80="$(
					__get_container_port \
						haproxy.1 \
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
						haproxy.1 \
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
			haproxy.1 \
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

		describe "Monitor URI"
			describe "Backend up"
				describe "Unencrypted response"
					it "Is 200 OK."
						backend_response_code="$(
							curl -sI \
								-o /dev/null \
								-w "%{http_code}" \
								-H "Host: ${backend_hostname}" \
								http://127.0.0.1:${container_port_80}/status
						)"

						backend_content="$(
							curl -s \
								-H "Host: ${backend_hostname}" \
								http://127.0.0.1:${container_port_80}/status
						)"

						assert equal \
							"${backend_response_code}:${backend_content}" \
							"200:OK"
					end
				end

				describe "Encrypted response"
					it "Is 200 OK."
						backend_response_code="$(
							curl -skI \
								-o /dev/null \
								-w "%{http_code}" \
								-H "Host: ${backend_hostname}" \
								https://127.0.0.1:${container_port_443}/status
						)"

						backend_content="$(
							curl -sk \
								-H "Host: ${backend_hostname}" \
								https://127.0.0.1:${container_port_443}/status
						)"

						assert equal \
							"${backend_response_code}:${backend_content}" \
							"200:OK"
					end
				end
			end

			describe "Backend down"
				# Put backend servers into maintenance state
				cli_server_state="maint"
				for cli_server in ${cli_servers}
				do
					docker exec -i \
						haproxy.1 \
						socat - UNIX:/var/lib/haproxy/stats-1 \
						<<< "set server ${cli_server} state ${cli_server_state}" \
					&> /dev/null
				done

				describe "Unencrypted response"
					it "Is 503 Service Unavailable."
						backend_response_code="$(
							curl -sI \
								-o /dev/null \
								-w "%{http_code}" \
								-H "Host: ${backend_hostname}" \
								http://127.0.0.1:${container_port_80}/status
						)"

						backend_content="$(
							curl -s \
								-H "Host: ${backend_hostname}" \
								http://127.0.0.1:${container_port_80}/status
						)"

						assert equal \
							"${backend_response_code}:${backend_content}" \
							"503:Service Unavailable"
					end
				end

				describe "Encrypted response"
					it "Is 503 Service Unavailable."
						backend_response_code="$(
							curl -skI \
								-o /dev/null \
								-w "%{http_code}" \
								-H "Host: ${backend_hostname}" \
								https://127.0.0.1:${container_port_443}/status
						)"

						backend_content="$(
							curl -sk \
								-H "Host: ${backend_hostname}" \
								https://127.0.0.1:${container_port_443}/status
						)"

						assert equal \
							"${backend_response_code}:${backend_content}" \
							"503:Service Unavailable"
					end
				end
			end
		end

		__terminate_container \
			haproxy.1 \
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
	local backend_location=""
	local certificate_fingerprint_file=""
	local certificate_fingerprint_server=""
	local certificate_pem_base64=""
	local container_port_80=""
	local container_port_443=""

	describe "Customised HAProxy operations"
		trap "__terminate_container haproxy.1 &> /dev/null; \
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

					printf \
						-- '%s' \
						"${certificate_pem_base64}" \
					> /tmp/www.app.local.txt
				fi

				it "Sets from base64 encoded value."
					__terminate_container \
						haproxy.1 \
					&> /dev/null

					docker run \
						--detach \
						--name haproxy.1 \
						--env HAPROXY_SSL_CERTIFICATE="${certificate_pem_base64}" \
						--network ${backend_network} \
						--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
						--publish ${DOCKER_PORT_MAP_TCP_443}:443 \
						--volume /tmp:/run/tmp:ro \
						jdeathe/centos-ssh-haproxy:latest \
					&> /dev/null

					container_port_443="$(
						__get_container_port \
							haproxy.1 \
							443/tcp
					)"

					if ! __is_container_ready \
						haproxy.1 \
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

				it "Sets from file path value."
					__terminate_container \
						haproxy.1 \
					&> /dev/null

					docker run \
						--detach \
						--name haproxy.1 \
						--env HAPROXY_SSL_CERTIFICATE="/run/tmp/www.app.local.pem" \
						--network ${backend_network} \
						--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
						--publish ${DOCKER_PORT_MAP_TCP_443}:443 \
						--volume /tmp:/run/tmp:ro \
						jdeathe/centos-ssh-haproxy:latest \
					&> /dev/null

					container_port_443="$(
						__get_container_port \
							haproxy.1 \
							443/tcp
					)"

					if ! __is_container_ready \
						haproxy.1 \
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

				it "Sets from file path with base64 encoded content."
					__terminate_container \
						haproxy.1 \
					&> /dev/null

					docker run \
						--detach \
						--name haproxy.1 \
						--env HAPROXY_SSL_CERTIFICATE="/run/tmp/www.app.local.txt" \
						--network ${backend_network} \
						--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
						--publish ${DOCKER_PORT_MAP_TCP_443}:443 \
						--volume /tmp:/run/tmp:ro \
						jdeathe/centos-ssh-haproxy:latest \
					&> /dev/null

					container_port_443="$(
						__get_container_port \
							haproxy.1 \
							443/tcp
					)"

					if ! __is_container_ready \
						haproxy.1 \
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
			haproxy.1 \
		&> /dev/null
		
		describe "HTTP/2"
			describe "Switch to example config"
				__terminate_container \
					haproxy.1 \
				&> /dev/null

				docker run \
					--detach \
					--name haproxy.1 \
					--env HAPROXY_CONFIG="/etc/haproxy/haproxy-h2.cfg" \
					--env HAPROXY_SSL_CERTIFICATE="/run/tmp/www.app.local.pem" \
					--network ${backend_network} \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--publish ${DOCKER_PORT_MAP_TCP_443}:443 \
					--volume /tmp:/run/tmp:ro \
					jdeathe/centos-ssh-haproxy:latest \
				&> /dev/null

				container_port_80="$(
					__get_container_port \
						haproxy.1 \
						80/tcp
				)"

				container_port_443="$(
					__get_container_port \
						haproxy.1 \
						443/tcp
				)"

				if ! __is_container_ready \
					haproxy.1 \
					${STARTUP_TIME} \
					"/usr/sbin/haproxy " \
					"/usr/bin/healthcheck"
				then
					exit 1
				fi

				describe "HTTP requests"
					describe "Unencrypted response"
						it "Forces HTTPS"
							backend_location="$(
								curl -skI \
									-H "Host: ${backend_hostname}" \
									http://127.0.0.1:${container_port_80}/ \
								| grep -i 'Location:'
							)"

							assert __shpec_matcher_egrepi \
								"${backend_location}" \
								"^Location:[ ]*https:\/\/${backend_hostname//./\.}\/"
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
			end
		end

		__terminate_container \
			haproxy.1 \
		&> /dev/null

		trap - \
			INT TERM EXIT
	end
}

function test_healthcheck ()
{
	local -r backend_network="bridge_t1"
	local -r event_lag_seconds=2
	local -r interval_seconds=1
	local -r retries=4
	local container_id
	local events_since_timestamp
	local health_status

	trap "__terminate_container haproxy.1 &> /dev/null; \
		__destroy; \
		exit 1" \
		INT TERM EXIT

	describe "Healthcheck"
		describe "Default configuration"
			__terminate_container \
				haproxy.1 \
			&> /dev/null

			docker run \
				--detach \
				--name haproxy.1 \
				--network ${backend_network} \
				jdeathe/centos-ssh-haproxy:latest \
			&> /dev/null

			events_since_timestamp="$(
				date +%s
			)"

			container_id="$(
				docker ps \
					--quiet \
					--filter "name=haproxy.1"
			)"

			it "Returns a valid status on starting."
				health_status="$(
					docker inspect \
						--format='{{json .State.Health.Status}}' \
						haproxy.1
				)"

				assert __shpec_matcher_egrep \
					"${health_status}" \
					"\"(starting|healthy|unhealthy)\""
			end

			it "Returns healthy after startup."
				events_timeout="$(
					awk \
						-v event_lag="${event_lag_seconds}" \
						-v interval="${interval_seconds}" \
						-v startup_time="${STARTUP_TIME}" \
						'BEGIN { print event_lag + startup_time + interval; }'
				)"

				health_status="$(
					test/health_status \
						--container="${container_id}" \
						--since="${events_since_timestamp}" \
						--timeout="${events_timeout}" \
						--monochrome \
					2>&1
				)"

				assert equal \
					"${health_status}" \
					"✓ healthy"
			end

			it "Returns unhealthy on failure."
				docker exec -t \
					haproxy.1 \
					bash -c "mv \
						/usr/sbin/haproxy \
						/usr/sbin/haproxy2" \
				&& docker exec -t \
					haproxy.1 \
					bash -c "if [[ -n \$(pgrep -f '^/usr/sbin/haproxy ') ]]; then \
						kill -9 \$(pgrep -f '^/usr/sbin/haproxy ')
					fi"

				events_since_timestamp="$(
					date +%s
				)"

				events_timeout="$(
					awk \
						-v event_lag="${event_lag_seconds}" \
						-v interval="${interval_seconds}" \
						-v retries="${retries}" \
						'BEGIN { print (2 * event_lag) + (interval * retries); }'
				)"

				health_status="$(
					test/health_status \
						--container="${container_id}" \
						--since="$(( ${event_lag_seconds} + ${events_since_timestamp} ))" \
						--timeout="${events_timeout}" \
						--monochrome \
					2>&1
				)"

				assert equal \
					"${health_status}" \
					"✗ unhealthy"
			end

			__terminate_container \
				haproxy.1 \
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
