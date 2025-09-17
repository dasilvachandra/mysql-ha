FROM mysql:8.0.30

LABEL maintainer="Andes Solutions"

# Tambahkan tools troubleshooting
RUN apt-get update && \
    apt-get install -y iputils-ping net-tools iproute2 dnsutils curl vim traceroute tcpdump && \
    rm -rf /var/lib/apt/lists/*

CMD ["mysqld"]
