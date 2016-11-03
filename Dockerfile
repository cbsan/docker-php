FROM cbsan/php:5.6

MAINTAINER Cristian B. Santos <cbsan.dev@gmail.com>

LABEL description="PHP5.6+ext sybase"
LABEL version="1.0"
LABEL name="Server PHP 5.6.27"

COPY ./sqlanywhere/* /usr/local/src

RUN set -xe \
		&& dep_lib="\
			git " \
	&& apt-get update && apt-get install -y  \
        $dep_lib \
    --no-install-recommends --no-install-suggests \
    && rm -rf /var/lib/apt/lists/* \
	&& git clone https://github.com/cbsan/sdk-sqlanywhere-php.git /usr/local/src/sdk-sqlanywhere-php \
	&& mkdir -p /opt/sqlanywhere16 \
	&& cd /usr/local/src/sdk-sqlanywhere-php \
	&& phpize \
	&& ./configure --with-sqlanywhere \
	&& make -j"$(nproc)" \
	&& make install \
	&& make clean \
	&& echo "extension=sqlanywhere.so" >> /usr/local/etc/php/php.ini\
	&& mkdir -p /opt/sqlanywhere16 \
	&& cd /usr/local/src \
	&& tar -xvzf lib64.tar.gz -C /opt/sqlanywhere16 --strip-components=1 \
	&& echo "/opt/sqlanywhere16/lib64" >> /etc/ld.so.conf.d/sqlanywhere16.conf \
	&& ldconfig \
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
		$dep_lib \
	&& rm -Rf /usr/local/src/*