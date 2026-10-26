<?php

use Illuminate\Support\Facades\Route;

/*
 * Routes are registered under the /api prefix by bootstrap/app.php.
 *
 * The readiness endpoint that reports whether the datastore and cache are
 * reachable is the subject of iteration 3. It arrives with its first acceptance
 * scenario and not before, so that the specification is written red.
 *
 * Laravel's framework-level liveness route is served at /up and is what the
 * container healthcheck polls: it returns 200 only if the framework booted.
 */

Route::get('/', fn () => response()->json([
    'service' => config('app.name'),
]));
