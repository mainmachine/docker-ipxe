# iPXE scripts and other http-accessible assets go here

Files mathcing `*.env` will be copied in to the docker volume `webroot` with the `.env` omitted. They will be served up by the `web-server` container.

*Example:*

A file named `menu.ipxe.env` will be copied as `menu.ipxe` and be accessible at the URL `http://${WEBSERVER_IP}/menu.ipxe`
