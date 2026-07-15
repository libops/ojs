ARG BASE_IMAGE=libops/ojs:3.5.0-5-php84@sha256:b97670708fdec9cc63b7c5ba9c96b3db547f3ea3e1658ef01bdeba6400aec090
FROM ${BASE_IMAGE}

WORKDIR /var/www/ojs

# nginx:nginx in the base image.
COPY --link --chown=100:101 plugins/ /var/www/ojs/plugins/
