#!/bin/sh
set -e

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
