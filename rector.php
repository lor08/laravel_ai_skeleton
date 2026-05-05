<?php

declare(strict_types=1);

/**
 * Rector configuration — OPTIONAL.
 *
 * To enable:
 *   composer require --dev rector/rector driftingly/rector-laravel
 *
 * Then:
 *   composer fix:rector
 *
 * Rector applies automated refactorings, including:
 *   - PHP 8.5 idioms (pipe operator, property hooks, asymmetric visibility)
 *   - Laravel-specific upgrades (request->validated, route binding, etc.)
 *   - Dead code removal
 *   - Type declarations from PHPDoc
 *   - Code quality (early returns, simpler conditionals — partial overlap with refactoring.guru)
 */

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use RectorLaravel\Set\LaravelLevelSetList;
use RectorLaravel\Set\LaravelSetList;

return RectorConfig::configure()
    ->withPaths([
        __DIR__ . '/app',
        __DIR__ . '/config',
        __DIR__ . '/database',
        __DIR__ . '/routes',
        __DIR__ . '/tests',
    ])
    ->withSkip([
        __DIR__ . '/bootstrap/cache',
        __DIR__ . '/storage',
        __DIR__ . '/vendor',
        __DIR__ . '/public/build',
    ])
    ->withPhpSets()
    ->withPreparedSets(
        deadCode: true,
        codeQuality: true,
        codingStyle: true,
        typeDeclarations: true,
        privatization: true,
        earlyReturn: true,
        instanceOf: true,
        strictBooleans: true,
    )
    ->withSets([
        LevelSetList::UP_TO_PHP_85,
        LaravelSetList::LARAVEL_130,
        LaravelLevelSetList::UP_TO_LARAVEL_130,
    ])
    ->withImportNames(removeUnusedImports: true)
    ->withParallel();
