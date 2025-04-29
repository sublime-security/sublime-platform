# nginx-custom-ssl

SSL support with custom cert.

To enable SSL with your custom certificate, follow the steps below:

1. Copy your certificate and key to certs/nginx.crt and certs/nginx.key
2. Copy your dhparam file to certs/dhparam.pem
3. Edit conf/nginx.conf to update `__server_names__` to your domain or IP address
4. Perform any other configuration edits that you might need. Be sure to update sublime.env with the BASE_URL that will be used to access Sublime, according to your DNS configuration. See [here](https://docs.sublime.security/docs/quickstart-docker#using-a-proxy) for more details.
5. Run `docker build -t sublime_nginx_custom_ssl .`
6. Run `cd ..` (back to sublime-platform directory)
7. Run `docker compose --profile nginx-custom-ssl up` (use `-d` to run as a daemon)
8. If you made changes to sublime.env above, restart the entire stack: `docker compose --profile nginx-custom-ssl restart` (optionally `-d`)
