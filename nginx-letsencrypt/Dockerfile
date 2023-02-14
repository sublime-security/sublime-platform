FROM nginx

RUN apt-get update &&  apt-get install -y \
  wget \
  certbot \
  python3-certbot-nginx

COPY nginx.conf /etc/nginx/nginx.conf
COPY start.sh /
CMD /start.sh
