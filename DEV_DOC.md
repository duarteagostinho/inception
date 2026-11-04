# Developer documentation

## Environment setup

Use the required Linux VM and install Docker Engine with the Compose plugin.

Create the persistent-storage directories once:

```sh
sudo mkdir -p /home/duandrad/data/wordpress /home/duandrad/data/database
```

Create the local, ignored configuration files:

```sh
make init
```

This creates, only when missing:

- `srcs/.env`
- `srcs/secrets/*.txt`

`make init` never overwrites existing files.

The generated `srcs/.env` contains the non-secret values:

```dotenv
DOMAIN_NAME=duandrad.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress
WP_ADMIN_USER=siteowner
WP_ADMIN_EMAIL=admin@example.com
WP_USER=author
WP_USER_EMAIL=author@example.com
```

The generated secret files are:

```text
srcs/secrets/db_password.txt
srcs/secrets/db_root_password.txt
srcs/secrets/wp_admin_password.txt
srcs/secrets/wp_user_password.txt
```

Each file must contain only its corresponding password. `make init` generates a
random value for each file when it is missing. Passwords are deliberately not
written into Dockerfiles, Compose environment values, or tracked documentation.

If the database directory already contains data from a previous run, keep the
original secret files. Newly generated passwords will not match that database;
remove the data directories first if you want a fresh install.

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

Use `make clean` to remove the containers and the Compose volume definitions.
Because the volumes are bind-backed, the data under `/home/duandrad/data` is kept.
`make fclean` additionally prunes unused Docker resources. To delete the persistent
data itself, remove `/home/duandrad/data/wordpress` and `/home/duandrad/data/database`
manually.

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
