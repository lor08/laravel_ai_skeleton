<?php

declare(strict_types=1);

arch('all PHP files in App use strict types')
    ->expect('App')
    ->toUseStrictTypes();

arch('all test files use strict types')
    ->expect('Tests')
    ->toUseStrictTypes();
