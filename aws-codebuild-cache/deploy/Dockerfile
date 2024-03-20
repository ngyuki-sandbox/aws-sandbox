# syntax=docker/dockerfile:1

FROM public.ecr.aws/docker/library/php:8.3-fpm-alpine AS build

RUN --mount=type=cache,target=/tmp \
    apk add --no-cache --virtual .build-deps autoconf gcc g++ make &&\
    pecl -v install apcu &&\
    docker-php-ext-install pcntl &&\
    apk del .build-deps

RUN apk add --no-cache tzdata

###

FROM public.ecr.aws/docker/library/php:8.3-fpm-alpine as main

RUN apk add --no-cache aws-cli dumb-init jq

COPY --from=build /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

RUN docker-php-ext-enable apcu opcache pcntl

COPY --from=public.ecr.aws/docker/library/composer:lts /usr/bin/composer /usr/bin/composer

COPY composer.json composer.lock /app/
WORKDIR /app/
RUN composer install --prefer-dist --no-dev --no-suggest --no-progress \
        --optimize-autoloader --classmap-authoritative --ignore-platform-reqs &&\
    composer clear-cache

COPY --from=build /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

COPY ./ /app/

ARG COMMIT_HASH
ARG BUILD_DATE
ENV COMMIT_HASH=$COMMIT_HASH \
    BUILD_DATE=$BUILD_DATE

FROM main as dev

COPY composer.json composer.lock /app2/
WORKDIR /app2/
RUN composer install --prefer-dist --no-dev --no-suggest --no-progress \
        --optimize-autoloader --classmap-authoritative --ignore-platform-reqs &&\
    composer clear-cache

COPY ./ /app2/
