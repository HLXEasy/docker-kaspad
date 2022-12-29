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

COPY --from=builder /go/bin /

EXPOSE 16110
EXPOSE 16111
EXPOSE 8082

CMD sh
