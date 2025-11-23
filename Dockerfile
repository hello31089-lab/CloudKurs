# Используем базовый образ с Ubuntu
FROM ubuntu:20.04

# Устанавливаем необходимые пакеты
RUN apt-get update && apt-get install -y 
    curl 
    build-essential 
    && rm -rf /var/lib/apt/lists/*

# Загружаем и устанавливаем Geekbench
RUN curl -L -O https://cdn.geekbench.com/Geekbench-5.4.1-Linux.tar.gz && 
    tar -xzf Geekbench-5.4.1-Linux.tar.gz && 
    rm Geekbench-5.4.1-Linux.tar.gz

# Указываем рабочую директорию
WORKDIR /Geekbench-5.4.1-Linux

# Запускаем Geekbench
CMD ["./geekbench5"]
