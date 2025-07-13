#!/bin/sh
set -e

# Dynamically handle user ID mismatch in CI environments
if [ "$CI" = "true" ]; then
    echo "CI environment detected, checking file permissions..."
    
    # Check if we can write to the working directory
    if [ ! -w /var/www/html ]; then
        echo "Directory /var/www/html is not writable by current user"
        echo "Current user: $(id)"
        echo "Directory ownership: $(ls -ld /var/www/html)"
        
        # Try to create required directories if possible
        mkdir -p /var/www/html/vendor 2>/dev/null || echo "Could not create vendor directory"
        mkdir -p /var/www/html/storage/framework/{cache,sessions,views} 2>/dev/null || echo "Could not create storage directories"
        mkdir -p /var/www/html/bootstrap/cache 2>/dev/null || echo "Could not create bootstrap cache directory"
        
        # Try to make subdirectories writable
        [ -d /var/www/html/vendor ] && chmod -R 755 /var/www/html/vendor 2>/dev/null || true
        [ -d /var/www/html/storage ] && chmod -R 775 /var/www/html/storage 2>/dev/null || true
        [ -d /var/www/html/bootstrap/cache ] && chmod -R 775 /var/www/html/bootstrap/cache 2>/dev/null || true
    else
        echo "Directory /var/www/html is writable"
    fi
else
    # Non-CI environment - create directories normally
    mkdir -p /var/www/html/vendor
    mkdir -p /var/www/html/storage/framework/{cache,sessions,views}
    mkdir -p /var/www/html/bootstrap/cache
fi

# Wait for Redis to be ready
echo "Waiting for Redis..."
while ! nc -z redis 6379; do
  sleep 1
done
echo "Redis is ready!"

case "$CONTAINER_ROLE" in
  app)
    echo "Starting PHP-FPM..."
    exec php-fpm
    ;;
  queue)
    echo "Starting Queue Worker..."
    exec php artisan queue:work --sleep=3 --tries=3 --max-time=3600
    ;;
  scheduler)
    echo "Starting Scheduler..."
    exec php artisan schedule:work
    ;;
  *)
    echo "Unknown container role: $CONTAINER_ROLE"
    exit 1
    ;;
esac
