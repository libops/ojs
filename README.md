# Open Journal Systems Docker Template

LibOps Docker Compose template for running [Open Journal Systems](https://pkp.sfu.ca/software/ojs/) with Traefik, MariaDB, and the LibOps OJS PHP/nginx image. Use it with [`sitectl-ojs`](https://github.com/libops/sitectl-ojs).

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

The `ojs` service builds this checkout on top of the LibOps OJS base image. The Dockerfile downloads the pinned OJS release before copying local plugins so Docker can reuse dependency layers when only site customizations change. Local builds use the platform selected by the Docker CLI and do not push images.

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

Update image tags or pin a full image reference with [`sitectl image`](https://sitectl.libops.io/commands/image):

```bash
sitectl image set --tag ojs=nginx-1.30.3-php84
sitectl image set --image ojs=libops/ojs:nginx-1.30.3-php84@sha256:...
```

Enable local development bind mounts with [`sitectl set`](https://sitectl.libops.io/commands/set), then apply the component change with [`sitectl converge`](https://sitectl.libops.io/commands/converge):

```bash
sitectl set dev-mode enabled
sitectl converge
```

Switch TLS modes with the [Traefik service commands](https://sitectl.libops.io/plugins/traefik):

```bash
sitectl traefik tls mkcert --domain ojs.localhost
sitectl traefik tls letsencrypt --email ops@example.org
```

Trust an upstream load balancer or reverse proxy with [`sitectl set`](https://sitectl.libops.io/commands/set), then apply it with [`sitectl converge`](https://sitectl.libops.io/commands/converge):

```bash
sitectl set reverse-proxy enabled --trusted-ip 203.0.113.10/32
sitectl converge
```

Raise upload limits with [`sitectl set`](https://sitectl.libops.io/commands/set), then apply them with [`sitectl converge`](https://sitectl.libops.io/commands/converge):

```bash
sitectl set upload-limits enabled --max-upload-size 2G --upload-timeout 10m
sitectl converge
```

See the [OJS sitectl plugin docs](https://sitectl.libops.io/plugins/ojs) for lifecycle operations, OJS tools, PKP tools, and recurring maintenance.

## Makefile

The Makefile is intentionally small. It only keeps template-specific targets that are not core sitectl operations:

```bash
make rollout
make test
make lint
```

Use `sitectl compose ...`, `sitectl traefik ...`, and `sitectl set ...` directly for normal stack operations.

## Template notes

- `traefik` is the only published ingress.
- `ojs` is built from this repository and based on the LibOps OJS PHP/nginx image.
- `mariadb` stores application data.
- Secrets are generated into `./secrets/`.
- Custom plugins can be added under `plugins/`.

OJS sends mail through the Docker host by default. For local SMTP testing, use the override example to add Mailpit and point OJS at `mailpit:1025`.

## License

The Docker Compose template and LibOps-specific setup in this repository are licensed under the MIT License. Open Journal Systems is licensed separately under the GNU General Public License v3; see `LICENSE.ojs`.
