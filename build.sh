#!/bin/bash

. .env

export NAMESPACE=${NAMESPACE:-mynamespace}
export IMAGENAME=${IMAGENAME:-myimagename}
export IPXE_TARGETS=${IPXE_TARGETS:-bin-x86_64-efi/ipxe.efi}
export IPXE_EMBED_SCRIPT=${IPXE_EMBED_SCRIPT:-web-server.ipxe}
export datecode="v$(date +%y.%m.%d_%H.%M)"

buildImage() {
  namespace="$1"
  imagename="$2"
  uniquetag="$3"

  echo "Building docker image for ${namespace}/${imagename}:${uniquetag}"

  currentlatestimage=$(docker inspect --format {{.Id}} ${namespace}/${imagename}:latest || echo "")

  docker build \
    -t ${namespace}/${imagename}:${uniquetag} \
    -t ${namespace}/${imagename} \
    .

  currentlatestimage=$(docker inspect --format {{.Id}} ${namespace}/${imagename}:latest || echo "")

  if [ "$previouslatesteimage" = "$currentlatestimage" ] && [ -n "$previouslatesteimage" ]; then
    echo "${namespace}/${imagename}:${uniquetag} is identical to previous build, discarding ${uniquetag}"
    docker rmi ${namespace}/${imagename}:${uniquetag}
  else
    echo "Tagging ${namespace}/${imagename}:${uniquetag} as latest..."
    docker image tag ${namespace}/${imagename}:${uniquetag} ${namespace}/${imagename}:latest
  fi
}

buildIpxe() {
  export ipxetarget="$1"
  export ipxeembedscript="$2"
  export threads="$(nproc --ignore=1)"
  export targetdir="$(dirname $ipxetarget)"

  makeopts=""

  case $ipxetarget in
    *-arm32-*|*-arm64-*)
      export makeopts="CROSS=aarch64-linux-gnu-"
      ;;
    *)
      # Assume x86 or x86_64 compatible
      true # Do nothing
      ;;
  esac

  (
    cd ipxe/src
    make clean
    make -j${threads} ${makeopts} ${ipxetarget} EMBED=${ipxeembedscript}
    # mkdir -p ../../usr/local/apache2/htdocs/${targetdir}
    # cp ${ipxetarget} ../../usr/local/apache2/htdocs/${targetdir}/
    mkdir -p ../../tftpboot/${targetdir}
    cp ${ipxetarget} ../../tftpboot/${targetdir}/
  )
}

# Back up additional_menu_entries file
cp tftpboot/pxelinux.cfg/additional_menu_entries{,.bak}

for menufile in tftpboot/pxelinux.cfg/*; do
  case $(basename $menufile) in
    default|additional_menu_entries*|*example*|*.env)
      true # Do nothing
      ;;
    *)
      # Add an INCLUDE entry
      printf "\n%s\n" "INCLUDE pxelinux.cfg/${menufile}" >> tftpboot/pxelinux.cfg/additional_menu_entries
      ;;
  esac
done

for IPXE_TARGET in ${IPXE_TARGETS}; do
  buildIpxe ${IPXE_TARGET} "$(readlink -f ${IPXE_EMBED_SCRIPT})"
done

buildImage ${NAMESPACE} ${IMAGENAME} ${datecode}

# Restore additional_menu_entries file
cp tftpboot/pxelinux.cfg/additional_menu_entries{.bak,}
