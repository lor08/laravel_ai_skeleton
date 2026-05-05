<?php

declare(strict_types=1);

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(TestCase::class)->in('Feature', 'Unit');

uses(RefreshDatabase::class)->in('Feature');

/*
|--------------------------------------------------------------------------
| Architecture configuration
|--------------------------------------------------------------------------
|
| Built-in arch presets:
|   - php()      — bans dd/die/var_dump/print_r/eval/exit etc.
|   - security() — bans unsafe functions (eval, exec, shell_exec, ...).
|   - laravel()  — opinionated Laravel-conventions; OFF by default because
|                  it can overlap with our own tests in tests/Architecture/
|                  (LayerBoundariesTest, NamingConventionsTest).
|                  Re-enable explicitly with arch()->preset()->laravel(); if needed.
|
*/
arch()->preset()->php();
arch()->preset()->security();

/*
|--------------------------------------------------------------------------
| Custom expectations
|--------------------------------------------------------------------------
*/
expect()->extend('toBeMoney', function () {
    return $this->toBeInt()->toBeGreaterThanOrEqual(0);
});
