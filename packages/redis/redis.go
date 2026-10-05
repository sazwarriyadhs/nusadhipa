package redisx

import (
	"context"

	"github.com/redis/go-redis/v9"
)

func Connect(ctx context.Context, host string, port string) (*redis.Client, error) {
	client := redis.NewClient(&redis.Options{
		Addr: host + ":" + port,
	})

	if err := client.Ping(ctx).Err(); err != nil {
		_ = client.Close()
		return nil, err
	}

	return client, nil
}
