FROM golang:1.25-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN go build -o /legal-server ./services/legal/cmd/server

FROM alpine:3.22

WORKDIR /app

COPY --from=builder /legal-server /app/legal-server

EXPOSE 8327

ENV PORT=8327

CMD ["/app/legal-server"]