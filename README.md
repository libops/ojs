# Open Journal Systems Docker Template

The Open Journal Systems Docker Template gives you a Docker Compose repository for running [Open Journal Systems](https://pkp.sfu.ca/software/ojs/). It includes Traefik, MariaDB, and the LibOps OJS PHP/nginx image, and is designed to be managed with [`sitectl-ojs`](https://github.com/libops/sitectl-ojs).

Docs:

- [Managed application architecture](https://sitectl.libops.io/apps)
- [OJS sitectl plugin](https://sitectl.libops.io/plugins/ojs)

## Requirements

- [sitectl](https://sitectl.libops.io/install) installed on the host that will run the site.
- [`sitectl-ojs`](https://github.com/libops/sitectl-ojs) installed for OJS create, validation, healthcheck, and helper commands.
- Docker with the Compose v2 plugin installed on the same host.

## Quick start

Create a new OJS site from this template:

```bash
sitectl create ojs/default \
  --template-repo https://github.com/libops/ojs \
  --path ./my-ojs-site \
  --type local \
  --checkout-source template \
  --default-context
```

The site is served through Traefik at `http://localhost`. The first boot installs OJS automatically. The default admin account is `admin`; its password is generated in `./secrets/OJS_ADMIN_PASSWORD`.

## Local image build

The `ojs` service builds this checkout on top of the app-versioned LibOps OJS image. OJS core and its application dependencies are already present in that image; this template image only adds the plugins owned by the downstream site. Local builds use the platform selected by the Docker CLI and do not push images.

Docker Compose derives the project name from the checkout directory, so independent forks do not share containers, networks, or named volumes by default. Set `COMPOSE_PROJECT_NAME` explicitly when a stable name is required.

## Basic Operations

Run these from the generated checkout, or add `--context <name>` when operating from elsewhere.

Start or update the stack with [`sitectl compose`](https://sitectl.libops.io/commands/compose):

```bash
sitectl compose up --remove-orphans -d
```

Check the site and context configuration with [`sitectl healthcheck`](https://sitectl.libops.io/commands/healthcheck) and [`sitectl validate`](https://sitectl.libops.io/commands/validate):

```bash
sitectl healthcheck
sitectl validate
```

Update the application base tag or pin that base by digest with [`sitectl image`](https://sitectl.libops.io/commands/image):

```bash
sitectl image set --tag ojs=3.5.0-5-php84
sitectl image set --build-arg ojs.BASE_IMAGE=libops/ojs:3.5.0-5-php84@sha256:...
```

The image tag starts with the OJS release and ends with the PHP flavor. Updating that base image and rebuilding the derived site image upgrades application core without copying core into the downstream repository. Back up the database, private files, and public files before an application upgrade, then use the OJS plugin rollout so the database upgrade runs with the new core.

Publish a domain, switch HTTP/TLS mode, configure Let's Encrypt, trust upstream proxies, or tune upload limits with the `ingress` component:

```bash
sitectl set ingress enabled --mode https-custom --domain ojs.localhost
sitectl set ingress enabled --mode https-letsencrypt --domain ojs.example.org --acme-email ops@example.org
sitectl set ingress enabled --trusted-ip 203.0.113.10/32 --max-upload-size 2G --upload-timeout 10m
```

`sitectl set` applies the requested component change immediately. Use `sitectl converge` when you want an interactive review of the complete component state.

The ingress component writes `INGRESS_HOSTNAMES` as comma-separated hostnames and `INGRESS_SCHEME` as `http` or `https` into the app container. Runtime config is rendered from those values during container startup, so generated sites should not carry separate app URL env vars for the same public route.

See the [OJS sitectl plugin docs](https://sitectl.libops.io/plugins/ojs) for lifecycle operations, OJS tools, PKP tools, and recurring maintenance.

## Makefile

The Makefile is intentionally small. It only keeps template-specific targets that are not core sitectl operations:

```bash
sitectl deploy
make test
make lint
```

Use `sitectl compose ...` and `sitectl set ...` directly for normal stack operations.

## Template notes

- `traefik` is the only published ingress.
- `ojs` is a small downstream customization image based on the app-versioned LibOps OJS image.
- `mariadb` stores application data.
- Secrets are generated into `./secrets/`.
- Custom plugins can be added under `plugins/`.

`OJS_SECRET_KEY` is an application-encryption key, not an arbitrary password. Keep the generated `base64:` value backed by exactly 32 random bytes; replacing it with a different-length string prevents OJS from serving requests, and rotating it can invalidate encrypted application data.

Application core belongs to the base image. Do not copy or bind-mount the complete OJS application tree over the image.

Rebuild and redeploy the derived site image after changing a checked-in plugin. Plugin category directories are intentionally not bind-mounted over the base image because doing so would hide plugins shipped by OJS.

Only MariaDB and the one-shot `database-init` service receive `DB_ROOT_PASSWORD`. The initializer idempotently creates the database and scoped user before OJS starts; the long-running app receives only `OJS_DB_PASSWORD` as `DB_PASSWORD`.

OJS sends mail through the Docker host by default. For local SMTP testing, use the override example to add Mailpit and point OJS at `mailpit:1025`.

## License

The Docker Compose template and LibOps-specific setup in this repository are licensed under the MIT License. Open Journal Systems is licensed separately under the GNU General Public License v3; see `LICENSE.ojs`.
