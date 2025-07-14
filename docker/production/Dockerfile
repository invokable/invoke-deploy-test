FROM php:8.4-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    zip \
    unzip \
    icu-dev \
    autoconf \
    oniguruma-dev \
    supervisor \
    gcc \
    g++ \
    make \
    linux-headers \
    netcat-openbsd

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip \
    intl \
    opcache

# Install Redis extension
RUN pecl install redis \
    && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configure PHP-FPM
COPY docker/production/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY docker/production/php.ini /usr/local/etc/php/php.ini

# Set working directory
WORKDIR /var/www/html

# Copy entrypoint script
COPY docker/production/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create non-root user with matching UID for GitHub Actions compatibility
# Default to 1000 but allow override for CI environments
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN addgroup -g ${GROUP_ID} -S www && \
    adduser -u ${USER_ID} -S www -G www && \
    addgroup -g 118 -S hostgroup 2>/dev/null || true && \
    adduser www hostgroup 2>/dev/null || true

# Ensure /var/www/html directory structure is set up correctly
RUN mkdir -p /var/www/html/vendor && \
    mkdir -p /var/www/html/storage/framework/{cache,sessions,views} && \
    mkdir -p /var/www/html/bootstrap/cache

# Set ownership and permissions that work with volume mounting
RUN chown -R www:www /var/www/html && \
    chmod -R 755 /var/www/html && \
    chmod -R 775 /var/www/html/storage && \
    chmod -R 775 /var/www/html/bootstrap/cache

RUN git config --system --add safe.directory /var/www/html

USER www

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
