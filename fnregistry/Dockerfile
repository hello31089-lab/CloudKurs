# Dockerfile.registry
FROM ubuntu:22.04

# Установка зависимостей
RUN apt-get update && \
    apt-get install -y ca-certificates wget && \
    rm -rf /var/lib/apt/lists/*

# Создание пользователя
RUN groupadd --system registry && \
    useradd --system --gid registry --shell /usr/sbin/nologin --home /var/lib/registry registry

# Установка бинарника (фиксированная версия)
ENV REGISTRY_VERSION=2.8.3
RUN wget https://github.com/distribution/distribution/releases/download/v${REGISTRY_VERSION}/registry_${REGISTRY_VERSION}_linux_amd64.tar.gz -O /tmp/registry.tar.gz && \
    tar -xzf /tmp/registry.tar.gz -C /usr/local/bin/ --strip-components=1 && \
    rm /tmp/registry.tar.gz

# Создание директории для данных и конфигурации
RUN mkdir -p /var/lib/registry && \
    chown -R registry:registry /var/lib/registry && \
    mkdir -p /etc/docker/registry

# Конфигурационный файл
RUN echo 'version: 0.1\nlog:\n  fields:\n    service: registry\nstorage:\n  filesystem:\n    rootdirectory: /var/lib/registry\nhttp:\n  addr: :5000' > /etc/docker/registry/config.yml

# Переключение на пользователя
USER registry

EXPOSE 5000

ENTRYPOINT ["registry"]
CMD ["serve", "/etc/docker/registry/config.yml"]