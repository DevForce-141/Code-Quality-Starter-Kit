<?php

arch('actions are invokable')
    ->expect('App\Actions')
    ->toBeInvokable();

arch('models do not contain business logic')
    ->expect('App\Models')
    ->not->toHavePublicMethodsBesides([
        'relationships', 'scopes', 'casts', 'fillable',
        'boot', 'booted', 'newCollection',
    ]);

arch('controllers do not query the database directly')
    ->expect('App\Http\Controllers')
    ->not->toUse(['Illuminate\Support\Facades\DB']);

arch('enums are properly placed')
    ->expect('App\Enums')
    ->toBeEnum();

arch('no debug functions in codebase')
    ->expect('App')
    ->not->toUse(['dd', 'dump', 'ray', 'var_dump', 'print_r']);

arch('form requests extend the base class')
    ->expect('App\Http\Requests')
    ->toExtend('Illuminate\Foundation\Http\FormRequest');
