# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

V2Board is a Laravel-based proxy protocol management system supporting V2Ray, Shadowsocks, Trojan, and Hysteria protocols. It provides a complete subscription management platform with admin panel, user portal, payment integration, and server node management.

## Technology Stack

- **Framework**: Laravel 8.x
- **PHP**: ^7.3.0 | ^8.0
- **Queue System**: Laravel Horizon (Redis-based)
- **Key Dependencies**:
  - JWT authentication (firebase/php-jwt)
  - Payment: Stripe integration
  - External APIs: Google reCAPTCHA, Telegram Bot
  - Protocol support: Multiple proxy protocols

## Development Commands

### Installation & Setup
```bash
# Initial installation
bash init.sh

# Or manual installation
php composer.phar install
php artisan v2board:install

# Update system
php artisan v2board:update
```

### Daily Development
```bash
# Run tests
./vendor/bin/phpunit

# Run specific test suite
./vendor/bin/phpunit --testsuite=Unit
./vendor/bin/phpunit --testsuite=Feature

# Clear caches
php artisan cache:clear
php artisan config:clear
php artisan route:clear

# Queue management (Horizon)
php artisan horizon
php artisan horizon:terminate

# Database
php artisan migrate
php artisan db:seed
```

### Artisan Commands (Custom)
```bash
# Statistics
php artisan v2board:statistics

# Scheduled checks (normally run by cron)
php artisan check:order
php artisan check:commission
php artisan check:ticket
php artisan check:server

# User management
php artisan reset:traffic
php artisan reset:user
php artisan reset:password {email}
php artisan clear:user

# Maintenance
php artisan reset:log
php artisan send:remindMail
```

## Architecture

### Route Organization

Routes are organized by user role in `app/Http/Routes/`:
- **AdminRoute.php**: Admin panel endpoints (prefix: secure_path from config)
- **UserRoute.php**: User dashboard and subscription management
- **StaffRoute.php**: Staff/support ticket management
- **PassportRoute.php**: Authentication (login, register, password reset)
- **GuestRoute.php**: Public endpoints (plans, payments)
- **ClientRoute.php**: Subscription client configuration endpoints
- **ServerRoute.php**: Server node API for traffic reporting

All routes are loaded via `routes/web.php` which delegates to these route classes.

### Middleware Layers

Key middleware in `app/Http/Middleware/`:
- **Admin/Staff/User**: Role-based access control
- **Client**: Client application authentication
- **Language**: Multi-language support
- **RequestLog**: API request logging
- **ForceJson**: Ensures JSON responses for API routes
- **CORS**: Cross-origin resource sharing

### Service Layer

Business logic is encapsulated in `app/Services/`:
- **OrderService**: Order processing, payment handling, plan assignment
- **ServerService**: Server node management, protocol configuration
- **UserService**: User operations, traffic management
- **AuthService**: Authentication and authorization
- **PaymentService**: Payment gateway integration
- **StatisticalService**: Analytics and reporting
- **TelegramService**: Telegram bot integration
- **MailService**: Email notifications
- **ThemeService**: Frontend theme management

### Protocol Support

Client protocol handlers in `app/Http/Controllers/Client/Protocols/`:
- Clash, ClashMeta, Stash
- Surge, Surfboard, Loon
- Shadowrocket, QuantumultX
- V2rayN, V2rayNG, SagerNet
- Shadowsocks, SSRPlus, Passwall

Each protocol controller generates client-specific subscription configurations.

### Job Queue System

Background jobs in `app/Jobs/` (processed by Horizon):
- **OrderHandleJob**: Async order processing
- **SendEmailJob**: Email delivery
- **SendTelegramJob**: Telegram notifications
- **TrafficFetchJob**: Server traffic data collection

### Scheduled Tasks

Defined in `app/Console/Kernel.php`:
- Daily statistics: `v2board:statistics` at 00:10
- Every minute: order/commission/ticket checks
- Daily: traffic/log reset
- Daily reminder emails at 11:30
- Horizon snapshots every 5 minutes

### Server Node Controllers

Server-side API controllers in `app/Http/Controllers/Server/`:
- **UniProxyController**: Universal proxy protocol handler
- **DeepbworkController**: Deepbwork integration
- **ShadowsocksTidalabController**: Shadowsocks Tidalab backend
- **TrojanTidalabController**: Trojan Tidalab backend

These handle server node authentication and traffic reporting.

### Utilities

Helper classes in `app/Utils/`:
- **Helper.php**: Common utility functions
- **CacheKey.php**: Centralized cache key management
- **Dict.php**: Dictionary/enum definitions

### Database

- Migrations: `database/migrations/`
- Seeds: `database/seeds/`
- Installation SQL: `database/install.sql`
- Update SQL: `database/update.sql`

## Configuration

- Environment: `.env` (copy from `.env.example`)
- App config: `config/v2board.php` (runtime config stored in database)
- Admin panel path: Configured via `v2board.secure_path` (defaults to hash of APP_KEY)

## Important Notes

- **Queue Worker Required**: Laravel Horizon must be running for background jobs (orders, emails, traffic collection)
- **Scheduled Tasks**: Set up cron to run `php artisan schedule:run` every minute
- **Admin Path**: The admin panel URL is dynamically generated based on `secure_path` config for security
- **Multi-Protocol**: When adding server nodes, ensure protocol-specific configuration matches the server type (Vmess/Trojan/Shadowsocks/Hysteria)
- **Theme System**: Frontend themes are loaded dynamically from `resources/views/theme/` and configured per installation

## Testing

- Test configuration: `phpunit.xml`
- Test suites: Unit and Feature
- Tests use array drivers for cache/queue/session to avoid external dependencies
- Bootstrap extension: `Tests\Bootstrap`

## Deployment

### Docker Deployment (Recommended)

```bash
# Start all services
docker-compose up -d

# Initialize application
docker-compose exec app php artisan key:generate
docker-compose exec app php artisan v2board:install

# View logs
docker-compose logs -f app

# Access container
docker-compose exec app bash
```

See `README.Docker.md` for detailed Docker deployment instructions.

### Traditional Deployment

- PM2 configuration available: `pm2.yaml`
- For BT Panel (宝塔): Ownership automatically set to `www` user by `init.sh`
- Ensure proper permissions for `storage/` and `bootstrap/cache/`
