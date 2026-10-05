package events

import (
	"context"
	"encoding/json"
	"log"
	"time"

	"github.com/redis/go-redis/v9"
)

type Publisher struct {
	Client *redis.Client
}

type BusinessIdentityUpdated struct {
	Event      string    `json:"event"`
	BusinessID string    `json:"business_id"`
	TenantID   string    `json:"tenant_id"`
	UpdatedAt  time.Time `json:"updated_at"`
}

type InventoryUpdated struct {
	Event             string    `json:"event"`
	BusinessID        string    `json:"business_id"`
	TenantID          string    `json:"tenant_id"`
	BranchID          string    `json:"branch_id"`
	ProductID         string    `json:"product_id"`
	MovementID        string    `json:"movement_id"`
	MovementType      string    `json:"movement_type"`
	Quantity          float64   `json:"quantity"`
	AvailableQuantity float64   `json:"available_quantity"`
	UpdatedAt         time.Time `json:"updated_at"`
}

func NewRedisPublisher(host, port string) *Publisher {
	client := redis.NewClient(&redis.Options{
		Addr: host + ":" + port,
	})

	return &Publisher{
		Client: client,
	}
}

func (p *Publisher) PublishBusinessIdentityUpdated(
	ctx context.Context,
	businessID string,
	tenantID string,
) error {
	payload := BusinessIdentityUpdated{
		Event:      "business.identity.updated",
		BusinessID: businessID,
		TenantID:   tenantID,
		UpdatedAt:  time.Now().UTC(),
	}

	data, err := json.Marshal(payload)
	if err != nil {
		return err
	}

	return p.Client.Publish(
		ctx,
		"nusa-dhipa.business.events",
		data,
	).Err()
}

func (p *Publisher) PublishInventoryUpdated(
	ctx context.Context,
	businessID string,
	tenantID string,
	branchID string,
	productID string,
	movementID string,
	movementType string,
	quantity float64,
	availableQuantity float64,
) error {
	payload := InventoryUpdated{
		Event:             "inventory.updated",
		BusinessID:        businessID,
		TenantID:          tenantID,
		BranchID:          branchID,
		ProductID:         productID,
		MovementID:        movementID,
		MovementType:      movementType,
		Quantity:          quantity,
		AvailableQuantity: availableQuantity,
		UpdatedAt:         time.Now().UTC(),
	}

	data, err := json.Marshal(payload)
	if err != nil {
		return err
	}

	return p.Client.Publish(
		ctx,
		"nusa-dhipa.inventory.events",
		data,
	).Err()
}

func (p *Publisher) Close() error {
	if p == nil || p.Client == nil {
		return nil
	}

	return p.Client.Close()
}

func LogPublishError(err error) {
	if err != nil {
		log.Printf("realtime event publish failed: %v", err)
	}
}
