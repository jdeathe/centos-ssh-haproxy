# =============================================================================
# jdeathe/centos-ssh-haproxy
# =============================================================================
FROM jdeathe/centos-ssh:1.8.0

ARG HATOP_VERSION="0.7.7"

# -----------------------------------------------------------------------------
# Install HAProxy
# -----------------------------------------------------------------------------
RUN rpm --rebuilddb \
	&& yum -y install \
			--setopt=tsflags=nodocs \
			--disableplugin=fastestmirror \
		haproxy \
		openssl \
		rsyslog \
		tar \
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
	&& echo 'alias hatop="hatop -s /var/lib/haproxy/stats -i 1"' \
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
ADD src/usr/sbin/haproxy-bootstrap \
	src/usr/sbin/haproxy-wrapper \
	src/usr/sbin/rsyslogd-wrapper \
	/usr/sbin/
ADD src/etc/services-config/haproxy/haproxy.cfg \
	/etc/services-config/haproxy/
ADD src/etc/services-config/supervisor/supervisord.d \
	/etc/services-config/supervisor/supervisord.d/

RUN ln -sf \
		/etc/services-config/haproxy/haproxy.cfg \
		/etc/haproxy/haproxy.cfg \
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
		/etc/services-config/haproxy/haproxy.cfg \
	&& chmod 600 \
		/etc/services-config/supervisor/supervisord.d/{haproxy-bootstrap,{haproxy,rsyslogd}-wrapper}.conf \
	&& chmod 700 \
		/usr/sbin/{haproxy-bootstrap,{haproxy,rsyslogd}-wrapper}

EXPOSE 80 443

# -----------------------------------------------------------------------------
# Set default environment variables
# -----------------------------------------------------------------------------
ENV HAPROXY_CONFIG="/etc/haproxy/haproxy.cfg" \
	SSH_AUTOSTART_SSHD=false \
	SSH_AUTOSTART_SSHD_BOOTSTRAP=false

# -----------------------------------------------------------------------------
# Set image metadata
# -----------------------------------------------------------------------------
LABEL \
	maintainer="James Deathe <james.deathe@gmail.com>"

CMD ["/usr/bin/supervisord", "--configuration=/etc/supervisord.conf"]