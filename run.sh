#!/bin/bash

. .env

docker-compose -d up

# Update menu files in running container - required because we use volumes
#   to allow manual modifications to menu files in running container
for menufile in tftpboot/pxelinux.cfg/*; do
  case $(basename $menufile) in
    additional_menu_entries)
      true # Do nothing
      ;;
    *)
      menufilerename=${menufile%*.env}
      docker cp ${menufile} ${CONTAINERNAME}:/var/lib/${menufilerename}
      docker exec ${CONTAINERNAME} sh -c "echo \"INCLUDE pxelinux.cfg/${menufilerename}\" >> /var/lib/tftpboot/pxelinux.cfg/additional_menu_entries"
      ;;
  esac
done

# ...and the same goes for dnsmasq configs
for conffile in etc/dnsmasq.conf.d/*; do
  case $(basename $conffile) in
    *.conf.env|*.conf)
      docker cp ${conffile} ${CONTAINERNAME}:/${conffile%*.env}
      ;;
    *)
      true # Do nothing
      ;;
  esac
done
