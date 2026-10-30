# syntax=docker/dockerfile:1

# Four stages, so that the image CI tests is the image the release publishes.
#
#   base -> dev   local development, Xdebug
#        -> ci    the gate: PCOV for coverage, dev dependencies present
#        -> prod  the published artifact: no Composer, no coverage driver, no dev deps
#
# Pinned to an exact patch of both FrankenPHP and PHP. A floating tag would make
# "a clean clone builds" true today and unprovable in a month, which is the one
# claim this repository cannot afford to get wrong.

# ---------------------------------------------------------------- base --------
FROM dunglas/frankenphp:1.13.3-php8.5.12-trixie AS base

# install-php-extensions ships with the FrankenPHP image.
RUN install-php-extensions pdo_mysql redis zip opcache intl

WORKDIR /app

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_NO_INTERACTION=1 \
    COMPOSER_HOME=/composer \
    SERVER_NAME=:8080

COPY --from=composer/composer:2-bin /composer /usr/bin/composer
COPY docker/entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

# FrankenPHP's image already contains www-data (uid 33). The app runs as it in
# every stage: a container that need not be root should not be able to become it.
# www-data's home is /var/www and it is not writable, so Composer would warn
# and run cacheless on every invocation. Give it somewhere to live instead.
RUN mkdir -p /data/caddy /config/caddy /composer \
 && chown -R www-data:www-data /app /data /config /composer

EXPOSE 8080
ENTRYPOINT ["entrypoint"]
CMD ["--config", "/etc/frankenphp/Caddyfile"]

# ----------------------------------------------------------------- dev --------
FROM base AS dev

RUN install-php-extensions xdebug

ENV APP_ENV=local \
    XDEBUG_MODE=off

# compose bind-mounts the working tree over /app, and a bind mount keeps the
# host's ownership. The container user must therefore share the host user's
# uid, or `composer install` cannot write vendor/ into the mount.
#
# 1000:1000 is the first non-system user on Linux and is what Docker Desktop
# presents on macOS, so the default is right almost everywhere. Override with
# UID/GID build args if your host disagrees -- `id -u` will tell you.
ARG UID=1000
ARG GID=1000
RUN usermod  --uid "$UID" www-data \
 && groupmod --gid "$GID" www-data \
 && chown -R www-data:www-data /data /config /composer

# Nothing is COPYed here: the mount is the source. Dependencies are installed
# by the entrypoint, which is the first thing that can see the mount.
USER www-data

# ------------------------------------------------------------------ ci --------
FROM base AS ci

RUN install-php-extensions pcov

ENV APP_ENV=testing

COPY --chown=www-data:www-data composer.json composer.lock ./
RUN composer install --no-scripts --no-autoloader --prefer-dist

COPY --chown=www-data:www-data . .
RUN composer dump-autoload --optimize

USER www-data

# ---------------------------------------------------------------- prod --------
FROM base AS prod

ENV APP_ENV=production \
    APP_DEBUG=false

COPY --chown=www-data:www-data composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

COPY --chown=www-data:www-data . .
RUN composer dump-autoload --optimize --no-dev \
 && rm -f /usr/bin/composer

USER www-data
