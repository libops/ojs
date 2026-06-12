# Open Journal Systems (OJS) Docker Container

Dockerized deployment of [Open Journal Systems](https://pkp.sfu.ca/software/ojs/) based on the [Islandora Buildkit](https://github.com/Islandora-Devops/isle-buildkit) OJS PHP/nginx base image.

## Quick Start

```bash
make up
```

Access OJS at `http://localhost`.

`make up` runs `scripts/init-if-needed.sh`, which inspects the rendered Docker Compose config and only runs the `init` service when required secrets or named volumes are missing.

The installation will run automatically on first startup. The default admin credentials are:
- Username: `admin` (configurable via `OJS_ADMIN_USERNAME`)
- Password: Contents of `./secrets/OJS_ADMIN_PASSWORD`
- Email: `admin@example.com` (configurable via `OJS_ADMIN_EMAIL`)

## Configuration

### OJS Configuration

| Environment Variable | Default | Source | Description |
| :------------------- | :------ | :----- | :---------- |
| DB_HOST | mariadb | environment | MariaDB hostname |
| DB_PORT | 3306 | environment | MariaDB port |
| DB_NAME | ojs | environment | Database name |
| DB_USER | ojs | environment | Database user |
| DB_PASSWORD | (generated) | secret | Database password (stored in `./secrets/OJS_DB_PASSWORD`) |
| OJS_SALT | (generated) | secret | Salt for password hashing (stored in `./secrets/OJS_SALT`) |
| OJS_API_KEY_SECRET | (generated) | secret | Secret for API key encoding (stored in `./secrets/OJS_API_KEY_SECRET`) |
| OJS_SECRET_KEY | (generated) | secret | Internally this is used for any encryption (specifically cookie encryption if enabled) (stored in `./secrets/OJS_SECRET_KEY`) |
| OJS_ADMIN_USERNAME | admin | environment | Initial admin username |
| OJS_ADMIN_EMAIL | admin@example.com | environment | Initial admin email |
| OJS_ADMIN_PASSWORD | (generated) | secret | Initial admin password (stored in `./secrets/OJS_ADMIN_PASSWORD`) |
| OJS_LOCALE | en | environment | Primary locale/language |
| OJS_TIMEZONE | UTC | environment | System timezone |
| OJS_FILES_DIR | /var/www/files | environment | Directory for uploaded files |
| OJS_OAI_REPOSITORY_ID | ojs.localhost | environment | OAI-PMH repository identifier |
| OJS_ENABLE_BEACON | 1 | environment | Enable PKP usage statistics beacon (1=enabled, 0=disabled) |
| OJS_SESSION_LIFETIME | 30 | environment | How long to stay logged in (in days) |
| OJS_X_FORWARDED_FOR | Off | environment | Trust X-Forwarded-For header. Enable PKP usage statistics beacon (Off, On) |
| OJS_SMTP_SERVER | host.docker.internal | environment | SMTP server for outgoing mail; defaults to the Docker host relay |
| OJS_SMTP_PORT | 25 | environment | SMTP server port |
| OJS_DEFAULT_ENVELOPE_SENDER | (empty) | environment | Optional default envelope sender for outgoing mail |

OJS sends mail through the Docker host by default. On LibOps production hosts, the host MTA forwards to the managed relay; for local testing, copy `docker-compose.override-example.yaml` to `docker-compose.override.yaml` to add Mailpit and point OJS at `mailpit:1025`.

### Nginx and PHP Settings

See https://github.com/Islandora-Devops/isle-buildkit/tree/main/nginx#nginx-settings

## Ingress

Traefik is the only published ingress for the stack. The OJS container listens only on the internal Compose network, while Traefik publishes `${HOST_INSECURE_PORT:-80}` and routes requests to OJS.

`docker-compose.yaml` is the production-shaped default. Local development changes should be copied from `docker-compose.override-example.yaml` to `docker-compose.override.yaml`; the example only exposes MariaDB for debugging and does not change the ingress path.


Set `DOMAIN` to the site hostname and `ACME_EMAIL` to the Let's Encrypt registration email before enabling the TLS override.

## Secrets Management

Secrets are stored in the `./secrets/` directory and mounted into the container at runtime. The `generate-secrets.sh` script creates secure random values for:

- `DB_ROOT_PASSWORD` - MariaDB root password
- `OJS_DB_PASSWORD` - OJS database user password
- `OJS_ADMIN_PASSWORD` - OJS admin user password
- `OJS_API_KEY_SECRET` - Secret for API key encoding/decoding
- `OJS_SALT` - Salt for password hashing

## Customization

You can customize the installation by:

1. Setting environment variables in `docker-compose.yaml`
2. Overriding default values in the Dockerfile
3. Adding custom plugins to `plugins/`

### Adding Plugins

Place plugin directories in the appropriate subdirectory under `plugins/`:

- `blocks/` - Block plugins
- `gateways/` - Gateway plugins
- `generic/` - Generic plugins
- `importexport/` - Import/export plugins
- `metadata/` - Metadata plugins
- `oaiMetadataFormats/` - OAI metadata format plugins
- `paymethod/` - Payment method plugins
- `pubIds/` - Public identifier plugins
- `reports/` - Report plugins
- `themes/` - Theme plugins

Plugins with `composer.json` files will automatically have their dependencies installed during the build.

## Volumes

The following volumes are created for data persistence:

- `mariadb-data` - MariaDB database files
- `ojs-cache` - OJS cache files
- `ojs-files` - Uploaded files (submissions, etc.)
- `ojs-public` - Public files

## Updating OJS Version

To update the OJS version, modify the `OJS_VERSION` build argument in the Dockerfile:

```dockerfile
ARG OJS_VERSION=3_5_0-3
```

Version tags follow the format used in the [PKP OJS repository](https://github.com/pkp/ojs/tags).

## Troubleshooting

### Installation Logs

If the automatic installation fails, check the container logs:

```bash
docker compose logs ojs
```

### Database Connection Issues

Ensure the MariaDB container is healthy before the OJS container starts:

```bash
docker compose ps
```

### Resetting Installation

To completely reset and reinstall:

```bash
docker compose down -v
docker compose run --rm init
docker compose up --remove-orphans -d
```

## License

This Docker implementation is provided as-is. Open Journal Systems is licensed under the GNU General Public License v3. See the [OJS repository](https://github.com/pkp/ojs) for details.
