FROM composer:2.7.7 AS builder
WORKDIR /src

COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

FROM php:8.3.8-fpm-alpine3.20
WORKDIR /var/www

ARG USER=runner
ARG GROUP=$USER

RUN addgroup -g 1000 $USER && \
    adduser -DH -g '' -G $USER -u 1000 $USER && \
    apk add --no-cache dumb-init

ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN install-php-extensions pdo_mysql

COPY --from=builder /src .
COPY . .
RUN chown -R $USER:$GROUP /var/www && \
    chmod -R 700 /var/www

RUN php artisan config:cache && \
    php artisan event:cache && \
    php artisan route:cache && \
    php artisan view:cache && \
    php artisan optimize

WORKDIR /var/www/public
EXPOSE 9000

USER $USER:$GROUP
ENTRYPOINT [ "/usr/bin/dumb-init", "--" ]
CMD [ "php-fpm" ]
