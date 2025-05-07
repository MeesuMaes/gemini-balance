#!/bin/bash

# 设置默认值（非必填变量，基于提供的 .env 文件）
DEFAULT_AUTH_TOKEN="sk-123456"
DEFAULT_TEST_MODEL="gemini-1.5-flash"
DEFAULT_THINKING_MODELS='["gemini-2.5-flash-preview-04-17"]'
DEFAULT_THINKING_BUDGET_MAP='{"gemini-2.5-flash-preview-04-17": 4000}'
DEFAULT_IMAGE_MODELS='["gemini-2.0-flash-exp"]'
DEFAULT_SEARCH_MODELS='["gemini-2.0-flash-exp","gemini-2.0-pro-exp"]'
DEFAULT_FILTERED_MODELS='["gemini-1.0-pro-vision-latest", "gemini-pro-vision", "chat-bison-001", "text-bison-001", "embedding-gecko-001"]'
DEFAULT_TOOLS_CODE_EXECUTION_ENABLED="false"
DEFAULT_SHOW_SEARCH_LINK="true"
DEFAULT_SHOW_THINKING_PROCESS="true"
DEFAULT_BASE_URL="https://generativelanguage.googleapis.com/v1beta"
DEFAULT_MAX_FAILURES="10"
DEFAULT_MAX_RETRIES="3"
DEFAULT_CHECK_INTERVAL_HOURS="1"
DEFAULT_TIMEZONE="Asia/Shanghai"
DEFAULT_TIME_OUT="300"
DEFAULT_PROXIES='[]'
DEFAULT_PAID_KEY="AIzaSyxxxxxxxxxxxxxxxxxxx"
DEFAULT_CREATE_IMAGE_MODEL="imagen-3.0-generate-002"
DEFAULT_UPLOAD_PROVIDER="smms"
DEFAULT_SMMS_SECRET_TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
DEFAULT_PICGO_API_KEY="xxxx"
DEFAULT_CLOUDFLARE_IMGBED_URL="https://xxxxxxx.pages.dev/upload"
DEFAULT_CLOUDFLARE_IMGBED_AUTH_CODE="xxxxxxxxx"
DEFAULT_STREAM_OPTIMIZER_ENABLED="false"
DEFAULT_STREAM_MIN_DELAY="0.016"
DEFAULT_STREAM_MAX_DELAY="0.024"
DEFAULT_STREAM_SHORT_TEXT_THRESHOLD="10"
DEFAULT_STREAM_LONG_TEXT_THRESHOLD="50"
DEFAULT_STREAM_CHUNK_SIZE="5"
DEFAULT_LOG_LEVEL="info"
DEFAULT_SAFETY_SETTINGS='[{"category": "HARM_CATEGORY_HARASSMENT", "threshold": "OFF"}, {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "OFF"}, {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "OFF"}, {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "OFF"}, {"category": "HARM_CATEGORY_CIVIC_INTEGRITY", "threshold": "BLOCK_NONE"}]'

# 设置文件路径
DEFAULT_COMPOSE_FILE="docker-compose.yml"
DEFAULT_ENV_FILE=".env"

# 函数：提示并验证必填输入
prompt_required() {
    local prompt="$1"
    local var_name="$2"
    local input
    while true; do
        read -p "$prompt" input
        if [ -n "$input" ]; then
            echo "$input"
            break
        else
            echo "错误：此字段为必填项，请输入有效值。"
        fi
    done
}

# 函数：验证 MySQL 连接
validate_mysql_connection() {
    local host="$1"
    local port="$2"
    local user="$3"
    local password="$4"
    local database="$5"

    echo "正在验证 MySQL 数据库连接..."
    # 使用 mysqladmin 在临时容器中测试连接
    if docker run --rm mysql:8 mysqladmin ping -h"$host" -P"$port" -u"$user" -p"$password" --silent; then
        echo "MySQL 连接验证成功！"
        return 0
    else
        echo "错误：无法连接到 MySQL 数据库。请检查主机、端口、用户、密码或数据库名称。"
        return 1
    fi
}

# 提示用户输入必填的数据库连接信息并验证
while true; do
    echo "请输入必填的 MySQL 数据库连接信息："
    DB_HOST=$(prompt_required "数据库主机地址： " "DB_HOST")
    DB_PORT=$(prompt_required "数据库端口： " "DB_PORT")
    DB_NAME=$(prompt_required "数据库名称： " "DB_NAME")
    DB_USER=$(prompt_required "数据库用户名： " "DB_USER")

    # 使用 -s 隐藏密码输入
    while true; do
        read -s -p "数据库密码： " DB_PASSWORD
        echo # 换行
        if [ -n "$DB_PASSWORD" ]; then
            break
        else
            echo "错误：数据库密码为必填项，请输入有效值。"
        fi
    done

    # 验证数据库连接
    if validate_mysql_connection "$DB_HOST" "$DB_PORT" "$DB_USER" "$DB_PASSWORD" "$DB_NAME"; then
        break
    else
        read -p "是否重新输入数据库连接信息？(y/n)： " RETRY
        if [ "$RETRY" != "y" ]; then
            echo "部署取消。"
            exit 1
        fi
    fi
done

