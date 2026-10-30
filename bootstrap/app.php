<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

/*
 * No `web:` argument. With no web routes registered, the session and cookie
 * middleware groups are never applied to anything, so the service being
 * stateless is a structural property rather than a configured one.
 */
return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        //
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Every error from this service is JSON, including the ones raised
        // before any route matched. An HTML error page from an API is a
        // response no client can read.
        $exceptions->shouldRenderJsonWhen(fn () => true);
    })->create();
