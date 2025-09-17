FROM haproxy:2.8

LABEL maintainer="Andes Solutions"

# pastikan build dijalankan dengan root
USER root

# Install tools troubleshooting (Debian base image → pakai apt-get)
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    iputils-ping \
    dnsutils \
    curl \
    vim \
    tcpdump \
    net-tools \
    iproute2 && \
    rm -rf /var/lib/apt/lists/*

# balik lagi ke user haproxy untuk run service
USER haproxy

CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
