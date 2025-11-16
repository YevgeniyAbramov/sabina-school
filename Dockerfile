# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Копируем go.mod и go.sum
COPY go.mod go.sum ./
RUN go mod download

# Копируем весь код
COPY . .

# Собираем приложение
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/main.go

# Final stage
FROM alpine:latest

WORKDIR /app

# Устанавливаем ca-certificates для HTTPS
RUN apk --no-cache add ca-certificates

# Копируем бинарник из builder
COPY --from=builder /app/main .

# Копируем статику
COPY public ./public

# Expose порт
EXPOSE 3000

# Запускаем
CMD ["./main"]