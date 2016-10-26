FROM alpine:3.4

MAINTAINER Cristian B. Santos <cbsan.dev@gmail.com>

LABEL description="PHP5.6.27"
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
		pkgconf \
		re2c

RUN apk add --no-cache --virtual .persistent-deps \
		ca-certificates \
		git \
		wget \
		tar \
		gawk \
		m4 \
		xz \
		libmcrypt-dev \
		curl \
		libxslt-dev \
		bzip2-dev

RUN mkdir -p /usr/local/src/php \
	&& mkdir -p "$DIR_PHP"/conf.d \
	&& set -x \
	&& addgroup -g 82 -S www-data \
	&& adduser -u 82 -D -S -G www-data www-data \
	&& set -xe \
	apk add --no-cache --virtual .fetch-deps \
		gnupg \
		openssl

RUN apk add --no-cache --virtual .build-deps \
		$PHP_DEPS \
		curl-dev \
		libedit-dev \
		libxml2-dev \
		openssl-dev \
		sqlite-dev \
		icu-dev

COPY "$BISON_VERSION.tar.gz" /usr/local/src

RUN cd /usr/local/src \
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
    --with-config-file-path=/usr/local/etc/php \
    --with-sqlanywhere=/etc/opt/sqlanywhere16 \
    && make -j"$(nproc)" \
    && make install \
    && make clean

RUN cp /usr/local/src/php/php.ini-production /usr/local/php/php.ini \
    && mkdir -p "$DIR_WWW" \
    && echo "<?php phpinfo();" > /var/www/phpinfo.php \
    && rm -rf /var/cache/apk/* \
	&& rm -rf /usr/local/src/*

RUN set -ex \
    && cd /usr/local/etc \
    && if [ -d php-fpm.d ]; then \
        sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null; \
        cp php-fpm.d/www.conf.default php-fpm.d/www.conf; \
    else \
        mkdir php-fpm.d; \
        cp php-fpm.conf.default php-fpm.d/www.conf; \
        { \
            echo '[global]'; \
            echo 'include=etc/php-fpm.d/*.conf'; \
        } | tee php-fpm.conf; \
    fi \
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
    } | tee php-fpm.d/docker.conf \
    && { \
        echo '[global]'; \
        echo 'daemonize = no'; \
        echo; \
        echo '[www]'; \
        echo 'listen = [::]:9000'; \
    } | tee php-fpm.d/zz-docker.conf

EXPOSE 9000

CMD ["php-fpm"]