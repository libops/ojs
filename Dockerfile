ARG BASE_IMAGE=libops/ojs:3.5.0-5-php84@sha256:f70fc962d341bb28ea8213b9c0872bc307d26ddff4f2bff5dc86737922c77bb5
FROM ${BASE_IMAGE}

WORKDIR /var/www/ojs

# nginx:nginx in the base image.
COPY --link --chown=100:101 plugins/ /var/www/ojs/plugins/
