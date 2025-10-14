#!/command/with-contenv bash
# shellcheck shell=bash

set -eou pipefail

function mysql_create_database {
    cat <<-EOF | create-database.sh
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8 COLLATE utf8_general_ci;

CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* to '${DB_USER}'@'%';
FLUSH PRIVILEGES;

SET PASSWORD FOR ${DB_USER}@'%' = PASSWORD('${DB_PASSWORD}')
EOF
}

function check_ojs_installed {
    # Check if OJS database tables exist
    # Query the database for one of the core OJS tables (journals table)
    mysql -h"${DB_HOST}" -u"${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" \
        -e "SELECT 1 FROM journals LIMIT 1" &>/dev/null
    return $?
}

function install_ojs {
    echo "OJS not installed. Running installation..."

    # Build form data for installation POST request
    local form_data="installing=0"
    form_data="${form_data}&locale=${OJS_LOCALE}"
    form_data="${form_data}&timeZone=${OJS_TIMEZONE}"
    form_data="${form_data}&filesDir=${OJS_FILES_DIR}"
    form_data="${form_data}&databaseDriver=mysqli"
    form_data="${form_data}&databaseHost=${DB_HOST}"
    form_data="${form_data}&databaseUsername=${DB_USER}"
    form_data="${form_data}&databasePassword=${DB_PASSWORD}"
    form_data="${form_data}&databaseName=${DB_NAME}"
    form_data="${form_data}&oaiRepositoryId=${OJS_OAI_REPOSITORY_ID}"
    form_data="${form_data}&enableBeacon=${OJS_ENABLE_BEACON}"
    form_data="${form_data}&adminUsername=${OJS_ADMIN_USERNAME}"
    form_data="${form_data}&adminPassword=${OJS_ADMIN_PASSWORD}"
    form_data="${form_data}&adminPassword2=${OJS_ADMIN_PASSWORD}"
    form_data="${form_data}&adminEmail=${OJS_ADMIN_EMAIL}"

    # POST to the installation endpoint with increased timeout
    echo "Posting installation request..."
    curl -d "${form_data}" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        http://localhost/index/en/install/install > /tmp/ojs-install.log 2>&1 && install_success=true || install_success=

    if [ -n "${install_success}" ]; then
        echo "=========================================="
        echo "OJS Installation Complete!"
        echo "=========================================="
        rm /tmp/ojs-install.log
    else
        echo "=========================================="
        echo "OJS Installation Failed!"
        echo "=========================================="
        cat /tmp/ojs-install.log
        echo "=========================================="
    fi
    sed -i 's/installed = Off/installed = On/' /var/www/ojs/config.inc.php
    chmod 440 /var/www/ojs/config.inc.php
}

function main {
    mysql_create_database

    # wait for nginx
    if ! timeout 300 wait-for-open-port.sh localhost 80; then
      echo "Could not connect to nginx at localhost:80"
      exit 1
    fi

    if ! check_ojs_installed; then
        install_ojs &
        echo "OJS installation started."
    else
        echo "OJS is already installed. Skipping installation."
    fi
}
main
