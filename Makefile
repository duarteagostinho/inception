all:
	docker compose -f srcs/docker-compose.yml up -d --build

init:
	@mkdir -p srcs/secrets
	@[ -f srcs/.env ] || printf '%s\n' \
		'DOMAIN_NAME=duandrad.42.fr' \
		'MYSQL_DATABASE=wordpress' \
		'MYSQL_USER=wordpress' \
		'WP_ADMIN_USER=siteowner' \
		'WP_ADMIN_EMAIL=admin@example.com' \
		'WP_USER=author' \
		'WP_USER_EMAIL=author@example.com' \
		> srcs/.env
	@[ -f srcs/secrets/db_password.txt ] || echo 'db_password' > srcs/secrets/db_password.txt
	@[ -f srcs/secrets/db_root_password.txt ] || echo 'root_password' > srcs/secrets/db_root_password.txt
	@[ -f srcs/secrets/wp_admin_password.txt ] || echo 'admin_password' > srcs/secrets/wp_admin_password.txt
	@[ -f srcs/secrets/wp_user_password.txt ] || echo 'user_password' > srcs/secrets/wp_user_password.txt

down:
	docker compose -f srcs/docker-compose.yml down

clean:
	docker compose -f srcs/docker-compose.yml down -v

fclean: clean
	docker system prune -a -f

re: fclean all
