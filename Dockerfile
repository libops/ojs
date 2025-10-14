FROM islandora/nginx:6.0.1@sha256:20d8b36e812c60bfabccdbfbee0f40d46733df921a4ea9de0a2fa943f88f4fb5

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

EXPOSE 80

WORKDIR /var/www/ojs

ARG \
    # renovate: datasource=repology depName=alpine_3_22/antiword
    ANTIWORD_VERSION=0.37-r6 \
    # renovate: datasource=repology depName=alpine_3_22/ghostscript
    GHOSTSCRIPT_VERSION=10.05.1-r0 \
    # renovate: datasource=repology depName=alpine_3_22/npm
    NPM_VERSION=11.3.0-r1 \
    # renovate: datasource=github-tags depName=ojs packageName=pkp/ojs
    OJS_VERSION=3_5_0-1 \
    # renovate: datasource=repology depName=alpine_3_22/php83
    PHP_VERSION=8.3.26-r0 \
    # renovate: datasource=repology depName=alpine_3_22/poppler-utils
    POPPLER_VERSION=25.04.0-r0

RUN apk add --no-cache \
    antiword=="${ANTIWORD_VERSION}" \
    ghostscript=="${GHOSTSCRIPT_VERSION}" \
    npm=="${NPM_VERSION}" \
    php83-bcmath=="${PHP_VERSION}" \
    php83-ftp=="${PHP_VERSION}" \
    php83-gettext=="${PHP_VERSION}" \
    poppler-utils=="${POPPLER_VERSION}" \
    && cleanup.sh

RUN git clone https://github.com/pkp/ojs.git . \
    && git checkout "${OJS_VERSION}" \
    && git submodule update --init --recursive \
    && rm -rf .github tests docs \
    && composer -d lib/pkp install \
    && composer -d plugins/generic/citationStyleLanguage install \
    && composer -d plugins/paymethod/paypal install \
    && rm -rf .git \
    # modify composer.json to be at least a week old so we can run composer install for contrib plugins
    && NOW=$(date +%s) \
    && SEVEN_DAYS_AGO=$((NOW - 604800)) \
    && OLDDATE=$(date -d @"${SEVEN_DAYS_AGO}" +%Y%m%d%H%M.%S) \
    && find /var/www/ojs/plugins -type f -name "composer.json" -exec touch -t "$OLDDATE" {} \;

RUN npm install \
    && npm run build \
    && rm -rf node_modules

RUN chown -R nginx:nginx /var/www/ojs

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
    # see https://github.com/Islandora-Devops/isle-buildkit/tree/main/nginx#nginx-settings
    PHP_MAX_EXECUTION_TIME=300 \
    PHP_MAX_INPUT_TIME=300 \
    PHP_DEFAULT_SOCKET_TIMEOUT=300 \
    PHP_REQUEST_TERMINATE_TIMEOUT=300 \
    PHP_MEMORY_LIMIT=256M \
    NGINX_FASTCGI_READ_TIMEOUT=300s \
    NGINX_FASTCGI_SEND_TIMEOUT=300s \
    NGINX_FASTCGI_CONNECT_TIMEOUT=300s

COPY --link rootfs /

# run composer install on any plugins added from ./rootfs/var/www/ojs/plugins (files modified within last day)
RUN find /var/www/ojs/plugins -type f -name "composer.json" -mtime -1 | while read -r COMPOSER_JSON; do \
    composer install --no-dev --optimize-autoloader -d "$(dirname "$COMPOSER_JSON")"; \
    done
