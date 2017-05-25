readonly BOOTSTRAP_BACKOFF_TIME=2
readonly TEST_DIRECTORY="test"

# These should ideally be a static value but hosts might be using this port so 
# need to allow for alternatives.
DOCKER_PORT_MAP_TCP_22="${DOCKER_PORT_MAP_TCP_22:-NULL}"
DOCKER_PORT_MAP_TCP_80="${DOCKER_PORT_MAP_TCP_80:-80}"
DOCKER_PORT_MAP_TCP_443="${DOCKER_PORT_MAP_TCP_443:-443}"

function __destroy ()
{
	:
}

function __setup ()
{
	:
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
	local container_port_80=""
	local container_port_443=""

	trap "__terminate_container haproxy.pool-1.1.1 &> /dev/null; \
		__destroy; \
		exit 1" \
		INT TERM EXIT

	describe "Basic HAProxy operations"
		__terminate_container \
			haproxy.pool-1.1.1 \
		&> /dev/null

		it "Runs a HAProxy container named haproxy.pool-1.1.1 on port ${DOCKER_PORT_MAP_TCP_80}."
			docker run \
				--detach \
				--name haproxy.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
				--publish ${DOCKER_PORT_MAP_TCP_443}:443 \
				jdeathe/centos-ssh-haproxy:latest \
			&> /dev/null

			container_port_80="$(
				docker port \
					haproxy.pool-1.1.1 \
					80/tcp
			)"
			container_port_80=${container_port_80##*:}

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

			it "Also binds to the encrypted port ${DOCKER_PORT_MAP_TCP_443}."
				container_port_443="$(
					docker port \
						haproxy.pool-1.1.1 \
						443/tcp
				)"
				container_port_443=${container_port_443##*:}

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

		# sleep ${BOOTSTRAP_BACKOFF_TIME}

		__terminate_container \
			haproxy.pool-1.1.1 \
		&> /dev/null
	end

	trap - \
		INT TERM EXIT
}

function test_custom_configuration ()
{
	:
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
	__destroy
end
