# Developer documentation

## Environment setup

Use the required Linux VM and install Docker Engine with the Compose plugin. Create
the persistent-storage directories:

```sh
sudo mkdir -p /home/duandrad/data/wordpress /home/duandrad/data/database
```

Create `srcs/.env` with non-secret values:

```dotenv
DOMAIN_NAME=duandrad.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress
WP_ADMIN_USER=siteowner
WP_ADMIN_EMAIL=admin@example.com
WP_USER=author
WP_USER_EMAIL=author@example.com
```

Create these local, ignored secret files:

```text
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
```

Each file must contain only its corresponding password. Passwords are deliberately
not written into Dockerfiles, Compose environment values, or tracked documentation.

## Build and launch

The Makefile delegates to `srcs/docker-compose.yml`:

```sh
make
```

Equivalent direct commands:

```sh
docker compose -f srcs/docker-compose.yml build
docker compose -f srcs/docker-compose.yml up
```

The Compose file builds each service from its own Dockerfile. It does not pull a
ready-made application image.

## Service management

```sh
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs --follow
docker compose -f srcs/docker-compose.yml restart
docker compose -f srcs/docker-compose.yml down
```

Use `make clean` to remove named volumes, and `make fclean` to additionally prune
unused Docker resources. These commands can destroy persistent application data.

## Persistence

The `wp-data` volume stores `/var/www/html`; `mariadb-data` stores
`/var/lib/mysql`. Their local driver options point to:

```text
/home/duandrad/data/wordpress
/home/duandrad/data/database
```

Inspect the mapping with:

```sh
docker volume inspect srcs_wp-data srcs_mariadb-data
```

The volume names may include the Compose project prefix. Do not replace these named
volumes with service-level bind mounts: named persistent storage is a mandatory
part of the subject.

## Verification

Before submission, verify:

```sh
docker compose -f srcs/docker-compose.yml config
docker compose -f srcs/docker-compose.yml ps
curl -k -I https://duandrad.42.fr/
```

Check that only Nginx publishes a host port, TLS is configured for 1.2/1.3, the
database and WordPress services are reachable only over the private network, and
the site remains available after a container restart.
