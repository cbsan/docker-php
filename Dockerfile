FROM cbsan/php:5.6

MAINTAINER Cristian B. Santos <cbsan.dev@gmail.com>

LABEL description="PHP5.6+ext sybase"
LABEL version="1.0"
LABEL name="Server PHP 5.6.27"


RUN git clone https://github.com/cbsan/sdk-sqlanywhere-php.git /usr/local/src/sdk-sqlanywhere-php \
	&& mkdir -p /opt/sqlanywhere16 \
	&& cd /usr/local/src/sdk-sqlanywhere-php \
	&& phpize \
	&& ./configure --with-sqlanywhere \
	&& make -j"$(nproc)" \
	&& make install \
	&& make clean \
	&& echo "extension=sqlanywhere.so" >> /usr/local/etc/php/php.ini

ENV LD_LIBRARY_PATH=/opt/sqlanywhere16/lib64