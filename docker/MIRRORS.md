# Docker 国内镜像源配置

## 配置 Docker 镜像加速器

为了加速 Docker 镜像拉取，建议配置 Docker daemon 使用国内镜像源。

### macOS / Windows (Docker Desktop)

1. 打开 Docker Desktop
2. 进入 Settings (设置) -> Docker Engine
3. 添加以下配置：

```json
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
}
```

4. 点击 "Apply & Restart"

### Linux

编辑 `/etc/docker/daemon.json`：

```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker
```

## 已配置的国内镜像源

项目的 Dockerfile 已经配置了以下国内镜像源：

1. **Debian APT 源**: 阿里云镜像 (mirrors.aliyun.com)
2. **Composer 源**: 阿里云 Composer 镜像 (mirrors.aliyun.com/composer/)

## 验证配置

```bash
# 验证 Docker 镜像加速器配置
docker info | grep -A 5 "Registry Mirrors"

# 测试拉取速度
docker pull php:8.0-fpm
```

## 其他可用的镜像源

如果上述镜像源速度不理想，可以尝试：

- 阿里云: https://cr.console.aliyun.com/cn-hangzhou/instances/mirrors (需要登录获取专属加速地址)
- 腾讯云: https://mirror.ccs.tencentyun.com
- 七牛云: https://reg-mirror.qiniu.com
