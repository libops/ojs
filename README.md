# Open Journal Systems (OJS) Docker Container

Dockerized deployment of [Open Journal Systems](https://pkp.sfu.ca/software/ojs/) based on the [Islandora Buildkit](https://github.com/Islandora-Devops/isle-buildkit) nginx base image.

## Quick Start

1. Generate secrets:
```bash
docker compose up init
```

2. Start the containers:
```bash
docker compose up -d
```

3. Access OJS at http://localhost

The installation will run automatically on first startup. The default admin credentials are:
- Username: `admin` (configurable via `OJS_ADMIN_USERNAME`)
- Password: Contents of `./secrets/OJS_ADMIN_PASSWORD`
- Email: `admin@example.com` (configurable via `OJS_ADMIN_EMAIL`)

## Configuration

### OJS Configuration

| Environment Variable | Default | Source | Description |
| :------------------- | :------ | :----- | :---------- |
| DB_HOST | mariadb | environment | MariaDB/MySQL hostname |
| DB_PORT | 3306 | environment | MariaDB/MySQL port |
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

### Nginx and PHP Settings

See https://github.com/Islandora-Devops/isle-buildkit/tree/main/nginx#nginx-settings

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
3. Adding custom plugins to `rootfs/var/www/ojs/plugins/`

### Adding Plugins

Place plugin directories in the appropriate subdirectory under `rootfs/var/www/ojs/plugins/`:

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
ARG OJS_VERSION=3_5_0-1
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
./scripts/generate-secrets.sh
docker compose up -d
```

## License

This Docker implementation is provided as-is. Open Journal Systems is licensed under the GNU General Public License v3. See the [OJS repository](https://github.com/pkp/ojs) for details.
