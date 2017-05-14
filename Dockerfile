# =============================================================================
# jdeathe/centos-ssh-haproxy
# =============================================================================
FROM jdeathe/centos-ssh:1.7.5

# -----------------------------------------------------------------------------
# Install HAProxy
# -----------------------------------------------------------------------------
RUN rpm --rebuilddb \
	&& yum --setopt=tsflags=nodocs -y install \
		tar \
		gzip \
		haproxy \
		openssl \
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
		echo -e '$UDPServerAddress 127.0.0.1'; \
		echo -e 'local2.* /var/log/haproxy.log'; \
		echo -e '& stop'; \
	} > /etc/rsyslog.d/listen.conf

# -----------------------------------------------------------------------------
# Install HATop
#   usage: env TERM=xterm hatop -s /var/lib/haproxy/stats
# -----------------------------------------------------------------------------
RUN curl -LsSO \
		https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/hatop/hatop-0.7.7.tar.gz \
	&& tar -xzf hatop-0.7.7.tar.gz \
	&& cd hatop-0.7.7 \
	&& install \
		-m 755 \
		bin/hatop \
		/usr/local/bin \
	&& install \
		-m 644 \
		man/hatop.1 \
		/usr/local/share/man/man1 \
	&& gzip /usr/local/share/man/man1/hatop.1 \
	&& rm -rf /hatop-0.7.7* \
	&& echo 'alias hatop="hatop -s /var/lib/haproxy/stats -i 1"' \
		> /etc/profile.d/hatop.sh

# -----------------------------------------------------------------------------
# Increase the system limits
# -----------------------------------------------------------------------------
RUN { \
		echo -e '\nhaproxy\tsoft\tnofile\t8388608'; \
		echo -e '\nhaproxy\thard\tnofile\t16777216'; \
	} >> /etc/security/limits.conf

RUN { \
		echo ''; \
		echo 'fs.file-max = 16777216'; \
		echo 'fs.nr_open = 8388608'; \
		echo ''; \
		echo 'net.core.somaxconn = 32768'; \
		echo 'net.ipv4.ip_local_port_range = 1024 65535'; \
		echo 'net.ipv4.route.flush = 1'; \
	} >> /etc/sysctl.conf

# -----------------------------------------------------------------------------
# Copy files into place
# -----------------------------------------------------------------------------
ADD usr/sbin/haproxy-bootstrap \
	usr/sbin/haproxy-wrapper \
	usr/sbin/rsyslogd-wrapper \
	/usr/sbin/
ADD etc/services-config/haproxy/haproxy.cfg \
	/etc/services-config/haproxy/
ADD etc/services-config/supervisor/supervisord.d \
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