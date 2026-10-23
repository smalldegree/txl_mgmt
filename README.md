# 通讯录管理系统（txl_mgmt）

一个前后端分离的通讯录管理项目，提供联系人的增删改查、搜索、排序与分页功能。

## 技术栈

| 模块 | 技术 |
|------|------|
| 后端 | Python 3.10.14 · Django 4.0 · Django REST Framework · SQLite3 |
| 前端 | Vue 3 · Vite 5 · axios |
| 环境 | pyenv 虚拟环境 |

## 项目结构

```
txl_mgmt/
├── backend/                     # Django 后端
│   ├── manage.py
│   ├── requirements.txt
│   ├── config/                  # 项目配置（settings / urls / wsgi / asgi）
│   └── contacts/                # 通讯录应用
│       ├── models.py            # Contact 数据模型
│       ├── serializers.py       # DRF 序列化器
│       ├── views.py             # ViewSet（CRUD / 搜索 / 排序）
│       ├── urls.py              # RESTful 路由
│       └── management/commands/seed_contacts.py  # 测试数据生成命令
├── deploy/                      # 部署配置
│   ├── nginx/txl_mgmt.conf      # Nginx 站点配置（include 方式）
│   ├── gunicorn.service         # gunicorn systemd 服务
│   └── deploy.sh                # 一键部署脚本
└── frontend/                    # Vue3 前端
    ├── vite.config.js           # 开发代理 /api → 8000
    └── src/
        ├── api.js               # axios 封装
        ├── App.vue              # 主界面（列表 / 搜索 / 弹窗 / 分页）
        └── style.css
```

## 功能特性

- 联系人 CRUD（RESTful API）
- 关键字搜索（姓名 / 手机号 / 邮箱）
- 字段排序（`?ordering=`）
- 分页（每页 20 条）
- 手机号唯一性校验
- 测试数据一键生成（300 条）

## 快速开始

### 1. 环境准备（pyenv）

```bash
pyenv install 3.10.14          # 如未安装
pyenv virtualenv 3.10.14 txl_mgmt_env
pyenv local txl_mgmt_env       # 在项目根目录执行
```

### 2. 启动后端

```bash
cd backend
pip install -r requirements.txt
python manage.py migrate
python manage.py seed_contacts   # 可选：生成 300 条测试数据
python manage.py runserver
```

后端默认运行于 `http://127.0.0.1:8000`。

### 3. 启动前端

```bash
cd frontend
npm install
npm run dev
```

前端默认运行于 `http://localhost:5173`（端口被占用会自动顺延）。开发环境通过 Vite 代理将 `/api` 转发到后端 8000 端口。

## API 文档

基础路径：`/api`

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/contacts/` | 联系人列表（分页） |
| POST | `/contacts/` | 新建联系人 |
| GET | `/contacts/{id}/` | 联系人详情 |
| PUT | `/contacts/{id}/` | 全量更新 |
| PATCH | `/contacts/{id}/` | 部分更新 |
| DELETE | `/contacts/{id}/` | 删除联系人 |

### 列表查询参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `search` | 搜索姓名/手机号/邮箱 | `?search=张` |
| `page` | 页码 | `?page=2` |
| `ordering` | 排序字段，`-` 前缀倒序 | `?ordering=-created_at` |

### 分页响应格式

```json
{
  "count": 301,
  "next": "http://127.0.0.1:8000/api/contacts/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "张三",
      "phone": "13800001111",
      "email": "zhangsan@test.com",
      "address": "北京市朝阳区",
      "remark": "同事",
      "created_at": "2026-10-22T16:33:36+08:00",
      "updated_at": "2026-10-22T16:33:56+08:00"
    }
  ]
}
```

## 数据模型

`Contact`（表名 `contacts`）

| 字段 | 类型 | 说明 |
|------|------|------|
| name | CharField(50) | 姓名 |
| phone | CharField(20) | 手机号（唯一） |
| email | EmailField | 邮箱（可空） |
| address | CharField(200) | 地址（可空） |
| remark | TextField | 备注（可空） |
| created_at | DateTimeField | 创建时间（自动） |
| updated_at | DateTimeField | 更新时间（自动） |

## 生产部署（Ubuntu + Nginx + gunicorn + HTTPS）

架构：Nginx（HTTPS，监听 14200 端口）托管前端静态文件，并将 `/api`、`/admin` 反向代理到 gunicorn（`127.0.0.1:8000`）。

### 1. 部署目录

假设项目部署在 `/var/www/html/txl_mgmt`：

```bash
git clone https://github.com/smalldegree/txl_mgmt.git /var/www/html/txl_mgmt
```

### 2. 申请 SSL 证书（Let's Encrypt）

```bash
sudo apt install -y certbot
sudo certbot certonly --standalone -d ecs.xunwu.work
```

> 提示：`--standalone` 会临时占用 80 端口完成域名验证，验证完成后自动释放。证书生成在 `/etc/letsencrypt/live/ecs.xunwu.work/`。

### 3. 一键部署

```bash
cd /var/www/html/txl_mgmt
sudo bash deploy/deploy.sh
```

脚本会自动完成：清理旧环境 → 安装后端依赖 → 数据库迁移 → 收集静态文件 → 构建前端 → 安装 gunicorn 服务 → 安装 Nginx 配置。

> 脚本默认**全新部署**，会清理上次的 `venv`、`node_modules`、`dist`、`staticfiles`、`__pycache__` 等旧环境残留（数据库默认保留）。
> 如需连数据库一起清空（删除所有数据）：`CLEAN_DB=1 sudo bash deploy/deploy.sh`

### 4. Nginx 配置（include 方式）

站点配置文件 [deploy/nginx/txl_mgmt.conf](deploy/nginx/txl_mgmt.conf) 采用独立文件，放入 sites-available 并通过软链启用（Ubuntu 主配置默认 include `/etc/nginx/sites-enabled/*`）：

```bash
sudo cp deploy/nginx/txl_mgmt.conf /etc/nginx/sites-available/txl_mgmt
sudo ln -s /etc/nginx/sites-available/txl_mgmt /etc/nginx/sites-enabled/
```

校验并重载：

```bash
sudo nginx -t
sudo systemctl reload nginx
```

### 5. 服务管理

```bash
# gunicorn 后端
sudo systemctl status txl_mgmt
sudo systemctl restart txl_mgmt

# nginx
sudo systemctl status nginx
```

### 6. 访问

- 前端页面：`https://ecs.xunwu.work:14200`
- 管理后台：`https://ecs.xunwu.work:14200/admin`

### 生产环境注意事项

- 修改 [settings.py](backend/config/settings.py) 中 `DEBUG = False`、替换 `SECRET_KEY`
- `ALLOWED_HOSTS` 已配置为 `ecs.xunwu.work`
- 防火墙需放行 14200 端口：`sudo ufw allow 14200/tcp`
