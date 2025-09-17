FROM haproxy:2.8
RUN apt-get update && apt-get install -y iputils-ping dnsutils curl vim && rm -rf /var/lib/apt/lists/*
CMD ["haproxy","-f","/usr/local/etc/haproxy/haproxy.cfg"]
