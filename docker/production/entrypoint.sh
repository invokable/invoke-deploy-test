#!/bin/sh
set -e

# Handle volume mounting permissions for CI environments
if [ "$CI" = "true" ] || [ ! -w /var/www/html ]; then
    echo "Adjusting permissions for mounted volumes..."
    
    # Create directories that the www user needs to write to
    mkdir -p /var/www/html/vendor 2>/dev/null || true
    mkdir -p /var/www/html/storage/framework/{cache,sessions,views} 2>/dev/null || true
    mkdir -p /var/www/html/bootstrap/cache 2>/dev/null || true
    
    # If we can't write to the main directory, we need to ensure subdirectories are writable
    # This handles the case where the volume is mounted with different ownership
    if [ ! -w /var/www/html ]; then
        echo "Warning: /var/www/html is not writable by www user"
        echo "This may cause issues with composer and other file operations"
        
        # Try to make specific directories writable if they exist
        [ -d /var/www/html/vendor ] && chmod -R 755 /var/www/html/vendor 2>/dev/null || true
        [ -d /var/www/html/storage ] && chmod -R 775 /var/www/html/storage 2>/dev/null || true
        [ -d /var/www/html/bootstrap/cache ] && chmod -R 775 /var/www/html/bootstrap/cache 2>/dev/null || true
    fi
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
