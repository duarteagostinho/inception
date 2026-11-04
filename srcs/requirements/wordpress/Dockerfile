FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
	php8.2-fpm php8.2-mysql php8.2-mbstring php8.2-gd curl ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

ARG WP_CLI_VERSION=2.11.0
RUN set -eux; \
	curl -fsSLO "https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar"; \
	curl -fsSLO "https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar.sha512"; \
	sha512sum -c "wp-cli-${WP_CLI_VERSION}.phar.sha512"; \
	install -m 0755 "wp-cli-${WP_CLI_VERSION}.phar" /usr/local/bin/wp; \
	rm -f "wp-cli-${WP_CLI_VERSION}.phar" "wp-cli-${WP_CLI_VERSION}.phar.sha512"

RUN mkdir -p /run/php

COPY ./conf/www.conf /etc/php/8.2/fpm/pool.d

COPY ./tools/wp-setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wp-setup.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/wp-setup.sh"]
CMD ["/usr/sbin/php-fpm8.2", "-F"]
