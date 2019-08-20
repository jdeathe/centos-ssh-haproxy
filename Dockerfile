FROM jdeathe/centos-ssh:1.11.0

ARG HATOP_VERSION="0.7.7"
ARG RELEASE_VERSION="1.3.0"

# ------------------------------------------------------------------------------
# Base install of required packages
# ------------------------------------------------------------------------------
RUN yum -y install \
			--setopt=tsflags=nodocs \
			--disableplugin=fastestmirror \
		haproxy-1.5.18-1.el6 \
		rsyslog7-7.4.10-7.el6 \
		socat-1.7.2.3-1.el6 \
	&& yum versionlock add \
		haproxy \
		rsyslog \
		socat \
	&& yum clean all \
	&& curl -LsSO \
		https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/hatop/hatop-${HATOP_VERSION}.tar.gz \
	&& tar -xzf hatop-${HATOP_VERSION}.tar.gz \
	&& cd hatop-${HATOP_VERSION} \
	&& install \
		-m 0755 \
		bin/hatop \
		/usr/local/bin \
	&& rm -rf /hatop-${HATOP_VERSION}*

# ------------------------------------------------------------------------------
# Copy files into place
# ------------------------------------------------------------------------------
ADD src /

# ------------------------------------------------------------------------------
# Provisioning
# - Increase the system limits
# - Add required directories
# - Enable local syslog logging
# - Add hatop alias
# - Replace placeholders with values in systemd service unit template
# - Backup default haproxy configuration
# - Replace default haproxy configuration with haproxy-http.cfg
# - Set permissions
# ------------------------------------------------------------------------------
RUN { printf -- \
		'\nhaproxy\tsoft\tnofile\t%s\nhaproxy\thard\tnofile\t%s\n' \
		'8388608' \
		'16777216'; \
	} >> /etc/security/limits.conf \
	&& mkdir -p \
		{/etc/pki/tls/certs/sni,/run/systemd/journal} \
	&& sed -i \
		-e 's~^#\$ModLoad imudp$~\$ModLoad imudp~' \
		-e 's~^#\$UDPServerRun 514$~\$UDPServerRun 514~' \
		-e 's~^\(\$OmitLocalLogging .*\)$~#\1~' \
		-e 's~^\(\$ModLoad imjournal .*\)$~#\1~' \
		-e 's~^\(\$ModLoad imklog .*\)$~#\1~' \
		-e 's~^\(\$ModLoad imuxsock .*\)$~#\1~' \
		-e 's~^\(\$IMJournalStateFile .*\)$~#\1~' \
		/etc/rsyslog.conf \
	&& { printf -- \
		'$UDPServerAddress %s\nlocal2.* %s\n& stop\n' \
		'127.0.0.1' \
		'/dev/stdout'; \
	} > /etc/rsyslog.d/listen.conf \
	&& printf -- 'alias hatop="%s"' \
		"hatop -s /var/lib/haproxy/stats-1 -i 1" \
		> /etc/profile.d/hatop.sh \
	&& sed -i \
		-e "s~{{RELEASE_VERSION}}~${RELEASE_VERSION}~g" \
		/etc/systemd/system/centos-ssh-haproxy@.service \
	&& mv \
		/etc/haproxy/haproxy.cfg \
		/etc/haproxy/haproxy.cfg.default \
	&& cp \
		/etc/haproxy/haproxy-http.cfg \
		/etc/haproxy/haproxy.cfg \
	&& chmod 600 \
		/etc/haproxy/{{haproxy,haproxy-{http,http-proxy,tcp}}.cfg,{400,403,408,500,502,503,504}.html.http} \
	&& chmod 600 \
		/etc/supervisord.d/{20-haproxy-bootstrap,{50-rsyslogd,90-haproxy}-wrapper}.conf \
	&& chmod 700 \
		/usr/{bin/healthcheck,sbin/{haproxy-bootstrap,{haproxy,rsyslogd}-wrapper}}

EXPOSE 80 443

# ------------------------------------------------------------------------------
# Set default environment variables
# ------------------------------------------------------------------------------
ENV \
	ENABLE_SSHD_WRAPPER="false" \
	ENABLE_SSHD_BOOTSTRAP="false" \
	HAPROXY_CONFIG="/etc/haproxy/haproxy.cfg" \
	HAPROXY_HOST_NAMES="localhost.localdomain" \
	HAPROXY_SSL_CERTIFICATE=""

# ------------------------------------------------------------------------------
# Set image metadata
# ------------------------------------------------------------------------------
LABEL \
	maintainer="James Deathe <james.deathe@gmail.com>" \
	install="docker run \
--rm \
--privileged \
--volume /:/media/root \
jdeathe/centos-ssh-haproxy:${RELEASE_VERSION} \
/usr/sbin/scmi install \
--chroot=/media/root \
--name=\${NAME} \
--tag=${RELEASE_VERSION}" \
	uninstall="docker run \
--rm \
--privileged \
--volume /:/media/root \
jdeathe/centos-ssh-haproxy:${RELEASE_VERSION} \
/usr/sbin/scmi uninstall \
--chroot=/media/root \
--name=\${NAME} \
--tag=${RELEASE_VERSION}" \
	org.deathe.name="centos-ssh-haproxy" \
	org.deathe.version="${RELEASE_VERSION}" \
	org.deathe.release="jdeathe/centos-ssh-haproxy:${RELEASE_VERSION}" \
	org.deathe.license="MIT" \
	org.deathe.vendor="jdeathe" \
	org.deathe.url="https://github.com/jdeathe/centos-ssh-haproxy" \
	org.deathe.description="HAProxy 1.5 / HATop 0.7 - CentOS-6 6.10 x86_64."

HEALTHCHECK \
	--interval=1s \
	--timeout=1s \
	--retries=4 \
	CMD ["/usr/bin/healthcheck"]

CMD ["/usr/bin/supervisord", "--configuration=/etc/supervisord.conf"]
