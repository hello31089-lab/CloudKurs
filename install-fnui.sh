#!/bin/bash
# install-fnui.sh — установка Fn Web UI через Docker + systemd

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Этот скрипт должен запускаться от root"
  exit 1
fi

FN_API_URL="${FN_API_URL:-http://10.0.1.3:8080}"

echo "Проверка наличия Docker..."
if ! command -v docker &> /dev/null; then
  echo "Docker не найден. Убедитесь, что он установлен."
  exit 1
fi

echo "Создание systemd-юнита для Fn UI..."

cat > /etc/systemd/system/fnui.service <<EOF
[Unit]
Description=Fn Project Web UI
After=docker.service
Requires=docker.service

[Service]
Type=simple
Restart=always
RestartSec=5
Environment="FN_API_URL=$FN_API_URL"
ExecStartPre=-/usr/bin/docker stop fnui
ExecStartPre=-/usr/bin/docker rm fnui
ExecStart=/usr/bin/docker run --rm \\
  --name fnui \\
  -p 4000:4000 \\
  -e FN_API_URL=$FN_API_URL \\
  fnproject/ui
ExecStop=/usr/bin/docker stop fnui
StandardOutput=journal
StandardError=journal
SyslogIdentifier=fnui

[Install]
WantedBy=multi-user.target
EOF

echo "Перезагрузка systemd и запуск сервиса..."
systemctl daemon-reload
systemctl enable --now fnui

echo "Fn UI запущен на порту 4000"
echo "Fn API URL: $FN_API_URL"