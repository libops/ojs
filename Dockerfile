ARG BASE_IMAGE=libops/ojs:3.5.0-5-php84@sha256:5a18ac6b8df5b3fb67fdf51744a74dd6658aef5250012a22ffdd8da53c08eb1d
FROM ${BASE_IMAGE}

WORKDIR /var/www/ojs

# nginx:nginx in the base image.
COPY --link --chown=100:101 plugins/ /var/www/ojs/plugins/
