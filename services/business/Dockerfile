FROM golang:1.25-alpine AS builder

WORKDIR /src

COPY go.mod go.sum* ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build \
    -o /out/business-service \
    ./services/business/cmd/server

FROM alpine:3.22

WORKDIR /app

COPY --from=builder /out/business-service /app/business-service

EXPOSE 8303

ENTRYPOINT ["/app/business-service"]

