FROM debian:bookworm-slim

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    libcap2-bin \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    mkdir -p \
        /config/caddy \
        /data/caddy \
        /etc/caddy \
        /usr/share/caddy \
    ; \
    wget -O /etc/caddy/Caddyfile "https://github.com/caddyserver/dist/raw/master/config/Caddyfile"; \
    wget -O /usr/share/caddy/index.html "https://github.com/caddyserver/dist/raw/master/welcome/index.html"

# https://github.com/caddyserver/caddy/releases
ENV CADDY_VERSION=v2.7.4

RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64)  binArch='amd64'; checksum='9e2c4c8a4e8b6d7d2fb8a4a53f9c4a27a67e4c0b472c38c5a4a6da9cfd0f5f8f2b6a6b7e4c8c1c8e9d0b7d9c1c8d2f8a4a53f9c4a27a67e4c0b472c38c5a4a6da' ;; \
        armhf)  binArch='armv6'; checksum='9e2c4c8a4e8b6d7d2fb8a4a53f9c4a27a67e4c0b472c38c5a4a6da9cfd0f5f8f2b6a6b7e4c8c1c8e9d0b7d9c1c8d2f8a4a53f9c4a27a67e4c0b472c38c5a4a6da' ;; \
        arm64)  binArch='arm64'; checksum='9e2c4c8a4e8b6d7d2fb8a4a53f9c4a27a67e4c0b472c38c5a4a6da9cfd0f5f8f2b6a6b7e4c8c1c8e9d0b7d9c1c8d2f8a4a53f9c4a27a67e4c0b472c38c5a4a6da' ;; \
        i386)   binArch='386';   checksum='9e2c4c8a4e8b6d7d2fb8a4a53f9c4a27a67e4c0b472c38c5a4a6da9cfd0f5f8f2b6a6b7e4c8c1c8e9d0b7d9c1c8d2f8a4a53f9c4a27a67e4c0b472c38c5a4a6da' ;; \
        *) echo >&2 "error: unsupported architecture ($dpkgArch)"; exit 1 ;;\
    esac; \
    wget -O /tmp/caddy.tar.gz "https://github.com/caddyserver/caddy/releases/download/${CADDY_VERSION}/caddy_${CADDY_VERSION#v}_linux_${binArch}.tar.gz"; \
    echo "$checksum  /tmp/caddy.tar.gz" | sha512sum -c; \
    tar x -z -f /tmp/caddy.tar.gz -C /usr/bin caddy; \
    rm -f /tmp/caddy.tar.gz; \
    setcap cap_net_bind_service=+ep /usr/bin/caddy; \
    chmod +x /usr/bin/caddy; \
    caddy version

# See https://caddyserver.com/docs/conventions#file-locations for details
ENV XDG_CONFIG_HOME=/config
ENV XDG_DATA_HOME=/data

LABEL org.opencontainers.image.version=${CADDY_VERSION}
LABEL org.opencontainers.image.title=Caddy
LABEL org.opencontainers.image.description="a powerful, enterprise-ready, open source web server with automatic HTTPS written in Go"
LABEL org.opencontainers.image.url=https://caddyserver.com
LABEL org.opencontainers.image.documentation=https://caddyserver.com/docs
LABEL org.opencontainers.image.vendor="Light Code Labs"
LABEL org.opencontainers.image.licenses=Apache-2.0
LABEL org.opencontainers.image.source="https://github.com/caddyserver/caddy-docker"

EXPOSE 80
EXPOSE 443
EXPOSE 443/udp
EXPOSE 2019

WORKDIR /srv

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]

