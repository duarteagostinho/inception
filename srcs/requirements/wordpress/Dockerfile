FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
	php8.2-fpm php8.2-mysql php8.2-mbstring php8.2-gd curl \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/local/bin/wp

RUN mkdir -p /run/php

COPY ./conf/www.conf /etc/php/8.2/fpm/pool.d

COPY ./tools/wp-setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wp-setup.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/wp-setup.sh"]
CMD ["/usr/sbin/php-fpm8.2", "-F"]
