FROM php:7.4-fpm-alpine

# Copy composer.lock and composer.json
COPY ./app/composer.lock ./app/composer.json /var/www/

# Set working directory
WORKDIR /var/www

# Install dependencies
RUN apk add curl oniguruma-dev zlib-dev libpng-dev
RUN docker-php-ext-install mysqli pdo pdo_mysql mbstring exif pcntl bcmath gd

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Add user for laravel application
RUN addgroup -g 1000 www
RUN adduser -u 1000 -s /bin/sh -G www -D www

# Copy existing application directory contents
COPY ./app /var/www

# Copy existing application directory permissions
COPY --chown=www:www ./app /var/www

# Change current user to www
USER www

# Expose port 9000 and start php-fpm server
EXPOSE 9000
CMD ["php-fpm"]
