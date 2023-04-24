FROM alpine:3.17.3

LABEL maintainer "dave.martinka@mediavuesystems.com"

# Install the necessary packages
RUN apk update \
    && apk add --no-cache \
       dnsmasq \
       wget \
       xorriso

ENV MEMTEST_VERSION 6.10
ENV UEFI_SHELL_MAJOR_VERSION 2.2
ENV UEFI_SHELL_RELEASE_VERSION 22H2

WORKDIR /tmp

RUN mkdir -p /var/lib/tftpboot/memtest

RUN wget -q http://www.memtest.org/download/v${MEMTEST_VERSION}/mt86plus_${MEMTEST_VERSION}.binaries.zip \
    && unzip mt86plus_${MEMTEST_VERSION}.binaries.zip \
    && mv memtest64.bin /var/lib/tftpboot/memtest/ \
    && mv memtest64.efi /var/lib/tftpboot/memtest/ \
    && rm mt86plus_* memtest*

RUN mkdir -p /var/lib/tftpboot/uefishell

RUN wget -q https://github.com/pbatard/UEFI-Shell/releases/download/${UEFI_SHELL_RELEASE_VERSION}/UEFI-Shell-${UEFI_SHELL_MAJOR_VERSION}-${UEFI_SHELL_RELEASE_VERSION}-RELEASE.iso \
    && xorriso -osirrox on -indev UEFI-Shell-${UEFI_SHELL_MAJOR_VERSION}-${UEFI_SHELL_RELEASE_VERSION}-RELEASE.iso -extract / uefishell \
    && mv uefishell/efi/boot/bootx64.efi /var/lib/tftpboot/uefishell/ \
    && mv uefishell/efi/boot/bootaa64.efi /var/lib/tftpboot/uefishell/ \
    && mv uefishell/efi/boot/bootarm.efi /var/lib/tftpboot/uefishell/ \
    && rm -r uefishell* *.iso

# RUN apk update \
#     && apk add --no-cache \
#        alpine-ipxe-undionly_kpxe \
#        alpine-ipxe-ipxe_efi

# RUN cp /usr/share/alpine-ipxe/undionly.kpxe /var/lib/tftpboot/ \
#     && cp /usr/share/alpine-ipxe/ipxe.efi /var/lib/tftpboot/

# Configure PXE and TFTP
COPY tftpboot/ /var/lib/tftpboot

# Configure DNSMASQ
COPY etc/ /etc

# Start dnsmasq. It picks up default configuration from /etc/dnsmasq.conf and
# /etc/default/dnsmasq plus any command line switch
ENTRYPOINT ["dnsmasq", "--no-daemon"]
CMD ["--dhcp-range=192.168.56.2,proxy"]
