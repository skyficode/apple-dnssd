FROM alpine:3.17

# include build tools, mbedtls, and DNS BIND9 
RUN apk add alpine-sdk build-base mbedtls-dev libdispatch libdispatch-dev linux-headers musl-nscd-dev bind mbedtls-utils


# BIND runs a user "named", so adjust permissions accordingly
RUN chgrp -R -L -c -v named /var/bind && \
    chmod -R -v g+w /var/bind/*

# DNS-SD Discovery Proxy needs keys 
RUN mkdir /etc/dnssd-proxy
RUN gen_key type=rsa rsa_keysize=4096 filename=server.key
RUN cert_write selfsign=1 issuer_key=server.key issuer_name=CN=dns.home.arpa not_before=20230101000000 not_after=20251231000000 is_ca=1 max_pathlen=0 output_file=server.crt
RUN mv server.key server.crt /etc/dnssd-proxy

# Apple's mDNSResponder uses different names for mbedtls tools, just link them
RUN ln -s /usr/bin/gen_key /usr/local/bin/mbedtls_gen_key && \
    ln -s /usr/bin/cert_write /usr/local/bin/mbedtls_cert_write

# add BIND's main configuration, "named.conf"
# COPY ./Clients/DockerDev/named.conf /var/bind/named.conf

# add BIND "zone" files, e.g. what stores the records
# COPY ./Clients/DockerDev/home.arpa.zone /var/bind/pri/home.arpa.zone

# add Apple Discovery Proxy (e.g. dnsextd++)  
# COPY ./Clients/DockerDev/dnssd-proxy.cf /etc/dnssd-proxy.cf

# copy the source to build
COPY ./ /usr/src/mDNSResponder/

# now build all the mDNSResponder code
RUN make os=linux -C /usr/src/mDNSResponder/mDNSPosix 
# RUN make os=linux setup build/srp-client build/srp-mdns-proxy build/keydump build/dnssd-proxy build/srputil -C /usr/src/mDNSResponder/ServiceRegistration 
RUN make os=linux -C /usr/src/mDNSResponder/ServiceRegistration

# $(BUILDDIR)/srp-dns-proxy $(BUILDDIR)/dnssd-relay

# RUN make dnsextd -C /usr/src/mDNSResponder/mDNSPosix 
# RUN make srp-client os=linux -C /usr/src/mDNSResponder/ServiceRegistration 
# RUN make srp-mdns-proxy os=linux -C /usr/src/mDNSResponder/ServiceRegistration 
# RUN make dnssd-proxy os=linux -C /usr/src/mDNSResponder/ServiceRegistration 
# RUN make keydump os=linux -C /usr/src/mDNSResponder/ServiceRegistration 
# RUN make srputil os=linux -C /usr/src/mDNSResponder/ServiceRegistration 

#RUN make dnssd-proxy srputil os=linux -C /usr/src/mDNSResponder/ServiceRegistration 
RUN make InstalledLib InstalledClients -C /usr/src/mDNSResponder/mDNSPosix && \
RUN make install -C /usr/src/mDNSResponder/ServiceRegistration

# TODO:
# - start named+dnsextd and/or discovery proxy etc

# but launch BIND, "named", to keep container running 
CMD ["named", "-c", "/var/bind/named.conf", "-g", "-u", "named"]

