# SPDX-FileCopyrightText: © 2022 Kaspa Developers
# SPDX-License-Identifier: MIT
FROM golang:1.18.9 as builder

RUN mkdir /app
WORKDIR /app

# Clone kaspad repo and checkout latest tag
RUN git clone https://github.com/kaspanet/kaspad \
 && cd kaspad \
 && git checkout $(git describe --tags)

WORKDIR /app/kaspad
RUN go install -ldflags '-linkmode external -w -extldflags "-static"' . ./cmd/...

FROM alpine:latest

RUN apk add --no-cache \
    bash \
    mc

# Enable Lynx-like motion on Midnight Commander
RUN mkdir -p /root/.config/mc \
 && echo "[Panels]" > /root/.config/mc/ini \
 && echo "navigate_with_arrows=true" >> /root/.config/mc/ini

# Create Kaspa data directories
RUN mkdir -p /root/.kaspad /root/.kaspawallet

COPY --from=builder /go/bin /usr/local/bin/

EXPOSE 16110
EXPOSE 16111
EXPOSE 8082

CMD bash
