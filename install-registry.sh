#!/bin/bash
# install-registry.sh — Установка Registry как системного сервиса на Ubuntu

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Этот скрипт должен запускаться от root"
  exit 1
fi

echo "Проверка системы..."
if ! command -v wget &> /dev/null; then
  echo "Установка wget и ca-certificates..."
  apt update
  apt install -y wget ca-certificates
fi

REGISTRY_VERSION="2.8.3"

echo "Скачивание Registry v${REGISTRY_VERSION}..."
DOWNLOAD_URL="https://github.com/distribution/distribution/releases/download/v${REGISTRY_VERSION}/registry_${REGISTRY_VERSION}_linux_amd64.tar.gz"

wget -q -O /tmp/registry.tar.gz "$DOWNLOAD_URL"

echo "Распаковка и установка бинарника..."
tar -xzf /tmp/registry.tar.gz -C /tmp/
mv /tmp/registry /usr/local/bin/registry
chmod +x /usr/local/bin/registry
rm -rf /tmp/registry.tar.gz /tmp/registry

echo "Создание системного пользователя..."
if ! id -u registry &> /dev/null; then
  useradd --system --shell /usr/sbin/nologin --home /var/lib/registry registry
fi

echo "Настройка директорий..."
mkdir -p /var/lib/registry
chown -R registry:registry /var/lib/registry

CONFIG_DIR="/etc/docker/registry"
mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_DIR/config.yml" <<EOF
version: 0.1
log:
  fields:
    service: registry
storage:
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  secret: $(openssl rand -hex 32)  # уникальный секрет для сессий
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
EOF

chown -R registry:registry "$CONFIG_DIR"

echo "Создание systemd-юнита..."

cat > /etc/systemd/system/registry.service <<EOF
[Unit]
Description=Docker Registry
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=registry
Group=registry
ExecStart=/usr/local/bin/registry serve /etc/docker/registry/config.yml
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=registry

[Install]
WantedBy=multi-user.target
EOF

echo "Перезагрузка systemd и запуск сервиса..."
systemctl daemon-reload
systemctl enable --now registry

echo "Docker Registry установлен и запущен на порту 5000"
echo "Проверка: curl http://localhost:5000/v2/"