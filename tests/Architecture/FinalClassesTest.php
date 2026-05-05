<?php

declare(strict_types=1);

arch('domain classes are final')
    ->expect('App')
    ->classes
    ->toBeFinal()
    ->ignoring([
        'App\Http\Controllers\Controller',
        'App\Models',
        'App\Exceptions\Handler',
    ]);

arch('DTOs are final and readonly')
    ->expect('App\DTO')
    ->classes
    ->toBeFinal()
    ->classes
    ->toBeReadonly();