# 提示输入必填的 API 配置
API_KEYS=$(prompt_required "Gemini API 密钥列表（JSON 数组格式，例如 [\"key1\",\"key2\"]）： " "API_KEYS")
ALLOWED_TOKENS=$(prompt_required "允许访问的 Token 列表（JSON 数组格式，例如 [\"token1\",\"token2\"]）： " "ALLOWED_TOKENS")

# 生成 .env 文件（包含所有变量）
cat > "$DEFAULT_ENV_FILE" << EOL
# MySQL 数据库配置
MYSQL_HOST=$DB_HOST
MYSQL_PORT=$DB_PORT
MYSQL_USER=$DB_USER
MYSQL_PASSWORD=$DB_PASSWORD
MYSQL_DATABASE=$DB_NAME

# API 相关配置
API_KEYS=$API_KEYS
ALLOWED_TOKENS=$ALLOWED_TOKENS
AUTH_TOKEN=$DEFAULT_AUTH_TOKEN
TEST_MODEL=$DEFAULT_TEST_MODEL
THINKING_MODELS=$DEFAULT_THINKING_MODELS
THINKING_BUDGET_MAP=$DEFAULT_THINKING_BUDGET_MAP
IMAGE_MODELS=$DEFAULT_IMAGE_MODELS
SEARCH_MODELS=$DEFAULT_SEARCH_MODELS
FILTERED_MODELS=$DEFAULT_FILTERED_MODELS
TOOLS_CODE_EXECUTION_ENABLED=$DEFAULT_TOOLS_CODE_EXECUTION_ENABLED
SHOW_SEARCH_LINK=$DEFAULT_SHOW_SEARCH_LINK
SHOW_THINKING_PROCESS=$DEFAULT_SHOW_THINKING_PROCESS
BASE_URL=$DEFAULT_BASE_URL
MAX_FAILURES=$DEFAULT_MAX_FAILURES
MAX_RETRIES=$DEFAULT_MAX_RETRIES
CHECK_INTERVAL_HOURS=$DEFAULT_CHECK_INTERVAL_HOURS
TIMEZONE=$DEFAULT_TIMEZONE
TIME_OUT=$DEFAULT_TIME_OUT
PROXIES=$DEFAULT_PROXIES

# 图像生成相关配置
PAID_KEY=$DEFAULT_PAID_KEY
CREATE_IMAGE_MODEL=$DEFAULT_CREATE_IMAGE_MODEL
UPLOAD_PROVIDER=$DEFAULT_UPLOAD_PROVIDER
SMMS_SECRET_TOKEN=$DEFAULT_SMMS_SECRET_TOKEN
PICGO_API_KEY=$DEFAULT_PICGO_API_KEY
CLOUDFLARE_IMGBED_URL=$DEFAULT_CLOUDFLARE_IMGBED_URL
CLOUDFLARE_IMGBED_AUTH_CODE=$DEFAULT_CLOUDFLARE_IMGBED_AUTH_CODE

# 流优化相关配置
STREAM_OPTIMIZER_ENABLED=$DEFAULT_STREAM_OPTIMIZER_ENABLED
STREAM_MIN_DELAY=$DEFAULT_STREAM_MIN_DELAY
STREAM_MAX_DELAY=$DEFAULT_STREAM_MAX_DELAY
STREAM_SHORT_TEXT_THRESHOLD=$DEFAULT_STREAM_SHORT_TEXT_THRESHOLD
STREAM_LONG_TEXT_THRESHOLD=$DEFAULT_STREAM_LONG_TEXT_THRESHOLD
STREAM_CHUNK_SIZE=$DEFAULT_STREAM_CHUNK_SIZE

# 日志配置
LOG_LEVEL=$DEFAULT_LOG_LEVEL

# 安全设置
SAFETY_SETTINGS=$DEFAULT_SAFETY_SETTINGS
EOL

# 设置 .env 文件权限（仅限所有者读写）
chmod 600 "$DEFAULT_ENV_FILE"

# 生成 docker-compose.yml 文件
cat > "$DEFAULT_COMPOSE_FILE" << EOL
version: '3.8'

volumes:
  mysql_data: # 保留以备将来可能的本地数据库使用

services:
  gemini-balance:
    image: ghcr.io/snailyp/gemini-balance:latest
    container_name: gemini-balance
    restart: unless-stopped
    ports:
      - "8000:8000"
    env_file:
      - $DEFAULT_ENV_FILE
    healthcheck:
      test: ["CMD-SHELL", "python -c \"import requests; exit(0) if requests.get('http://localhost:8000/health').status_code == 200 else exit(1)\""]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
EOL

# 检查 Docker 和 Docker Compose 是否安装
if ! command -v docker &> /dev/null; then
    echo "错误：未安装 Docker。请先安装 Docker。"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "错误：未安装 Docker Compose。请先安装 Docker Compose。"
    exit 1
fi

# 启动 Docker Compose
echo "正在启动 Docker Compose 服务..."
docker-compose -f "$DEFAULT_COMPOSE_FILE" up -d

# 检查服务状态
if [ $? -eq 0 ]; then
    echo "服务启动成功！gemini-balance 运行在 http://localhost:8000"
    echo "您可以通过 'docker-compose -f $DEFAULT_COMPOSE_FILE logs' 查看日志。"
else
    echo "服务启动失败，请检查配置或日志（使用 'docker-compose -f $DEFAULT_COMPOSE_FILE logs'）。"
    exit 1
fi
