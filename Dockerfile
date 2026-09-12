ARG BASE_IMAGE=libops/ojs:3.5.0-5-php84@sha256:3c847db71be8b9c815af746e1b102e1d23af499d69d6c188b0fb38c8151ce317
FROM ${BASE_IMAGE}

WORKDIR /var/www/ojs

# nginx:nginx in the base image.
COPY --link --chown=100:101 plugins/ /var/www/ojs/plugins/
