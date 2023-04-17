#!/bin/bash

. .env

docker-compose up -d

# Update menu files in running container - required because we use volumes
#   to allow manual modifications to menu files in running container
for menufile in tftpboot/pxelinux.cfg/*; do
  menufile=$(basename $menufile)
  case $menufile in
    default|additional_menu_entries*|*example*)
      true # Do nothing
      ;;
    *)
      menufilerename=${menufile%*.env}
      docker cp tftpboot/pxelinux.cfg/${menufile} ${CONTAINERNAME}:/var/lib/tftpboot/pxelinux.cfg/${menufilerename}
      docker exec ${CONTAINERNAME} sh -c "echo \"INCLUDE pxelinux.cfg/${menufilerename}\" >> /var/lib/tftpboot/pxelinux.cfg/additional_menu_entries"
      ;;
  esac
done

# ...also for ipxe and other files
for tftpbootfile in tftpboot/*; do
  if [ -f "$file" ]; then
    tftpbootfile=$(basename $tftpbootfile)
    case $tftpbootfile in
      *example*)
        true # Do nothing
        ;;
      *)
        tftpbootfilerename=${tftpbootfile%*.env}
        docker cp tftpboot/${tftpbootfile} ${CONTAINERNAME}:/var/lib/tftpboot/${tftpbootfilerename}
        ;;
    esac
  fi
done

# ...and the same goes for dnsmasq configs
for conffile in etc/dnsmasq.conf.d/*; do
  case $(basename $conffile) in
    example.conf|README.md)
      true # Do nothing
      ;;
    *.conf.env|*.conf)
      docker cp ${conffile} ${CONTAINERNAME}:/${conffile%*.env}
      ;;
    *)
      true # Do nothing
      ;;
  esac
done

docker exec ${CONTAINERNAME} sh -c 'chown -R $(id -un):$(id -gn) /etc/dnsmasq.conf.d /var/lib/tftpboot'

# Restart to use refreshed configs
docker-compose restart
