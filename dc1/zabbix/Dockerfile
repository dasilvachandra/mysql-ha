FROM zabbix/zabbix-server-mysql:alpine-6.4-latest

LABEL maintainer="Andes Solutions"

# Copy custom config (opsional)
COPY zabbix_server.conf /etc/zabbix/zabbix_server.conf

# Tambahkan package/tools jika perlu
RUN apk add --no-cache bash curl vim

EXPOSE 10051
CMD ["docker-entrypoint.sh"]