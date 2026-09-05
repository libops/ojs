ARG BASE_IMAGE=libops/ojs:3.5.0-5-php84@sha256:b2081601a6601438277041390eca0b6ce7bae87f87621f77bbd924a20e0c8ed0
FROM ${BASE_IMAGE}

WORKDIR /var/www/ojs

# nginx:nginx in the base image.
COPY --link --chown=100:101 plugins/ /var/www/ojs/plugins/
