#!/usr/bin/env bash
# 通讯录管理系统部署脚本（Ubuntu + Nginx + gunicorn）
# 用法：sudo bash deploy/deploy.sh
# 全新部署：默认清理 venv / node_modules / dist / staticfiles / __pycache__ 等旧环境残留
# 如需连数据库一起清空：CLEAN_DB=1 sudo bash deploy/deploy.sh

set -euo pipefail

# 部署根目录（自动检测脚本位置：脚本位于 <project>/deploy/deploy.sh，也可用 APP_ROOT 环境变量覆盖）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_ROOT="${APP_ROOT:-$(dirname "$SCRIPT_DIR")}"
DOMAIN="ecs.fuxi.space"
PORT="14200"

# 0. 清理旧环境（全新部署，不留上次残留）
echo "==> 0. 清理旧环境"
rm -rf "$APP_ROOT/backend/venv"
rm -rf "$APP_ROOT/backend/staticfiles"
rm -rf "$APP_ROOT/frontend/node_modules"
rm -rf "$APP_ROOT/frontend/dist"
find "$APP_ROOT/backend" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
if [ "${CLEAN_DB:-0}" = "1" ]; then
    echo "==> 清空数据库（CLEAN_DB=1）"
    rm -f "$APP_ROOT/backend/db.sqlite3"
    rm -rf "$APP_ROOT/backend/media"
fi

echo "==> 1. 准备后端虚拟环境"
cd "$APP_ROOT/backend"
python3 -m venv venv
source venv/bin/activate
# 配置 pip 镜像源（默认阿里云源，可用 PIP_INDEX_URL 环境变量覆盖）
export PIP_INDEX_URL="${PIP_INDEX_URL:-https://mirrors.aliyun.com/pypi/simple/}"
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
sed -i "s|/var/www/html/txl_mgmt|$APP_ROOT|g" /etc/systemd/system/txl_mgmt.service
systemctl daemon-reload
systemctl enable --now txl_mgmt.service

echo "==> 5. 安装 Nginx 站点配置（sites-available / sites-enabled 方式）"
cp "$APP_ROOT/deploy/nginx/txl_mgmt.conf" "/etc/nginx/sites-available/txl_mgmt"
ln -sf /etc/nginx/sites-available/txl_mgmt /etc/nginx/sites-enabled/txl_mgmt
nginx -t && systemctl reload nginx

echo "==> 部署完成"
echo "访问地址：https://${DOMAIN}:${PORT}"
echo "提示：请确保已通过 certbot 申请 SSL 证书："
echo "  certbot certonly --standalone -d ${DOMAIN}"
