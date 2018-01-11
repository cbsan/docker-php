FROM cbsan/php:5.6

RUN set -xe \
    && ext_dep="curl \
                git \
                ssh \
                mercurial" \
    && apt-get update && apt-get install -y  \
        $ext_dep \
    --no-install-recommends --no-install-suggests \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fSL https://getcomposer.org/composer.phar -o /usr/local/bin/composer \
    && curl -fSL https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar -o /usr/local/bin/phpcs \
    && curl -fSL https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar -o /usr/local/bin/phpcbf \
    && curl -fSL https://github.com/FriendsOfPHP/PHP-CS-Fixer/releases/download/v2.0.0/php-cs-fixer.phar -o /usr/local/bin/php-cs-fixer \
    && chmod a+x /usr/local/bin/* \
    && rm -rf /usr/local/etc/php-fpm.d/zz-docker.conf

ENV PATH "$PATH:/root/.composer/vendor/bin"

RUN /usr/local/bin/composer self-update && echo "{}" > ~/.composer/composer.json

WORKDIR /var/www
