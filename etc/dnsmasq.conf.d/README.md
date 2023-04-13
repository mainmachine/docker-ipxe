# Additional dnsmasq config files go here

Files matching `*.conf` and `*.conf.env` will be treated as dnsmasq config files and added in to the docker image. Files matching `*.conf` will be copied as is, and those matching  `*.conf.env` will be copied with the `.env` omitted. Use the `*.conf.env` for security-sensitive configuration, as they will not be tracked by git.
