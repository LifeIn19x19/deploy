FROM php:5.6-apache

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        imagemagick \
    && docker-php-ext-install -j$(nproc) iconv \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) mysqli
#    && docker-php-ext-install -j$(nproc) zlib \
#    && docker-php-ext-install -j$(nproc) imagick

COPY ./config/large-request-uris.conf /etc/apache2/conf-available/large-request-uris.conf

RUN a2enconf large-request-uris
RUN printf '[PHP]\ndate.timezone = "UTC"\n' > /usr/local/etc/php/conf.d/tzone.ini
