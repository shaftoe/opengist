# syntax=docker/dockerfile:1
#
# Opengist image
#
# Versions of the base toolchain are parametrized so they can be overridden at
# build time (--build-arg) and kept in sync in a single place.
#
#   docker build \
#     --build-arg ALPINE_VERSION=3.23 \
#     --build-arg GOLANG_VERSION=1.26.4 \
#     --build-arg NODE_VERSION=26.3.0 \
#     -t opengist .
#
# Build targets:
#   dev   - live-reloading development image (source mounted as a volume)
#   build - compiles the production binary
#   prod  - minimal runtime image (default)

ARG ALPINE_VERSION=3.23
ARG GOLANG_VERSION=1.26.4
ARG NODE_VERSION=26.3.0

########################################
# toolchain images (parametrized)      #
########################################
FROM golang:${GOLANG_VERSION}-alpine${ALPINE_VERSION} AS go
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION} AS node

########################################
# base: shared toolchain (go + node)   #
########################################
FROM alpine:${ALPINE_VERSION} AS base

ENV CGO_ENABLED=0 \
    NODE_PATH=/usr/local/lib/node_modules \
    PATH=/usr/local/go/bin:${PATH}

RUN apk add --no-cache \
        gcc \
        git \
        libstdc++ \
        make \
        musl-dev

COPY --from=go /usr/local/go/ /usr/local/go/
COPY --from=node /usr/local/ /usr/local/

WORKDIR /opengist

COPY . .


########################################
# dev: development image               #
########################################
FROM base AS dev

RUN apk add --no-cache \
        curl \
        gnupg \
        openssh-server \
        openssl \
        wget \
        xz \
    && git config --global --add safe.directory /opengist \
    && make install

EXPOSE 6157 6158 2222 16157

VOLUME ["/opengist"]

CMD ["make", "watch"]


########################################
# build: compile the production binary #
########################################
FROM base AS build

RUN make


########################################
# prod: minimal runtime image          #
########################################
FROM alpine:${ALPINE_VERSION} AS prod

LABEL org.opencontainers.image.title="Opengist" \
      org.opencontainers.image.description="Self-hosted pastebin powered by Git" \
      org.opencontainers.image.source="https://github.com/thomiceli/opengist" \
      org.opencontainers.image.licenses="AGPL-3.0"

# git is required at runtime (Opengist shells out to it); shadow is needed by
# the entrypoint to honour the UID/GID environment variables.
RUN apk add --no-cache \
        curl \
        git \
        shadow \
    && addgroup -S opengist \
    && adduser -S -G opengist -s /bin/ash -g 'Opengist User' opengist

WORKDIR /app/opengist

COPY --from=build --chown=opengist:opengist /opengist/config.yml /config.yml
COPY --from=build --chown=opengist:opengist /opengist/opengist ./opengist
COPY --from=build --chown=opengist:opengist /opengist/docker ./docker

EXPOSE 6157 6158 2222
VOLUME ["/opengist"]

HEALTHCHECK --interval=60s --timeout=30s --start-period=15s --retries=3 \
    CMD curl -f http://127.0.0.1:6157/healthcheck || exit 1

ENTRYPOINT ["./docker/entrypoint.sh"]
