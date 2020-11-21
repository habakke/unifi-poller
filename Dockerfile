# syntax = docker/dockerfile:1-experimental

FROM --platform=$BUILDPLATFORM golang:1.15-alpine AS base
WORKDIR /src
ENV CGO_ENABLED=0

# Install Dependencies
RUN apk add --no-cache make git

# Download 3rd party source code
RUN git clone -b 'v2.0.1' --single-branch --depth 1 https://github.com/unifi-poller/unifi-poller.git .
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

FROM base AS build
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    BINARY=unifi-poller make

FROM busybox:musl AS bin
COPY --from=build /src/unifi-poller .
COPY --from=build /etc/ssl /etc/ssl
COPY --from=build /usr/share/zoneinfo /usr/share/zoneinfo
RUN mkdir -p /etc/unifi-poller

ENV TZ=UTC

CMD ["/unifi-poller"]
