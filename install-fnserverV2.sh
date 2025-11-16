#!/bin/bash
# install-fnserver.sh — установка Fn Server с локальным registry 10.0.1.5:5000
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Ошибка: Этот скрипт должен запускаться от root (sudo)"
  exit 1
fi

echo "Проверка наличия Docker"
if ! command -v docker &> /dev/null; then
  echo "Ошибка: Docker не установлен. Установите: https://docs.docker.com/engine/install/"
  exit 1
fi

if docker ps --format '{{.Names}}' | grep -q '^fnserver$'; then
  echo "Fn Server уже запущен"
  exit 0
fi

echo "Проверка доступа к registry 10.0.1.5:5000"
if ! curl -fsL http://10.0.1.5:5000/v2/ > /dev/null; then
  echo "Предупреждение: Не удалось подключиться к http://10.0.1.5:5000/v2/"
  echo "    Убедитесь, что registry запущен."
  read -p "Продолжить? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

echo "Создание systemd-юнита для Fn Server"
cat > /etc/systemd/system/fnserver.service <<'EOF'
[Unit]
Description=Fn Project Server (with local registry 10.0.1.5:5000)
After=docker.service network-online.target
Requires=docker.service
Wants=network-online.target

[Service]
Type=simple
Restart=always
RestartSec=10
TimeoutStartSec=120

# Очистка старого контейнера
ExecStartPre=-/usr/bin/docker stop fnserver
ExecStartPre=-/usr/bin/docker rm fnserver

# Запуск fnserver с FN_REGISTRY
ExecStart=/usr/bin/docker run --rm \
  --name fnserver \
  -p 8080:8080 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --privileged \
  -e FN_REGISTRY=10.0.1.5:5000 \
  fnproject/fnserver:latest

# Остановка
ExecStop=/usr/bin/docker stop fnserver

# Логи
StandardOutput=journal
StandardError=journal
SyslogIdentifier=fnserver

[Install]
WantedBy=multi-user.target
EOF

# Перезагрузка systemd и запуск
echo "Перезагрузка systemd и запуск сервиса..."
systemctl daemon-reload
systemctl enable --now fnserver



# Проверка здоровья
if curl -fsL http://localhost:8080/v2/health > /dev/null; then
  echo "Fn Server запущен"
  echo "   API: http://localhost:8080"
  echo "   Registry: 10.0.1.5:5000"
  echo "   Проверка: curl http://localhost:8080/version"
else
  echo "Не удалось подключиться к Fn Server."
  echo "   Логи: journalctl -u fnserver -f"
  exit 1
fi