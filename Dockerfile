# Frontend
FROM node:22-alpine AS web
WORKDIR /web
COPY web2/package.json web2/package-lock.json ./
RUN npm ci
COPY web2/ ./
RUN npm run build

# Go binary
FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/main.go

# Runtime
FROM alpine:latest
WORKDIR /app
RUN apk --no-cache add ca-certificates
COPY --from=builder /app/main .
COPY --from=web /web/dist ./web2/dist

EXPOSE 3000
ENV WEB_ROOT=./web2/dist
CMD ["./main"]
