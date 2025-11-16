FROM ubuntu:24.04

# Установка curl
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Установка Fn CLI (автоматически ставит fnserver)
RUN curl -LSs https://raw.githubusercontent.com/fnproject/cli/master/install | sh

EXPOSE 8080

# Запуск сервера
CMD ["fn", "start"]