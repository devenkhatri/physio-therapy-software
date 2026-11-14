# ==========================================
# Stage 1: Build Frontend Assets (Vite)
# ==========================================
FROM node:22-alpine AS frontend
WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# ==========================================
# Stage 2: Application Container (PHP-FPM)
# ==========================================
FROM php:8.3-fpm-alpine

# Install system dependencies and PHP extensions
RUN apk add --no-cache \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    oniguruma-dev \
    libzip-dev \
    icu-dev \
    linux-headers \
    mysql-client \
    && docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd zip intl

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Copy codebase
COPY . .

# Copy compiled assets from frontend stage
COPY --from=frontend /app/public/build ./public/build

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Copy entrypoint script and custom php.ini
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/php/local.ini /usr/local/etc/php/conf.d/local.ini
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set initial permissions
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache \
    && chmod -R 775 /var/www/storage /var/www/bootstrap/cache

EXPOSE 9000

ENTRYPOINT ["entrypoint.sh"]
CMD ["php-fpm"]
