FROM haproxy:2.8

LABEL maintainer="Andes Solutions"

# Tambahkan tools troubleshooting
RUN apt-get update && \
    apt-get install -y iputils-ping net-tools iproute2 dnsutils curl vim traceroute tcpdump && \
    rm -rf /var/lib/apt/lists/*

CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
