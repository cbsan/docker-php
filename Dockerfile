FROM debian:jessie

MAINTAINER Cristian B. Santos <cbsan.dev@gmail.com>

LABEL description="Debian Jessie + PHP5.6.27"
LABEL version="1.0"
LABEL name="Server PHP 5.6.27"

ENV PHP_VERSION PHP-5.6.27
ENV PHP_DIR /usr/local/etc/php
ENV BISON_VERSION bison-2.7
ENV WORK_DIR /var/www

RUN apt-get update && apt-get install -y  \
        ca-certificates \
        curl \
        libedit2 \
        libsqlite3-0 \
        libmcrypt4 \
        libxml2 \
        libicu52 \
        autoconf \
        file \
        g++ \
        gcc \
        make \
        pkg-config \
        re2c \
    --no-install-recommends --no-install-suggests \
    && rm -rf /var/lib/apt/lists/*

RUN set -xe \
    && php_build="\
        libcurl4-openssl-dev \
        libsqlite3-dev \
        libedit-dev \
        libmcrypt-dev \
        libssl-dev \
        libxml2-dev \
        libc-dev \
        libicu-dev \
        xz-utils " \
    ext_dep="\
        git " \
    && apt-get update && apt-get install -y  \
        $php_build \
        $ext_dep \
    --no-install-recommends --no-install-suggests \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p $PHP_DIR/build \
    && mkdir -p $PHP_DIR/conf.d \
    && curl -fSL https://ftp.gnu.org/gnu/bison/$BISON_VERSION.tar.gz -o $PHP_DIR/build/$BISON_VERSION.tar.gz \
    && cd $PHP_DIR/build \
    && tar -xzf $BISON_VERSION.tar.gz \
    && cd $PHP_DIR/build/$BISON_VERSION \
    && ./configure --prefix=/usr \
    && make -j"$(nproc)" \
    && make install \
    && make clean \
    && git clone -b $PHP_VERSION --depth 1 git://github.com/php/php-src $PHP_DIR/build/php \
    && cd $PHP_DIR/build/php \
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
        --with-openssl \
        --with-mcrypt \
        --with-libedit \
        --with-curl \
        --with-config-file-path=$PHP_DIR \
        --with-config-file-scan-dir=$PHP_DIR/conf.d \
    && make -j"$(nproc)" \
    && make install \
    && make clean \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
        $php_build \
        $ext_dep \
    && cp $PHP_DIR/build/php/php.ini-production $PHP_DIR/php.ini \
    && rm -Rf $PHP_DIR/build

RUN set -ex \
    && mkdir -p $WORK_DIR \
    && mkdir -p mkdir /usr/local/etc/php-fpm.d \
    && echo "<?php phpinfo();" > $WORK_DIR/phpinfo.php \
    && echo "date.timezone = America/Sao_Paulo" >> $PHP_DIR/php.ini \
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
        } > /usr/local/etc/php-fpm.d/zz-docker.conf

EXPOSE 9000

CMD ["php-fpm -D"]