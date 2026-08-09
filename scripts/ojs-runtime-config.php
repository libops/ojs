<?php

declare(strict_types=1);

$config = parse_ini_file('/var/www/ojs/config.inc.php', true);

echo json_encode([
    'installed' => $config['general']['installed'] ?? null,
    'base_url' => $config['general']['base_url'] ?? null,
    'files_dir' => $config['files']['files_dir'] ?? null,
    'public_files_dir' => $config['files']['public_files_dir'] ?? null,
    'repository_id' => $config['oai']['repository_id'] ?? null,
    'task_runner' => $config['schedule']['task_runner'] ?? null,
    'smtp' => $config['email']['smtp'] ?? null,
    'smtp_server' => $config['email']['smtp_server'] ?? null,
    'smtp_port' => $config['email']['smtp_port'] ?? null,
], JSON_THROW_ON_ERROR);
