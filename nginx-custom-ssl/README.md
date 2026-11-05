# nginx-custom-ssl

SSL support with custom cert.

To enable SSL with your custom certificate, follow the steps below:

1. Copy your certificate and key to certs/nginx.crt and certs/nginx.key
2. Edit conf/nginx.conf to update `__server_names__` to your domain or IP address
3. Configure the `sublime.env` file in the repository root for your domain, following [Configure Sublime](https://docs.sublime.security/docs/quickstart-docker#ssl). Do not include a port in `BASE_URL` or the other public URLs.
4. Perform any other configuration edits that you might need
5. Run `docker build -t sublime_nginx_custom_ssl .`
6. Run `cd ..` (back to sublime-platform directory)
7. Run `docker compose --profile nginx-custom-ssl up`
