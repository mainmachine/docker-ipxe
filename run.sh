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
      docker cp tftpboot/pxelinux.cfg/${menufile} ${DNSMASQ_CONTAINER_NAME}:/var/lib/tftpboot/pxelinux.cfg/${menufilerename}
      docker exec ${DNSMASQ_CONTAINER_NAME} sh -c "echo \"INCLUDE pxelinux.cfg/${menufilerename}\" >> /var/lib/tftpboot/pxelinux.cfg/additional_menu_entries"
      ;;
  esac
done

# ...also for ipxe and other files
for tftpbootfile in tftpboot/*; do
  if [ -f "$tftpbootfile" ]; then
    tftpbootfile=$(basename $tftpbootfile)
    case $tftpbootfile in
      *example*)
        true # Do nothing
        ;;
      *)
        tftpbootfilerename=${tftpbootfile%*.env}
        docker cp tftpboot/${tftpbootfile} ${DNSMASQ_CONTAINER_NAME}:/var/lib/tftpboot/${tftpbootfilerename}
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
      docker cp ${conffile} ${DNSMASQ_CONTAINER_NAME}:/${conffile%*.env}
      ;;
    *)
      true # Do nothing
      ;;
  esac
done

# ...and ALSO apache files
for htdocsfile in usr/local/apache2/htdocs/*; do
  htdocsfile=$(basename $htdocsfile)
  case $htdocsfile in
    *example*|READEME*)
      true # Do nothing
      ;;
    *)
      htdocsfilerename=${htdocsfile%*.env}
      docker cp usr/local/apache2/htdocs/${htdocsfile} ${WEBSERVER_CONTAINER_NAME}:/usr/local/apache2/htdocs/${htdocsfilerename}
      ;;
  esac
done

docker exec ${DNSMASQ_CONTAINER_NAME} sh -c 'chown -R $(id -un):$(id -gn) /etc/dnsmasq.conf.d /var/lib/tftpboot'

# Restart to use refreshed configs
docker-compose restart
