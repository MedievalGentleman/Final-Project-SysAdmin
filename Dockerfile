FROM composer:2.7.7 AS builder
WORKDIR /src

COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

COPY . .

FROM php:8.3.8-fpm-alpine3.20
WORKDIR /app

ARG USER=runner
ARG GROUP=$USER

RUN addgroup -g 1000 $USER && \
    adduser -DH -g '' -G $USER -u 1000 $USER && \
    apk add --no-cache dumb-init

RUN docker-php-ext-configure mysqli && \
    docker-php-ext-install mysqli pdo_mysql

COPY --from=builder /src /app
RUN chown -R $USER:$GROUP /app && \
    chmod -R 700 /app

RUN php artisan config:cache && \
    php artisan event:cache && \
    php artisan route:cache && \
    php artisan view:cache && \
    php artisan optimize

EXPOSE ${PORT}

USER $USER:$GROUP
ENTRYPOINT [ "/usr/bin/dumb-init", "--" ]
CMD [ "php", "artisan", "serve", "--host", "0.0.0.0", "--port", "8080" ]
