#!/bin/bash
# install-fnserver.sh — установка Fn Server через Docker + systemd
# Использует внешний insecure registry: 10.0.1.5:5000

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Этот скрипт должен запускаться от root"
  exit 1
fi

FN_REGISTRY="${FN_REGISTRY:-10.0.1.5:5000}"

echo "🔍 Проверка наличия Docker..."
if ! command -v docker &> /dev/null; then
  echo "Docker не найден. Убедитесь, что он установлен."
  exit 1
fi

# === Настройка insecure registry ===
echo "Настройка Docker для работы с insecure registry: $FN_REGISTRY"
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "insecure-registries": ["$FN_REGISTRY"]
}
EOF

echo "Перезапуск Docker для применения настроек"
systemctl restart docker

# === Проверка, не запущен ли уже fnserver ===
if docker ps --format '{{.Names}}' | grep -q '^fnserver$'; then
  echo "Fn Server уже запущен"
  exit 0
fi

# === Создание systemd-юнита ===
echo "Создание systemd-юнита для Fn Server"

cat > /etc/systemd/system/fnserver.service <<EOF
[Unit]
Description=Fn Project Server
After=docker.service
Requires=docker.service

[Service]
Type=simple
Restart=always
RestartSec=5
Environment="FN_REGISTRY=$FN_REGISTRY"
ExecStartPre=-/usr/bin/docker stop fnserver
ExecStartPre=-/usr/bin/docker rm fnserver
ExecStart=/usr/bin/docker run --rm \\
  --name fnserver \\
  -p 8080:8080 \\
  -v /var/run/docker.sock:/var/run/docker.sock \\
  --privileged \\
  -e FN_REGISTRY=$FN_REGISTRY \\
  fnproject/fnserver
ExecStop=/usr/bin/docker stop fnserver
StandardOutput=journal
StandardError=journal
SyslogIdentifier=fnserver

[Install]
WantedBy=multi-user.target
EOF

echo "Перезагрузка systemd и запуск сервиса"
systemctl daemon-reload
systemctl enable --now fnserver

echo "Fn Server запущен на порту 8080"
echo "Registry: http://$FN_REGISTRY"
echo "Проверка: curl http://localhost:8080/version"
