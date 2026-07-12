ARG BASE_IMAGE=libops/ojs:3.5.0-5-php84@sha256:778ea1281c5eb2aeb841cdd135049e3ecdc9743979e073ffdf71f0e1c264a438
FROM ${BASE_IMAGE}

WORKDIR /var/www/ojs

# nginx:nginx in the base image.
COPY --link --chown=100:101 plugins/ /var/www/ojs/plugins/
