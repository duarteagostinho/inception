FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y php7.4 \
	php7.4-fpm php7.4-mysql	php7.4-mbstring \
	php7.4-gd curl && rm -rf /var/lib/apt/lists/*

#  installs wp cli tool, to manage wp via cli
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/local/bin/wp

# this is needed by the fpm to temporarily store socket files
RUN mkdir -p /run/php

# copies our conf to the fpm config dir
COPY ./conf/www.conf /etc/php/7.4/fpm/pool.d

# copies our script for the initial setup 
COPY ./tools/wp-setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wp-setup.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/wp-setup.sh"] # runs script before initializing fpm
CMD ["/usr/sbin/php-fpm7.4", "-F"] # using -F, we make fpm move to PID 1 (main process)
