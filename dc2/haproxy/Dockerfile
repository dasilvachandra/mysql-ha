FROM haproxy:2.8

LABEL maintainer="Andes Solutions"

# Install tools troubleshooting (Alpine base image → pakai apk)
RUN apk add --no-cache \
    bash \
    iputils \
    bind-tools \
    curl \
    vim \
    tcpdump \
    net-tools \
    iproute2

# Default command jalankan haproxy dengan config
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
