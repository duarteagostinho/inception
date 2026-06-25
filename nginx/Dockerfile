FROM debian:bullseye

RUN apt-get update -y && apt-get install -y nginx openssl && \
    mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/duandrad.42.fr.key \
    -out /etc/nginx/ssl/duandrad.42.fr.crt \
    -subj "/C=PT/L=Lisbon/O=42/CN=duandrad.42.fr"

COPY conf/default.conf /etc/nginx/sites-enabled/default

CMD ["nginx", "-g", "daemon off;"]

