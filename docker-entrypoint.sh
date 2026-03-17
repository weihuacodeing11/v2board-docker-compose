#!/bin/bash
set -e

echo "Starting V2Board initialization..."

# Install composer dependencies if vendor directory doesn't exist
if [ ! -d "vendor" ]; then
    echo "Installing composer dependencies..."
    composer install --no-dev --optimize-autoloader --no-interaction
fi

# Copy environment file if not exists
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cp .env.docker .env
fi

# Generate application key if not set
if grep -q "APP_KEY=$" .env || grep -q 'APP_KEY=""' .env; then
    echo "Generating application key..."
    php artisan key:generate --force
fi

# Wait for database
echo "Waiting for database..."
max_attempts=30
attempt=0
while ! nc -z db 3306; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
        echo "Database connection timeout!"
        exit 1
    fi
    sleep 2
done
echo "Database is ready!"

# Wait a bit more for MySQL to be fully ready
sleep 5

# Check if database is initialized
TABLE_COUNT=$(mysql -h db -u v2board -pv2board_password v2board -e "SELECT COUNT(*) as count FROM information_schema.tables WHERE table_schema = 'v2board';" -sN 2>/dev/null || echo "0")

if [ "$TABLE_COUNT" -eq "0" ] || [ "$TABLE_COUNT" -eq "1" ]; then
    echo "Initializing database from install.sql..."
    mysql -h db -u v2board -pv2board_password v2board < database/install.sql
    echo "Database initialized successfully!"
else
    echo "Database already initialized (found $TABLE_COUNT tables)"
fi

# Create v2board config file if not exists
if [ ! -f config/v2board.php ]; then
    echo "Creating v2board config file..."
    # Use fixed admin path
    SECURE_PATH="admin"
    cat > config/v2board.php <<EOF
<?php
return [
    'secure_path' => '${SECURE_PATH}',
    'app_name' => 'V2Board',
    'app_url' => 'http://localhost',
];
EOF
    echo "V2Board config created with secure_path: ${SECURE_PATH}"
fi

# Create default admin user if no admin exists
ADMIN_COUNT=$(mysql -h db -u v2board -pv2board_password v2board -e "SELECT COUNT(*) FROM v2_user WHERE is_admin = 1;" -sN 2>/dev/null || echo "0")

if [ "$ADMIN_COUNT" -eq "0" ]; then
    echo "Creating default admin user..."
    ADMIN_EMAIL="admin@v2board.com"
    ADMIN_PASSWORD="admin123456"
    PASSWORD_HASH=$(php -r "echo password_hash('${ADMIN_PASSWORD}', PASSWORD_DEFAULT);")
    ADMIN_UUID="00000000-0000-0000-0000-000000000001"
    ADMIN_TOKEN="admin_token_00000000000000000001"

    mysql -h db -u v2board -pv2board_password v2board <<EOSQL
INSERT INTO v2_user (email, password, uuid, token, is_admin, created_at, updated_at)
VALUES ('${ADMIN_EMAIL}', '${PASSWORD_HASH}', '${ADMIN_UUID}', '${ADMIN_TOKEN}', 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE is_admin = 1;
EOSQL

    echo "=========================================="
    echo "Default Admin Account Created:"
    echo "Email: ${ADMIN_EMAIL}"
    echo "Password: ${ADMIN_PASSWORD}"
    echo "=========================================="
    echo "IMPORTANT: Please change the password after first login!"
    echo "=========================================="

    # Save credentials to a file for reference
    cat > /var/www/storage/admin_credentials.txt <<EOF
V2Board Admin Credentials
=========================
Email: ${ADMIN_EMAIL}
Password: ${ADMIN_PASSWORD}
Created: $(date)

IMPORTANT: Change this password after first login!
Delete this file after noting the credentials.
EOF
    chmod 600 /var/www/storage/admin_credentials.txt
else
    echo "Admin user already exists (found $ADMIN_COUNT admin users)"
fi

# Clear and cache config
echo "Caching configuration..."
php artisan config:cache
php artisan route:cache

# Create necessary directories
echo "Creating necessary directories..."
mkdir -p /var/www/storage/framework/{sessions,views,cache}
mkdir -p /var/www/storage/logs
mkdir -p /var/www/bootstrap/cache
mkdir -p /var/www/config/theme

# Set permissions (using 777 for development/testing to avoid permission issues with volume mounts)
echo "Setting permissions..."
chmod -R 777 /var/www/storage /var/www/bootstrap/cache /var/www/config/theme
chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache /var/www/config/theme 2>/dev/null || true

echo "V2Board initialization completed!"

exec "$@"
