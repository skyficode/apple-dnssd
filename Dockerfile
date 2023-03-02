## BUILDER CONTAINER

# build some code needed for container, in a local container first... (required buildx / BuildKit)
FROM alpine:3.17

# include build tools, mbedtls, and DNS BIND9 
RUN apk add alpine-sdk build-base mbedtls-dev libdispatch libdispatch-dev linux-headers bind mbedtls-utils

# BIND runs a user "named", so adjust permissions accordingly
RUN chgrp -R -L -c -v named /var/bind && \
    chmod -R -v g+w /var/bind/*

# DNS-SD Discovery Proxy needs keys 
RUN mkdir /etc/dnssd-proxy
RUN gen_key type=rsa rsa_keysize=4096 filename=server.key
RUN cert_write selfsign=1 issuer_key=server.key issuer_name=CN=dns.home.arpa not_before=20230101000000 not_after=20251231000000 is_ca=1 max_pathlen=0 output_file=server.crt
RUN mv server.key server.crt /etc/dnssd-proxy

# add BIND's main configuration, "named.conf"
COPY ./Clients/DockerDev/named.conf /var/bind/named.conf

# add BIND "zone" files, e.g. what stores the records
COPY ./Clients/DockerDev/home.arpa.zone /var/bind/pri/home.arpa.zone

# add Apple Discovery Proxy (e.g. dnsextd++)  
COPY ./Clients/DockerDev/dnssd-proxy.cf /etc/dnssd-proxy.cf


# launch BIND, "named"
CMD ["named", "-c", "/var/bind/named.conf", "-g", "-u", "named"]