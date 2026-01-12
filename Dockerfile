FROM golang:1.24.0-bookworm AS builder
# glibc а не musl как в alpine (для работы с sqlite3)

WORKDIR /app

# Установка зависимостей для компиляции sqlite3 с CGO
RUN apt-get update && apt-get install -y gcc sqlite3 libsqlite3-dev
COPY go.mod go.sum ./
RUN go mod download && go mod verify

COPY . .
RUN CGO_ENABLED=1 GOOS=linux go build -a -ldflags '-linkmode external -extldflags "-static"' -o grpc-auth ./cmd/sso/main.go
RUN CGO_ENABLED=1 GOOS=linux go build -a -ldflags '-linkmode external -extldflags "-static"' -o migrator ./cmd/migrator/main.go

FROM debian:bookworm-slim
WORKDIR /app

# Устанавливаем библиотеки для работы SQLite в рантайме
RUN apt-get update && apt-get install -y libsqlite3-0 ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/grpc-auth ./grpc-auth
COPY --from=builder /app/migrator ./migrator
COPY --from=builder /app/migrations ./migrations
COPY --from=builder /app/config/prod-docker.yaml ./config/prod-docker.yaml

EXPOSE 44044
CMD ["./grpc-auth"]

