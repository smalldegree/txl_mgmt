#!/usr/bin/env bash
# 通讯录管理系统部署脚本（Ubuntu + Nginx + gunicorn）
# 用法：sudo bash deploy/deploy.sh

set -euo pipefail

# 部署根目录（按需修改）
APP_ROOT="${APP_ROOT:-/var/www/txl_mgmt}"
DOMAIN="ecs.fuxi.space"
PORT="14200"

echo "==> 1. 准备后端虚拟环境"
cd "$APP_ROOT/backend"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "==> 2. 数据库迁移 & 静态文件收集"
python manage.py migrate
python manage.py collectstatic --noinput

echo "==> 3. 构建前端"
cd "$APP_ROOT/frontend"
npm install
npm run build

echo "==> 4. 安装 gunicorn systemd 服务"
cp "$APP_ROOT/deploy/gunicorn.service" /etc/systemd/system/txl_mgmt.service
sed -i "s|/var/www/txl_mgmt|$APP_ROOT|g" /etc/systemd/system/txl_mgmt.service
systemctl daemon-reload
systemctl enable --now txl_mgmt.service

echo "==> 5. 安装 Nginx 站点配置（include 方式）"
cp "$APP_ROOT/deploy/nginx/txl_mgmt.conf" "/etc/nginx/conf.d/txl_mgmt.conf"
nginx -t && systemctl reload nginx

echo "==> 部署完成"
echo "访问地址：https://${DOMAIN}:${PORT}"
echo "提示：请确保已通过 certbot 申请 SSL 证书："
echo "  certbot certonly --standalone -d ${DOMAIN}"
