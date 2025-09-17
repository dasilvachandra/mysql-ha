FROM haproxy:2.8

LABEL maintainer="Andes Solutions"

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

CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
