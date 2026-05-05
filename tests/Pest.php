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
| Globally ignored namespaces for arch tests. These are typically Laravel
| internals or test infrastructure that we don't want to assert against.
|
*/
arch()->preset()->laravel();
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

/*
|--------------------------------------------------------------------------
| Functions
|--------------------------------------------------------------------------
*/
function something(): mixed
{
    // Add helpers used across multiple tests here.
    return null;
}
