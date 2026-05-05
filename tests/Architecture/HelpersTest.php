<?php

declare(strict_types=1);

arch('no global Laravel helpers in PHP code — use Facades instead')
    ->expect('App')
    ->not->toUse([
        'trans', 'view', 'redirect', 'app', 'config',
        'abort', 'abort_if', 'abort_unless',
        'auth', 'request', 'now', 'cache', 'session',
        'back', 'response', 'route', 'asset', 'url',
        'env', 'dispatch', 'event', 'logger',
        'optional', 'tap', 'collect', 'info', 'action',
        'old', 'csrf_token', 'csrf_field', 'method_field',
        'data_get', 'data_set',
        'public_path', 'storage_path', 'base_path',
        'app_path', 'database_path', 'resource_path', 'config_path',
    ]);
