*This project has been created as part of the 42 curriculum by duandrad.*

# Inception

## Description

Inception is a small WordPress infrastructure built with Docker Compose. It contains
three dedicated services:

- Nginx terminates TLS and is the only service exposed on host port 443.
- WordPress runs PHP-FPM and serves the application files.
- MariaDB stores the WordPress database.

The services communicate over a private Docker bridge network. The WordPress files
and MariaDB data are stored in separate named volumes backed by
`/home/duandrad/data` on the evaluation virtual machine.

### Design choices

- **Virtual machine vs Docker:** the required VM provides an isolated Linux
  environment; Docker provides lightweight, reproducible service isolation inside it.
- **Secrets vs environment variables:** non-sensitive settings are in `srcs/.env`;
  passwords are supplied as Docker secrets mounted at `/run/secrets`.
- **Docker network vs host network:** the user-defined bridge network gives services
  DNS-based service discovery without exposing MariaDB or PHP-FPM to the host.
- **Docker volumes vs bind mounts:** named volumes give Docker-managed persistence;
  their local driver stores the data at the required host paths without mounting
  arbitrary application directories directly into containers.

## Instructions

### Prerequisites

- A Linux virtual machine with Docker Engine and the Docker Compose plugin.
- The `duandrad.42.fr` name mapped to the VM IP in `/etc/hosts`.
- The directories `/home/duandrad/data/wordpress` and
  `/home/duandrad/data/database`.

The local `srcs/.env` and `secrets/` files are intentionally ignored by Git. Create
them from the variable and secret names used in the Compose file before starting the
project.

### Build and run

```sh
make
```

Stop the containers without removing data:

```sh
make down
```

Remove containers and named volumes:

```sh
make clean
```

`make fclean` additionally removes unused Docker images and resources.

Open `https://duandrad.42.fr/` after accepting the self-signed certificate. The
administration panel is at `https://duandrad.42.fr/wp-admin/`.

## Resources

- [Docker Compose documentation](https://docs.docker.com/compose/)
- [Docker volumes](https://docs.docker.com/engine/storage/volumes/)
- [Docker secrets](https://docs.docker.com/engine/swarm/secrets/)
- [NGINX TLS configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [WP-CLI handbook](https://make.wordpress.org/cli/handbook/)
- [MariaDB documentation](https://mariadb.com/kb/en/documentation/)

AI was used to help inspect build failures, compare the implementation with the
subject, identify configuration issues, and design verification commands. Every
change is reviewed and tested against the subject requirements before submission.
