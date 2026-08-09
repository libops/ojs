<?php

declare(strict_types=1);

$config = parse_ini_file('/var/www/ojs/config.inc.php', true, INI_SCANNER_RAW);
$database = $config['database'] ?? null;

if (!is_array($database)) {
    fwrite(STDERR, "config.inc.php omitted [database]\n");
    exit(2);
}

foreach (['host', 'port', 'username', 'password', 'name'] as $key) {
    $value = $database[$key] ?? '';
    if (!is_string($value) || $value === '') {
        fwrite(STDERR, "config.inc.php database.$key is empty\n");
        exit(2);
    }
    fwrite(STDOUT, $value . "\0");
}
