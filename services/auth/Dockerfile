FROM golang:1.25-alpine AS builder

WORKDIR /src

COPY go.mod go.sum* ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build \
    -o /out/auth-service \
    ./services/auth/cmd/server

FROM alpine:3.22

WORKDIR /app

COPY --from=builder /out/auth-service /app/auth-service

EXPOSE 8301

ENTRYPOINT ["/app/auth-service"]

