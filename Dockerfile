# =============================================================================
# jdeathe/centos-ssh-haproxy
# =============================================================================
FROM jdeathe/centos-ssh:centos-7-2.0.1

MAINTAINER James Deathe <james.deathe@gmail.com>

RUN rpm --rebuilddb \
	&& yum --setopt=tsflags=nodocs -y install \
	tar \
	gzip \
	haproxy \
	openssl \
	&& yum clean all

RUN mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.default

# Install HATop
# Usage: env TERM=xterm hatop -s /var/lib/haproxy/stats
RUN curl -LsSO http://hatop.googlecode.com/files/hatop-0.7.7.tar.gz \
	&& tar -xzf hatop-0.7.7.tar.gz \
	&& cd hatop-0.7.7 \
	&& install -m 755 bin/hatop /usr/local/bin \
	&& install -m 644 man/hatop.1 /usr/local/share/man/man1 \
	&& gzip /usr/local/share/man/man1/hatop.1 \
	&& rm -rf hatop-0.7.7*

# TODO Needs to be in a boostrap otherwise the key is part of the image
# TODO Server Name needs to be a variable
# TODO Use Let's Encrypt to periodically generate a certificate
# Generate a self-signed certificate
RUN mkdir -p /etc/haproxy/certs/ \
	&& openssl req \
	-x509 \
	-sha256 \
	-nodes \
	-newkey rsa:4096 \
	-days 365 \
	-subj "/C=GB/ST=STATE/L=LOCALITY/O=ORGANISATION/CN=app-1.local" \
	-keyout /etc/haproxy/certs/haproxy.key \
	-out /etc/haproxy/certs/haproxy.pem \
	&& cat /etc/haproxy/certs/haproxy.pem \
		/etc/haproxy/certs/haproxy.key \
		> /etc/haproxy/certs/app-1.local.pem

# Increase the FD limit to 8015 or more
RUN { \
		echo -e '\nhaproxy\tsoft\tnofile\t8192'; \
		echo -e '\nhaproxy\thard\tnofile\t48052'; \
	} >> /etc/security/limits.conf

RUN { \
		echo ''; \ 
		echo 'fs.file-max = 1048576'; \
		echo 'fs.file-nr = 1025216 0 1048576'; \
		echo 'fs.nr_open = 1048576'; \
	} >> /etc/sysctl.conf

# -----------------------------------------------------------------------------
# Copy files into place
# -----------------------------------------------------------------------------
ADD usr/sbin/haproxy-start \
	/usr/sbin/haproxy-start
ADD etc/services-config/haproxy/haproxy.cfg \
	/etc/services-config/haproxy/

ADD etc/services-config/supervisor/supervisord.d/haproxy.conf \
	/etc/services-config/supervisor/supervisord.d/

RUN ln -sf /etc/services-config/supervisor/supervisord.conf /etc/supervisord.conf \
	&& ln -sf /etc/services-config/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg \
	&& ln -sf /etc/services-config/supervisor/supervisord.d/haproxy.conf /etc/supervisord.d/haproxy.conf \
	&& chmod +x /usr/sbin/haproxy-start

EXPOSE 80 443

# -----------------------------------------------------------------------------
# Set default environment variables
# -----------------------------------------------------------------------------
ENV HAPROXY_CONFIG="/etc/haproxy/haproxy.cfg" \
	HAPROXY_SERVER_ADDRESS_1="192.169.99.100" \
	HAPROXY_SERVER_ADDRESS_2="" \
	HAPROXY_SERVER_ADDRESS_3="" \
	HAPROXY_SERVER_ADDRESS_4=""

CMD ["/usr/bin/supervisord", "--configuration=/etc/supervisord.conf"]