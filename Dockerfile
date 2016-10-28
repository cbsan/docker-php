FROM debian:jessie
MAINTAINER Cristian B. Santos <cbsan.dev@gmail.com>

LABEL description="Debian Jessie + PHP5.6.27"
LABEL version="1.0"
LABEL name="Server PHP 5.6.27"

ENV PHP_VERSION PHP-5.6.27
ENV BISON_VERSION bison-2.4
ENV DIR_PHP /usr/local/etc/php
ENV DIR_WWW /var/www

ENV PHP_DEPS \
        autoconf \
        file \
        g++ \
        gcc \
        libc-dev \
        make \
        pkg-config \
        re2c

ENV PHP_BUILD_LIB \
        libcurl4-openssl-dev \
        libedit-dev \
        libsqlite3-dev \
        libssl-dev \
        libxml2-dev \
        libbz2-dev \
        libicu-dev \
        libmcrypt-dev \
        libxslt-dev \
        git

RUN apt-get update \
    && apt-get install -y \
        $PHP_DEPS \
        $PHP_BUILD_LIB \
        ca-certificates \
        curl \
        libedit2 \
        libsqlite3-0 \
        libxml2 \
        xz-utils \
    --no-install-recommends \
    && rm -r /var/lib/apt/lists/* \
    && mkdir -p /usr/local/src/php \
    && mkdir -p "$DIR_PHP"/conf.d

RUN curl -fSL https://ftp.gnu.org/gnu/bison/"$BISON_VERSION.tar.gz" -o /usr/local/src/"$BISON_VERSION.tar.gz" \
    && cd /usr/local/src \
    && tar -xzf "$BISON_VERSION.tar.gz" \
    && cd /usr/local/src/"$BISON_VERSION" \
    && ./configure --prefix=/usr \
    && make -j"$(nproc)" \
    && make install \
    && make clean \
    && rm -Rf /usr/local/src/"$BISON_VERSION.tar.gz" \
    && cd /usr/local/src \
    && rm -Rf /usr/local/src/"$BISON_VERSION"

RUN git clone -b $PHP_VERSION --depth 1 git://github.com/php/php-src /usr/local/src/php \
    && cd /usr/local/src/php \
    && ./buildconf --force \
    && ./configure \
    --disable-cgi \
    --disable-short-tags \
    --enable-fpm \
    --enable-pcntl \
    --enable-bcmath \
    --enable-mbstring \
    --enable-cli \
    --enable-intl \
    --enable-mysqlnd \
    --with-fpm-user=www-data \
    --with-fpm-group=www-data \
    --with-zlib \
    --with-bz2 \
    --with-openssl \
    --with-xsl \
    --with-mcrypt \
    --with-libedit \
    --with-curl \
    --with-config-file-path=$DIR_PHP \
    && make -j"$(nproc)" \
    && make install \
    && make clean

RUN set -ex \
    && mkdir -p "$DIR_WWW" \
    && mkdir -p mkdir /usr/local/etc/php-fpm.d \
    && echo "<?php phpinfo();" > /var/www/phpinfo.php \
    && cp /usr/local/src/php/php.ini-production /usr/local/etc/php/php.ini \
    && cp /usr/local/etc/php-fpm.conf.default /usr/local/etc/php-fpm.d/www.conf \
    && { \
            echo '[global]'; \
            echo 'include=etc/php-fpm.d/*.conf'; \
        } > /usr/local/etc/php-fpm.conf \
    && { \
            echo '[global]'; \
            echo 'error_log = /proc/self/fd/2'; \
            echo; \
            echo '[www]'; \
            echo '; if we send this to /proc/self/fd/1, it never appears'; \
            echo 'access.log = /proc/self/fd/2'; \
            echo; \
            echo 'clear_env = no'; \
            echo; \
            echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
            echo 'catch_workers_output = yes'; \
        } > /usr/local/etc/php-fpm.d/docker.conf \
    && { \
            echo '[global]'; \
            echo 'daemonize = no'; \
            echo; \
            echo '[www]'; \
            echo 'listen = [::]:9000'; \
        } > /usr/local/etc/php-fpm.d/zz-docker.conf \
    && rm -rf /usr/local/src/* \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $PHP_BUILD_LIB

EXPOSE 9000

CMD ["php-fpm"]