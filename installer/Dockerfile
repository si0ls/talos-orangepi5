FROM golang:1.22-bookworm AS builder

COPY go.mod go.sum /installer/

ENV GOMODCACHE=/.cache/gomod
WORKDIR /installer
RUN --mount=type=cache,target=/.cache/gomod \
    go mod download && \
    go mod verify

COPY . /installer

ENV GOCACHE=/.cache/go
WORKDIR /installer
RUN --mount=type=cache,target=/.cache/gomod \
    --mount=type=cache,target=/.cache/go \
    CGO_ENABLED=0 go build -o /orangepi-5 .

FROM scratch AS installer

COPY --from=builder /orangepi-5 /orangepi-5
COPY profile.yaml /orangepi-5.yaml
