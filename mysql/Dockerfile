FROM mysql:8.0.30

LABEL maintainer="Andes Solutions"

# Tambahkan tools troubleshooting
RUN microdnf install -y iputils net-tools iproute dnsutils curl vim traceroute tcpdump && \
    microdnf clean all

CMD ["mysqld"]
