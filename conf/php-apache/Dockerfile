# ----------------------------------------------------
# WEB DOCKERFILE
# ----------------------------------------------------
FROM php:7.4-apache

ENV COMPOSER_ALLOW_SUPERUSER=1
ENV DEBIAN_FRONTEND="noninteractive"

EXPOSE 80
WORKDIR /app

# ------------------------
# INSTAL PACKAGES
# ------------------------
RUN apt-get update -qq && \
    apt-get install -qy \
    nano \
    git \
    iputils-ping \
    mariadb-client \
    gnupg \
    unzip \
    libcurl4-openssl-dev \
    zlib1g-dev \
    libxml2-dev \
    zip && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    docker-php-ext-install opcache bcmath curl xml pdo pdo_mysql

# PHP Extensions
COPY php.ini /usr/local/etc/php/conf.d/app.ini

# Apache configuration
COPY vhost.conf /etc/apache2/sites-available/000-default.conf
COPY apache.conf /etc/apache2/conf-available/z-app.conf

# Enable rewrite mod
RUN a2enmod rewrite remoteip && \
    a2enconf z-app

# ------------------------
# INSTAL MAILER
# ------------------------
RUN apt-get update &&\
    apt-get install --no-install-recommends --assume-yes --quiet ca-certificates curl git &&\
    rm -rf /var/lib/apt/lists/*
RUN curl -Lsf 'https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz' | tar -C '/usr/local' -xvzf -
ENV PATH /usr/local/go/bin:$PATH
RUN go get github.com/mailhog/mhsendmail
RUN cp /root/go/bin/mhsendmail /usr/bin/mhsendmail
RUN echo 'sendmail_path = /usr/bin/mhsendmail --smtp-addr mailhog:1025' > /usr/local/etc/php/php.ini

#USER 1000:1000
