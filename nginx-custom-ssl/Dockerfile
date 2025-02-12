FROM nginx:1.23.3

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/ssl-params.conf /etc/nginx/ssl-params.conf

COPY certs/nginx.crt /etc/ssl/certs/nginx.crt
COPY certs/nginx.key /etc/ssl/private/nginx.key
COPY certs/dhparam.pem /etc/ssl/certs/dhparam.pem

CMD nginx -g "daemon off;"
