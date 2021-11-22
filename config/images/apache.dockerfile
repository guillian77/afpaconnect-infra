# ---------------------------------------------------------------------
# DEV WEB APP
# ---------------------------------------------------------------------

# Best practices    : https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
# Builds            : https://docs.docker.com/develop/develop-images/multistage-build/

FROM php:7.4-apache as build-env

ENV APP_NAME=afpaconnect
ENV WEB_PATH=public

# ---------------------------------------------------------------------
# Configure user, sudoers and permissions
# ---------------------------------------------------------------------
RUN apt-get update
RUN apt-get -y install sudo

# Executions rights
RUN chmod +x /usr/local/bin/*

RUN useradd -m ${APP_NAME} && echo ${APP_NAME}:${APP_NAME} | chpasswd && adduser ${APP_NAME} sudo

# Add "www-data" to "APP_NAME" group
RUN usermod -aG www-data ${APP_NAME}

# ---------------------------------------------------------------------
# Install PHP and PHP extensions
# ---------------------------------------------------------------------
RUN apt-get update
RUN apt-get install -y --no-install-recommends curl libzip-dev libpng-dev unzip git
RUN apt-get install -y --no-install-recommends libxml2-utils libfreetype6-dev libjpeg62-turbo-dev
RUN docker-php-ext-install -j$(nproc) zip bcmath sockets mysqli pdo pdo_mysql calendar opcache
RUN docker-php-ext-configure gd --with-jpeg=/usr/include/ --with-freetype=/usr/include/
RUN docker-php-ext-install gd
RUN pecl install xdebug-2.9.1
RUN docker-php-ext-enable xdebug

# ---------------------------------------------------------------------
# Configure PHP for WEB APP
# ---------------------------------------------------------------------
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
RUN sed -i 's/memory_limit = .*/memory_limit = -1/' "$PHP_INI_DIR/php.ini"

COPY ./config/php/apache2/php.ini "$PHP_INI_DIR/php.ini"
COPY ./config/php/cli/php.ini "$PHP_INI_DIR/cli/php.ini"

# ---------------------------------------------------------------------
# Configure Apache2 for WEB APP
# ---------------------------------------------------------------------

# Disable default sites.
RUN a2dissite 000-default
RUN a2dissite default-ssl.conf
RUN rm -rf /etc/apache2/sites-available/000-default.conf
RUN rm -rf /etc/apache2/sites-available/default-ssl.conf

# Enable required Apaches2 mods.
RUN a2enmod ssl
RUN a2enmod proxy_connect
RUN a2enmod rewrite
RUN a2enmod headers
RUN a2enmod speling

# Create file structure.
RUN mkdir -p /var/www/${APP_NAME}/${WEB_PATH}

# Copy configuration files to container.
COPY ./config/apache/dev.conf /etc/apache2/sites-available/dev.conf
RUN sed -i 's/___APP_NAME___/'${APP_NAME}'/' "/etc/apache2/sites-available/dev.conf"
RUN sed -i 's/___WEB_PATH___/'${WEB_PATH}'/' "/etc/apache2/sites-available/dev.conf"

# Set ServerName globally.
RUN echo "ServerName dev.${APP_NAME}.fr" >> /etc/apache2/apache2.conf

# Create logs files
RUN touch /var/log/apache2/${APP_NAME}-dev.error.log
RUN touch /var/log/apache2/${APP_NAME}-dev.access.log

# Give "APP_NAME" user permissions
RUN chown -R ${APP_NAME}:${APP_NAME} /var/www/
RUN chown -R ${APP_NAME}:${APP_NAME} /var/log/apache2/
RUN chown ${APP_NAME}:${APP_NAME} /var/log/apache2/${APP_NAME}-dev.error.log
RUN chown ${APP_NAME}:${APP_NAME} /var/log/apache2/${APP_NAME}-dev.access.log

# Enable APP_NAME devs sites.
RUN a2ensite dev.conf

RUN /etc/init.d/apache2 stop
RUN /etc/init.d/apache2 start

# ---------------------------------------------------------------------
# Install Composer
# ---------------------------------------------------------------------
#
# Warning - At this time. Version 1.1.1 of composer is required
# to make externals librairies work with Symfony 3.4.0.
# Dot not use version 2.0.0 yet.
#
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=2.1.8

# ---------------------------------------------------------------------
# Install Symfony binary
# ---------------------------------------------------------------------
RUN curl -sS https://get.symfony.com/cli/installer | bash
RUN mv ${HOME}/.symfony/bin/symfony /usr/local/bin/symfony

# ---------------------------------------------------------------------
# MISCELLANEOUS
# ---------------------------------------------------------------------
RUN apt-get install -y mariadb-client nano wget iputils-ping

# ---------------------------------------------------------------------
# CLEAN
# ---------------------------------------------------------------------
# Clean
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /srv/*

# ---------------------------------------------------------------------
# ENTRYPOINTS
# ---------------------------------------------------------------------
COPY ./config/entrypoints/app-entrypoint /usr/local/bin/app-entrypoint
RUN chmod +x /usr/local/bin/app-entrypoint
ENTRYPOINT ["app-entrypoint"]

COPY ./config/entrypoints/apache2-foreground /usr/local/bin/
RUN chmod +x /usr/local/bin/apache2-foreground
CMD ["apache2-foreground"]
