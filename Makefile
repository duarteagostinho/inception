LOGIN ?= duandrad
DATA_DIR ?= /home/$(LOGIN)/data
SECRETS_DIR := srcs/secrets

.PHONY: all init down clean fclean re

all: init
	docker compose -f srcs/docker-compose.yml up -d --build

init:
	@mkdir -p $(DATA_DIR)/database $(DATA_DIR)/wordpress $(SECRETS_DIR)
	@if [ ! -f srcs/.env ]; then \
		printf '%s\n' \
			'DOMAIN_NAME=$(LOGIN).42.fr' \
			'MYSQL_DATABASE=wordpress' \
			'MYSQL_USER=wordpress' \
			'WP_ADMIN_USER=siteowner' \
			'WP_ADMIN_EMAIL=admin@example.com' \
			'WP_USER=author' \
			'WP_USER_EMAIL=author@example.com' \
			> srcs/.env; \
		echo "init: created srcs/.env"; \
	fi
	@if [ -d "$(DATA_DIR)/database/mysql" ] && [ ! -f "$(SECRETS_DIR)/db_root_password.txt" ]; then \
		echo "init: WARNING: existing database data found but no secrets."; \
		echo "init:          generated passwords will NOT match the existing database."; \
		echo "init:          restore the original secret files or remove $(DATA_DIR)/database."; \
	fi
	@for f in db_password db_root_password wp_admin_password wp_user_password; do \
		if [ ! -f "$(SECRETS_DIR)/$$f.txt" ]; then \
			tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32 > "$(SECRETS_DIR)/$$f.txt"; \
			echo "init: created $(SECRETS_DIR)/$$f.txt"; \
		fi; \
	done

down:
	docker compose -f srcs/docker-compose.yml down

clean:
	docker compose -f srcs/docker-compose.yml down -v
	@echo "clean: note: bind-mounted data under $(DATA_DIR) is kept."

fclean: clean
	docker system prune -a -f

re: fclean all
