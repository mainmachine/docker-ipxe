FROM alpine:3.17.1

LABEL maintainer "ferrari.marco@gmail.com"

# Install the necessary packages
RUN apk update \
    && apk add --no-cache \
       dnsmasq \
       wget

ENV MEMTEST_VERSION 5.31b
# ENV SYSLINUX_VERSION 6.03
# ENV TEMP_SYSLINUX_PATH /tmp/syslinux-"$SYSLINUX_VERSION"

WORKDIR /tmp

RUN mkdir -p /var/lib/tftpboot/memtest /var/lib/tftpboot/bios /var/lib/tftpboot/uefi \
    && ln -s ../pxelinux.cfg /var/lib/tftpboot/bios/ \
    && ln -s ../pxelinux.cfg /var/lib/tftpboot/uefi/

RUN wget -q http://www.memtest.org/download/archives/"$MEMTEST_VERSION"/memtest86+-"$MEMTEST_VERSION".bin.gz \
    && gunzip memtest86+-"$MEMTEST_VERSION".bin.gz \
    && mv memtest86+-$MEMTEST_VERSION.bin /var/lib/tftpboot/memtest/memtest86+

RUN apk update \
    && apk add --no-cache \
       syslinux \
    && for target in pxelinux.0 lpxelinux.0 libcom32.c32 libutil.c32 ldlinux.c32 menu.c32 vesamenu.c32; do \
         find /usr/share/syslinux/ -name "${target}" -exec cp {} /var/lib/tftpboot/bios \;; \
       done; \
    && for target in syslinux.efi ldlinux.e64 libcom32.c32 libutil.c32 vesamenu.c32; do \
         find /usr/share/syslinux/efi -name "${target}" -exec cp {} /var/lib/tftpboot/uefi \;; \
       done; \
    && find /usr/share/syslinux -name pxechn.c32 -exec cp {} /var/lib/tftpboot/uefi \;;

# Configure PXE and TFTP
COPY tftpboot/ /var/lib/tftpboot

# Configure DNSMASQ
COPY etc/ /etc

# Start dnsmasq. It picks up default configuration from /etc/dnsmasq.conf and
# /etc/default/dnsmasq plus any command line switch
ENTRYPOINT ["dnsmasq", "--no-daemon"]
CMD ["--dhcp-range=192.168.56.2,proxy"]
