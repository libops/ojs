ARG BASE_IMAGE=libops/ojs:nginx-1.30.3-php84
FROM ${BASE_IMAGE}

ARG TARGETARCH

ARG \
    # renovate: datasource=custom.ojs depName=ojs
    SOFTWARE_VERSION=3.5.0-3
ARG FILE=ojs-${SOFTWARE_VERSION}.tar.gz
ARG URL=https://pkp.sfu.ca/ojs/download/${FILE}
ARG SHA256="af501e4f8d99af84d47c26eca3347400d94b3ace08806b5e30a7b6d0ce91e3e5"

WORKDIR /var/www/ojs

RUN --mount=type=cache,id=custom-ojs-downloads-${TARGETARCH},sharing=locked,target=/opt/downloads \
    download.sh \
        --url "${URL}" \
        --sha256 "${SHA256}" \
        --strip \
        --dest "/var/www/ojs" \
    && \
    sed -i \
        -e '/<code function="downloadIPGeoDB"\/>/d' \
        -e '/<code function="updateRorRegistryDataset"\/>/d' \
        dbscripts/xml/install.xml && \
    rm -rf .github tests docs && \
    mkdir -p /var/www/files /var/www/ojs/cache /var/www/ojs/public && \
    touch /var/www/ojs/opcache_stat.php && \
    cleanup.sh

COPY --link plugins/ /var/www/ojs/plugins/

ENV \
    DB_HOST=mariadb \
    DB_PORT=3306 \
    DB_NAME=ojs \
    DB_USER=ojs \
    DB_PASSWORD=changeme \
    OJS_SALT=changeme \
    OJS_API_KEY_SECRET=changeme \
    OJS_SECRET_KEY=changeme \
    OJS_BASE_URL=http://localhost \
    OJS_ADMIN_USERNAME=admin \
    OJS_ADMIN_EMAIL=admin@localhost \
    OJS_ADMIN_PASSWORD=changeme \
    OJS_LOCALE=en \
    OJS_TIMEZONE=UTC \
    OJS_FILES_DIR=/var/www/files \
    OJS_OAI_REPOSITORY_ID=ojs.localhost \
    OJS_ENABLE_BEACON=1 \
    OJS_SESSION_LIFETIME=30 \
    OJS_X_FORWARDED_FOR=Off \
    OJS_SMTP_SERVER=host.docker.internal \
    OJS_SMTP_PORT=25 \
    OJS_DEFAULT_ENVELOPE_SENDER= \
    OJS_ENABLE_HTTPS=false

RUN chown -R nginx:nginx /var/www/ojs /var/www/files && \
    cleanup.sh
