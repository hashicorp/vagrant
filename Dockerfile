# syntax = docker.mirror.hashicorp.services/docker/dockerfile:experimental
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


FROM docker.mirror.hashicorp.services/golang:alpine AS builder

RUN apk add --no-cache git gcc libc-dev openssh

RUN mkdir -p /tmp/wp-prime
COPY go.sum /tmp/wp-prime
COPY go.mod /tmp/wp-prime

WORKDIR /tmp/wp-prime

RUN mkdir -p -m 0600 ~/.ssh \
    && ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
RUN git config --global url.ssh://git@github.com/.insteadOf https://github.com/
RUN --mount=type=ssh --mount=type=secret,id=ssh.config --mount=type=secret,id=ssh.key \
    GIT_SSH_COMMAND="ssh -o \"ControlMaster auto\" -F \"/run/secrets/ssh.config\"" \
    go mod download

COPY . /tmp/wp-src

WORKDIR /tmp/wp-src

RUN apk add --no-cache make
RUN go get github.com/kevinburke/go-bindata/...
RUN --mount=type=cache,target=/root/.cache/go-build make bin

FROM docker.mirror.hashicorp.services/alpine

COPY --from=builder /tmp/wp-src/vagrant /usr/bin/vagrant

VOLUME ["/data"]

RUN addgroup vagrant && \
    adduser -S -G vagrant vagrant && \
    mkdir /data/ && \
    chown -R vagrant:vagrant /data

USER vagrant

ENTRYPOINT ["/usr/bin/vagrant"]
