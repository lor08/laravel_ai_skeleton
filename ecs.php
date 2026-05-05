<?php

declare(strict_types=1);

use PhpCsFixer\Fixer\ClassNotation\OrderedClassElementsFixer;
use PhpCsFixer\Fixer\Import\OrderedImportsFixer;
use PhpCsFixer\Fixer\PhpUnit\PhpUnitTestClassRequiresCoversFixer;
use PhpCsFixer\Fixer\Phpdoc\PhpdocLineSpanFixer;
use PhpCsFixer\Fixer\Phpdoc\PhpdocOrderFixer;
use PhpCsFixer\Fixer\Strict\DeclareStrictTypesFixer;
use Symplify\EasyCodingStandard\Config\ECSConfig;

return ECSConfig::configure()
    ->withPaths([
        __DIR__ . '/app',
        __DIR__ . '/config',
        __DIR__ . '/database',
        __DIR__ . '/routes',
        __DIR__ . '/tests',
        __DIR__ . '/bootstrap/app.php',
    ])
    ->withSkip([
        __DIR__ . '/bootstrap/cache',
        __DIR__ . '/storage',
        __DIR__ . '/vendor',
        __DIR__ . '/node_modules',
        __DIR__ . '/public/build',
    ])
    ->withPreparedSets(
        psr12: true,
        common: true,
        symplify: true,
        cleanCode: true,
    )
    ->withRules([
        DeclareStrictTypesFixer::class,
    ])
    ->withConfiguredRule(OrderedClassElementsFixer::class, [
        'order' => [
            'use_trait',
            'case',
            'constant_public',
            'constant_protected',
            'constant_private',
            'property_public',
            'property_protected',
            'property_private',
            'construct',
            'destruct',
            'magic',
            'phpunit',
            'method_public_static',
            'method_protected_static',
            'method_private_static',
            'method_public',
            'method_protected',
            'method_private',
        ],
    ])
    ->withConfiguredRule(OrderedImportsFixer::class, [
        'sort_algorithm' => 'alpha',
        'imports_order'  => ['class', 'function', 'const'],
    ])
    ->withConfiguredRule(PhpdocLineSpanFixer::class, [
        'property' => 'single',
        'method'   => 'multi',
    ])
    ->withSkip([
        // Allow plain PSR-12 in migrations (return new class extends Migration { ... })
        PhpUnitTestClassRequiresCoversFixer::class,
        PhpdocOrderFixer::class => null,
    ]);
