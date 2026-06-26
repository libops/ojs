#!/command/with-contenv bash
# shellcheck shell=bash

set -eou pipefail

function mysql_create_database {
    cat <<-EOF | create-database.sh
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8 COLLATE utf8_general_ci;

CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* to '${DB_USER}'@'%';
FLUSH PRIVILEGES;

SET PASSWORD FOR ${DB_USER}@'%' = PASSWORD('${DB_PASSWORD}');
EOF
}

function set_ojs_installed {
    sed -i 's/^installed = .*/installed = On/' /var/www/ojs/config.inc.php
    chmod 440 /var/www/ojs/config.inc.php
    touch /installed
}

function fix_ojs_writable_permissions {
    local dir=
    for dir in /var/www/files /var/www/ojs/cache /var/www/ojs/public; do
        mkdir -p "${dir}"
        chown -R nginx:nginx "${dir}"
        find "${dir}" -type d -exec chmod 750 {} +
        find "${dir}" -type f -exec chmod 640 {} +
    done
}

function render_ojs_config {
    /etc/s6-overlay/scripts/confd-oneshot.sh
}

function check_ojs_installed {
    mysql -h"${DB_HOST}" -u"${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" \
        -e "SELECT 1 FROM versions WHERE current = 1 AND product_type = 'core' AND product = 'ojs2' LIMIT 1" &>/dev/null
    return $?
}

function install_ojs {
    echo "OJS not installed. Running installation..."

    local enable_beacon=n
    case "${OJS_ENABLE_BEACON}" in
        1|[Oo][Nn]|[Tt][Rr][Uu][Ee]|[Yy]*)
            enable_beacon=y
            ;;
    esac

    echo "Running OJS CLI installer..."
    {
        printf '%s\n' "${OJS_LOCALE}"
        printf '\n'
        printf '%s\n' "${OJS_FILES_DIR}"
        printf '%s\n' "${OJS_ADMIN_USERNAME}"
        printf '%s\n' "${OJS_ADMIN_PASSWORD}"
        printf '%s\n' "${OJS_ADMIN_PASSWORD}"
        printf '%s\n' "${OJS_ADMIN_EMAIL}"
        printf 'mysqli\n'
        printf '%s\n' "${DB_HOST}"
        printf '%s\n' "${DB_USER}"
        printf '%s\n' "${DB_PASSWORD}"
        printf '%s\n' "${DB_NAME}"
        printf '%s\n' "${OJS_OAI_REPOSITORY_ID}"
        printf '%s\n' "${enable_beacon}"
        printf 'y\n'
    } | php /var/www/ojs/tools/install.php > /tmp/ojs-install.log 2>&1 && install_success=true || install_success=

    if [ -n "${install_success}" ] && grep -q "Successfully installed version" /tmp/ojs-install.log && check_ojs_installed; then
        echo "=========================================="
        echo "OJS Installation Complete!"
        echo "=========================================="
        rm /tmp/ojs-install.log
        render_ojs_config
        set_ojs_installed
        fix_ojs_writable_permissions
    else
        echo "=========================================="
        echo "OJS Installation Failed!"
        echo "=========================================="
        cat /tmp/ojs-install.log
        echo "=========================================="
        exit 1
    fi
}

function main {
    if [ ! -f /var/www/ojs/index.php ]; then
        echo "OJS application files are not present. Skipping OJS setup."
        return 0
    fi

    # wait for nginx
    if ! timeout 300 wait-for-open-port.sh localhost 80; then
        echo "Could not connect to nginx at localhost:80"
        exit 1
    fi
    if [ "${DB_HOST}" = "mariadb" ]; then
        mysql_create_database
        if check_ojs_installed; then
            echo "OJS already installed. Skipping installation."
            set_ojs_installed
            fix_ojs_writable_permissions
            exit 0
        fi
        install_ojs
    fi

    set_ojs_installed
    fix_ojs_writable_permissions
}
main
