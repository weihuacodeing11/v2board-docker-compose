# V2Board Docker Deployment

## 前置准备

### 配置 Docker 镜像加速（推荐）

为了加速镜像拉取，建议先配置 Docker 镜像加速器。

**OrbStack 用户**：
```bash
mkdir -p ~/.docker
cat > ~/.docker/daemon.json <<EOF
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.xuanyuan.me"
  ]
}
EOF
orbstack restart docker
```

**Docker Desktop 用户**：
1. 打开 Docker Desktop -> Settings -> Docker Engine
2. 添加镜像源配置：
```json
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}
```
3. 点击 Apply & Restart

## 一键启动

### 快速部署（推荐）

```bash
# 1. 克隆或进入项目目录
cd v2board

# 2. 一键启动所有服务
docker-compose up -d

# 3. 等待初始化完成（首次启动约需 3-5 分钟）
docker-compose logs -f app

# 看到 "V2Board initialization completed!" 表示启动成功
```

就这么简单！所有服务会自动：
- ✅ 构建 PHP 应用镜像
- ✅ 安装 Composer 依赖
- ✅ 生成 APP_KEY
- ✅ 初始化数据库
- ✅ 启动队列处理器

### 访问应用

**前端页面**: http://localhost

**管理后台**: 获取管理后台地址
```bash
docker-compose exec app php -r "require 'vendor/autoload.php'; \$app = require_once 'bootstrap/app.php'; \$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap(); echo 'Admin URL: http://localhost/' . config('v2board.secure_path', substr(md5(config('app.key')), 8, 16)) . PHP_EOL;"
```

## 服务说明

启动后会运行以下服务：

| 服务 | 说明 | 端口 |
|------|------|------|
| nginx | Web 服务器 | 80, 443 |
| app | PHP-FPM 应用 | 9000 |
| db | MySQL 8.0 数据库 | 3306 |
| redis | Redis 缓存/队列 | 6379 |
| horizon | Laravel Horizon 队列处理器 | - |

## 数据库信息

- **主机**: localhost:3306
- **数据库**: v2board
- **用户名**: v2board
- **密码**: v2board_password
- **Root 密码**: v2board_root_password

## 常用命令

### 查看服务状态
```bash
docker-compose ps
```

### 查看日志
```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f app
docker-compose logs -f horizon
docker-compose logs -f nginx
```

### 进入容器
```bash
# 进入应用容器
docker-compose exec app bash

# 进入数据库容器
docker-compose exec db bash
```

### 运行 Artisan 命令
```bash
# 清除缓存
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan route:clear

# 运行统计
docker-compose exec app php artisan v2board:statistics

# 重置流量
docker-compose exec app php artisan reset:traffic
```

### 重启服务
```bash
# 重启所有服务
docker-compose restart

# 重启特定服务
docker-compose restart app
docker-compose restart horizon
```

### 停止服务
```bash
# 停止所有服务
docker-compose down

# 停止并删除数据卷（危险！会删除数据库数据）
docker-compose down -v
```

### 更新应用
```bash
# 拉取最新代码
git pull

# 重新构建并启动
docker-compose up -d --build

# 查看日志确认更新成功
docker-compose logs -f app
```

## 配置修改

### 修改数据库密码

编辑 `docker-compose.yml`，修改以下环境变量：
```yaml
db:
  environment:
    MYSQL_ROOT_PASSWORD: your_root_password
    MYSQL_PASSWORD: your_password
```

同时修改 `.env.docker` 中的数据库密码：
```
DB_PASSWORD=your_password
```

### 修改应用配置

编辑 `.env.docker` 文件，修改后重启服务：
```bash
docker-compose restart app horizon
```

## 生产环境部署

### 安全配置

1. **修改默认密码**
   - 修改 `docker-compose.yml` 中的数据库密码
   - 修改 `.env.docker` 中的 `DB_PASSWORD`

2. **关闭调试模式**
   ```bash
   # 编辑 .env.docker
   APP_DEBUG=false
   APP_ENV=production
   ```

3. **配置域名**
   ```bash
   # 编辑 .env.docker
   APP_URL=https://your-domain.com
   ```

4. **配置 SSL**
   - 将 SSL 证书放到 `docker/nginx/ssl/` 目录
   - 修改 `docker/nginx/conf.d/default.conf` 添加 SSL 配置

### 邮件配置

编辑 `.env.docker`：
```bash
MAIL_DRIVER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=your-email@gmail.com
MAIL_FROM_NAME=V2Board
```

## 故障排查

### 容器启动失败

```bash
# 查看详细日志
docker-compose logs app

# 检查容器状态
docker-compose ps
```

### 数据库连接失败

```bash
# 检查数据库是否就绪
docker-compose exec db mysqladmin ping -h localhost -u v2board -pv2board_password

# 检查数据库日志
docker-compose logs db
```

### Horizon 队列不工作

```bash
# 重启 Horizon
docker-compose restart horizon

# 查看 Horizon 日志
docker-compose logs -f horizon
```

### 权限问题

```bash
# 修复权限
docker-compose exec app chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache
docker-compose exec app chmod -R 775 /var/www/storage /var/www/bootstrap/cache
```

### 清除所有数据重新开始

```bash
# 停止并删除所有容器和数据
docker-compose down -v

# 删除构建缓存
docker-compose build --no-cache

# 重新启动
docker-compose up -d
```

## 备份与恢复

### 备份数据库

```bash
docker-compose exec db mysqldump -u v2board -pv2board_password v2board > backup.sql
```

### 恢复数据库

```bash
docker-compose exec -T db mysql -u v2board -pv2board_password v2board < backup.sql
```

## 性能优化

### 调整 PHP 配置

编辑 `docker/php/local.ini`：
```ini
upload_max_filesize=100M
post_max_size=100M
memory_limit=512M
max_execution_time=300
```

### 调整 MySQL 配置

创建 `docker/mysql/my.cnf`：
```ini
[mysqld]
max_connections=200
innodb_buffer_pool_size=1G
```

然后在 `docker-compose.yml` 中挂载：
```yaml
db:
  volumes:
    - ./docker/mysql/my.cnf:/etc/mysql/conf.d/my.cnf
```
