FROM cbsan/php:5.6

RUN set -xe \
    && ext_dep="curl" \
    && apt-get update && apt-get install -y  \
        $ext_dep \
    --no-install-recommends --no-install-suggests \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fSL https://getcomposer.org/composer.phar -o /usr/local/bin/composer \
    && chmod a+x /usr/local/bin/composer \
    && composer \
    && rm -rf /usr/local/etc/php-fpm.d/zz-docker.conf

ENV PATH "$PATH:/root/.composer/vendor/bin"

WORKDIR /var/www
