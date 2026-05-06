# nginx-custom-ssl

SSL support with custom cert.

To enable SSL with your custom certificate, follow the steps below:

1. Copy your certificate and key to certs/nginx.crt and certs/nginx.key
2. Edit conf/nginx.conf to update `__server_names__` to your domain or IP address
3. Perform any other configuration edits that you might need
4. Run `docker build -t sublime_nginx_custom_ssl .`
5. Run `cd ..` (back to sublime-platform directory)
6. Run `docker compose --profile nginx-custom-ssl up`
