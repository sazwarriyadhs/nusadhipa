FROM golang:1.25-alpine AS builder

WORKDIR /src

COPY go.mod go.sum* ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build \
    -o /out/api-gateway \
    ./services/api_gateway/cmd/server

FROM alpine:3.22

WORKDIR /app

COPY --from=builder /out/api-gateway /app/api-gateway

EXPOSE 8300

ENTRYPOINT ["/app/api-gateway"]

