# User documentation

## Services

The stack provides a WordPress website over HTTPS. Nginx is the public entrypoint,
WordPress handles PHP requests through PHP-FPM, and MariaDB stores the site data.
MariaDB and PHP-FPM are internal services and are not published on host ports.

## Start and stop

From the repository root on the VM:

```sh
make
```

Stop the stack while preserving its data:

```sh
make down
```

To remove the containers and the Compose volume definitions, use `make clean`.
The bind-mounted data under `/home/duandrad/data` is kept. Remove that directory
manually only if a fresh installation is intended.

## Website and administration

Add the VM address to `/etc/hosts`:

```text
<vm-ip> duandrad.42.fr
```

Visit:

- Website: `https://duandrad.42.fr/`
- Administration: `https://duandrad.42.fr/wp-admin/`

The certificate is self-signed, so a browser warning is expected.

## Credentials

Passwords are stored locally in the ignored `srcs/secrets/` directory and are mounted
into the relevant containers at `/run/secrets`. `make init` generates random password
values for those files and creates `srcs/.env` if they do not exist. Never commit
those files. The administrator
username is configured by `WP_ADMIN_USER` in `srcs/.env`; it is intentionally not
named `admin` to satisfy the subject requirement.

## Health checks

List service state:

```sh
docker compose -f srcs/docker-compose.yml ps
```

MariaDB should show `healthy`; all three services should be running. Inspect recent
logs if needed:

```sh
docker compose -f srcs/docker-compose.yml logs --tail=100
```

Confirm HTTPS responds:

```sh
curl -k -I https://duandrad.42.fr/
```
