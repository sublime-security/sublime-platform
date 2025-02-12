# nginx-custom-ssl

SSL support with custom cert.

To enable SSL with your custom certificate, follow the steps below:

1. Copy your certificate and key to certs/nginx.crt and certs/nginx.key
2. Copy your dhparam file to certs/dhparam.pem
3. Edit conf/nginx.conf to update `__server_names__` to your domain or IP address
4. Perform any other configuration edits that you might need
5. Run `docker build -t sublime_nginx_custom_ssl .`
6. Run `cd ..` (back to sublime-platform directory)
7. Run `docker compose --profile nginx-custom-ssl up`
