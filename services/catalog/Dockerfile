FROM golang:1.25-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -o /out/catalog ./cmd/server

FROM alpine:3.22

RUN adduser -D -H -u 10001 appuser

WORKDIR /app

COPY --from=builder /out/catalog /app/catalog

USER appuser

EXPOSE 8304

ENTRYPOINT ["/app/catalog"]
