<?php

declare(strict_types=1);

arch('controllers do not query the database directly')
    ->expect('App\Http\Controllers')
    ->not->toUse([
        'Illuminate\Support\Facades\DB',
        'Illuminate\Database\Eloquent\Builder',
        'Illuminate\Database\Query\Builder',
    ]);

arch('repositories never know about HTTP')
    ->expect('App\Repositories')
    ->not->toUse([
        'Illuminate\Http\Request',
        'Illuminate\Http\Response',
        'Illuminate\Foundation\Http\FormRequest',
        'Illuminate\Http\JsonResponse',
    ]);

arch('services use repositories, not Eloquent directly')
    ->expect('App\Services')
    ->not->toUse([
        'Illuminate\Database\Eloquent\Builder',
    ]);

arch('DTOs have no infrastructure dependencies')
    ->expect('App\DTO')
    ->not->toUse([
        'Illuminate\Support\Facades',
        'App\Services',
        'App\Repositories',
        'App\Jobs',
    ]);
