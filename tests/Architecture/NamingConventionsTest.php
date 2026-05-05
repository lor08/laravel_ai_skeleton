<?php

declare(strict_types=1);

arch('controllers have Controller suffix and are final')
    ->expect('App\Http\Controllers')
    ->toBeFinal()
    ->toHaveSuffix('Controller')
    ->ignoring(['App\Http\Controllers\Controller']);

arch('form requests have Request suffix and extend FormRequest')
    ->expect('App\Http\Requests')
    ->toHaveSuffix('Request')
    ->toExtend('Illuminate\Foundation\Http\FormRequest');

arch('services have Service suffix')
    ->expect('App\Services')
    ->toHaveSuffix('Service');

arch('repositories have Repository suffix')
    ->expect('App\Repositories')
    ->toHaveSuffix('Repository');

arch('jobs have Job suffix and implement ShouldQueue')
    ->expect('App\Jobs')
    ->toHaveSuffix('Job')
    ->toImplement('Illuminate\Contracts\Queue\ShouldQueue');

arch('events have Event suffix')
    ->expect('App\Events')
    ->toHaveSuffix('Event');

arch('listeners have Listener suffix')
    ->expect('App\Listeners')
    ->toHaveSuffix('Listener');

arch('exceptions have Exception suffix')
    ->expect('App\Exceptions')
    ->toHaveSuffix('Exception')
    ->ignoring(['App\Exceptions\Handler']);

arch('enums are real PHP enums')
    ->expect('App\Enums')
    ->toBeEnums();
