FROM alpine:3.17.3

LABEL maintainer "ferrari.marco@gmail.com"

# Install the necessary packages
RUN apk update \
    && apk add --no-cache \
       dnsmasq \
       wget

ENV MEMTEST_VERSION 5.31b

WORKDIR /tmp

RUN mkdir -p /var/lib/tftpboot/memtest

RUN wget -q http://www.memtest.org/download/archives/"$MEMTEST_VERSION"/memtest86+-"$MEMTEST_VERSION".bin.gz \
    && gunzip memtest86+-"$MEMTEST_VERSION".bin.gz \
    && mv memtest86+-$MEMTEST_VERSION.bin /var/lib/tftpboot/memtest/memtest86+

RUN apk update \
    && apk add --no-cache \
       alpine-ipxe-undionly_kpxe \
       alpine-ipxe-ipxe_efi

RUN cp /usr/share/alpine-ipxe/undionly.kpxe /var/lib/tftpboot/ \
    && cp /usr/share/alpine-ipxe/ipxe.efi /var/lib/tftpboot/

# Configure PXE and TFTP
COPY tftpboot/ /var/lib/tftpboot

# Configure DNSMASQ
COPY etc/ /etc

# Start dnsmasq. It picks up default configuration from /etc/dnsmasq.conf and
# /etc/default/dnsmasq plus any command line switch
ENTRYPOINT ["dnsmasq", "--no-daemon"]
CMD ["--dhcp-range=192.168.56.2,proxy"]
