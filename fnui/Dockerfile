# ---------- 1. База ----------
FROM ubuntu:22.04 AS base
LABEL maintainer="your@email.com"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    curl \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# ---------- 2. Node.js 18 + npm ----------
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs npm && \
    npm install -g npm@10

# ---------- 3. Сборка UI ----------
WORKDIR /src
RUN git clone https://github.com/fnproject/ui.git .

WORKDIR /src/client
RUN npm ci --legacy-peer-deps --ignore-scripts
RUN npm run build

# ---------- 4. Финальный слой ----------
FROM ubuntu:22.04 AS final
LABEL maintainer="your@email.com"

# Устанавливаем ca-certificates + nodejs + npm
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Устанавливаем npm@10 и http-server
RUN npm install -g npm@10 http-server

# Копируем UI
COPY --from=base /src/client/dist /ui

WORKDIR /ui
EXPOSE 4000

CMD ["http-server", ".", "-p", "4000", "--cors"]