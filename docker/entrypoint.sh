#!/bin/sh
# Everything a clean clone needs before the first request, in the one place that
# runs on every start. Putting any of this in a README instruction or a `make
# setup` would mean `docker compose up -d` is not the whole of the first run.
#
# Compose's `pre_start` lifecycle hook is the declarative answer to migration
# timing, but it needs Compose v5.3.0 and GitHub's runners ship 2.38.2, so the
# work happens here instead.
set -e
cd /app

# `composer install` only in the stages that still have Composer and a mount to
# install into; the ci and prod images baked their vendor tree at build time.
if [ -x /usr/bin/composer ] && [ ! -f vendor/autoload.php ]; then
    composer install --no-interaction --prefer-dist
fi

[ -f .env ] || cp .env.example .env
grep -q '^APP_KEY=base64:' .env || php artisan key:generate --force --no-interaction

php artisan migrate --force --no-interaction

exec frankenphp run "$@"
