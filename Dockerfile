# =============================================================================
# jdeathe/centos-ssh-haproxy
# =============================================================================
FROM jdeathe/centos-ssh:1.8.4

ARG HATOP_VERSION="0.7.7"

# -----------------------------------------------------------------------------
# Install HAProxy
# -----------------------------------------------------------------------------
RUN rpm --rebuilddb \
	&& yum -y install \
			--setopt=tsflags=nodocs \
			--disableplugin=fastestmirror \
		haproxy-1.5.18-1.el6 \
		rsyslog-5.8.10-12.el6 \
	&& yum versionlock add \
		haproxy \
		rsyslog \
	&& yum clean all \
	&& mv \
		/etc/haproxy/haproxy.cfg \
		/etc/haproxy/haproxy.cfg.default \
	&& mkdir -p \
		/etc/pki/tls/certs/sni

# -----------------------------------------------------------------------------
# Enable local syslog logging
# -----------------------------------------------------------------------------
RUN sed -i \
		-e 's~^#\$ModLoad imudp$~\$ModLoad imudp~' \
		-e 's~^#\$UDPServerRun 514$~\$UDPServerRun 514~' \
		-e 's~^\$OmitLocalLogging on$~\$OmitLocalLogging off~' \
		-e 's~^\(\$ModLoad imuxsock .*\)$~#\1~' \
		-e 's~^\(\$ModLoad imjournal .*\)$~#\1~' \
		-e 's~^\(\$IMJournalStateFile .*\)$~#\1~' \
		/etc/rsyslog.conf \
	&& mkdir -p \
		/run/systemd/journal \
	&& { \
		echo '$UDPServerAddress 127.0.0.1'; \
		echo 'local2.* /var/log/haproxy.log'; \
		echo '& stop'; \
	} > /etc/rsyslog.d/listen.conf

# -----------------------------------------------------------------------------
# Install HATop
#   usage: env TERM=xterm hatop -s /var/lib/haproxy/stats
# -----------------------------------------------------------------------------
RUN curl -LsSO \
		https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/hatop/hatop-${HATOP_VERSION}.tar.gz \
	&& tar -xzf hatop-${HATOP_VERSION}.tar.gz \
	&& cd hatop-${HATOP_VERSION} \
	&& install \
		-m 0755 \
		bin/hatop \
		/usr/local/bin \
	&& rm -rf /hatop-${HATOP_VERSION}* \
	&& echo 'alias hatop="hatop -s /var/lib/haproxy/stats-1 -i 1"' \
		> /etc/profile.d/hatop.sh

# -----------------------------------------------------------------------------
# Increase the system limits
# -----------------------------------------------------------------------------
RUN { \
		echo ''; \
		echo -e 'haproxy\tsoft\tnofile\t8388608'; \
		echo -e 'haproxy\thard\tnofile\t16777216'; \
	} >> /etc/security/limits.conf

# -----------------------------------------------------------------------------
# Copy files into place
# -----------------------------------------------------------------------------
ADD src/usr/bin \
	/usr/bin/
ADD src/usr/sbin \
	/usr/sbin/
ADD src/opt/scmi \
	/opt/scmi/
ADD src/etc/services-config/haproxy \
	/etc/services-config/haproxy/
ADD src/etc/services-config/supervisor/supervisord.d \
	/etc/services-config/supervisor/supervisord.d/
ADD src/etc/systemd/system \
	/etc/systemd/system/

RUN ln -sf \
		/etc/services-config/haproxy/haproxy-http.example.cfg \
		/etc/haproxy/haproxy.cfg \
	&& ln -sf \
		/etc/services-config/haproxy/haproxy-http.example.cfg \
		/etc/haproxy/haproxy-http.cfg \
	&& ln -sf \
		/etc/services-config/haproxy/haproxy-http-proxy.example.cfg \
		/etc/haproxy/haproxy-http-proxy.cfg \
	&& ln -sf \
		/etc/services-config/haproxy/haproxy-tcp.example.cfg \
		/etc/haproxy/haproxy-tcp.cfg \
	&& ln -sf \
		/etc/services-config/haproxy/haproxy-bootstrap.conf \
		/etc/haproxy-bootstrap.conf \
	&& ln -sf \
		/etc/services-config/haproxy/400.html.http \
		/etc/haproxy/400.html.http \
	&& ln -sf \
		/etc/services-config/haproxy/403.html.http \
		/etc/haproxy/403.html.http \
	&& ln -sf \
		/etc/services-config/haproxy/408.html.http \
		/etc/haproxy/408.html.http \
	&& ln -sf \
		/etc/services-config/haproxy/500.html.http \
		/etc/haproxy/500.html.http \
	&& ln -sf \
		/etc/services-config/haproxy/502.html.http \
		/etc/haproxy/502.html.http \
	&& ln -sf \
		/etc/services-config/haproxy/503.html.http \
		/etc/haproxy/503.html.http \
	&& ln -sf \
		/etc/services-config/haproxy/504.html.http \
		/etc/haproxy/504.html.http \
	&& ln -sf \
		/etc/services-config/supervisor/supervisord.d/haproxy-bootstrap.conf \
		/etc/supervisord.d/haproxy-bootstrap.conf \
	&& ln -sf \
		/etc/services-config/supervisor/supervisord.d/haproxy-wrapper.conf \
		/etc/supervisord.d/haproxy-wrapper.conf \
	&& ln -sf \
		/etc/services-config/supervisor/supervisord.d/rsyslogd-wrapper.conf \
		/etc/supervisord.d/rsyslogd-wrapper.conf \
	&& chmod 600 \
		/etc/services-config/haproxy/{haproxy-{http,http-proxy,tcp}.example.cfg,{400,403,408,500,502,503,504}.html.http} \
	&& chmod 600 \
		/etc/services-config/supervisor/supervisord.d/{haproxy-bootstrap,{haproxy,rsyslogd}-wrapper}.conf \
	&& chmod 700 \
		/usr/{bin/healthcheck,sbin/{haproxy-bootstrap,{haproxy,rsyslogd}-wrapper}}

EXPOSE 80 443

# -----------------------------------------------------------------------------
# Set default environment variables
# -----------------------------------------------------------------------------
ENV HAPROXY_SSL_CERTIFICATE="" \
	HAPROXY_CONFIG="/etc/haproxy/haproxy.cfg" \
	HAPROXY_HOST_NAMES="localhost.localdomain" \
	SSH_AUTOSTART_SSHD=false \
	SSH_AUTOSTART_SSHD_BOOTSTRAP=false

# -----------------------------------------------------------------------------
# Set image metadata
# -----------------------------------------------------------------------------
ARG RELEASE_VERSION="1.0.2"
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
	org.deathe.description="CentOS-6 6.9 x86_64 - HAProxy 1.5 / HATop 0.7."

HEALTHCHECK \
	--interval=0.5s \
	--timeout=1s \
	--retries=4 \
	CMD ["/usr/bin/healthcheck"]

CMD ["/usr/bin/supervisord", "--configuration=/etc/supervisord.conf"]