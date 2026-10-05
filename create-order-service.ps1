$ErrorActionPreference = "Stop"

$Root = "D:\NUSA-DHIPA-BUSINESS-OS"
$Order = Join-Path $Root "services\order"

Write-Host "============================================================"
Write-Host " NUSA-DHIPA ORDER SERVICE GENERATOR"
Write-Host "============================================================"

New-Item -ItemType Directory -Force -Path `
    "$Order\cmd\server", `
    "$Order\internal\config", `
    "$Order\internal\domain", `
    "$Order\internal\repository", `
    "$Order\internal\service", `
    "$Order\internal\httpapi" | Out-Null

@'
module github.com/nusa-dhipa/business-os/services/order

go 1.25.0

require (
    github.com/go-chi/chi/v5 v5.2.3
    github.com/golang-jwt/jwt/v5 v5.3.0
    github.com/google/uuid v1.6.0
    github.com/jackc/pgx/v5 v5.7.5
)

require (
    github.com/jackc/pgpassfile v1.0.0 // indirect
    github.com/jackc/pgservicefile v0.0.0-20240606120523-5a60cdf6a761 // indirect
    github.com/jackc/puddle/v2 v2.2.2 // indirect
    golang.org/x/crypto v0.42.0 // indirect
    golang.org/x/sync v0.17.0 // indirect
    golang.org/x/text v0.29.0 // indirect
)
'@ | Set-Content "$Order\go.mod" -Encoding UTF8

@'
package main

import (
    "context"
    "fmt"
    "log"
    "net/http"
    "time"

    "github.com/jackc/pgx/v5/pgxpool"

    "github.com/nusa-dhipa/business-os/services/order/internal/config"
    "github.com/nusa-dhipa/business-os/services/order/internal/httpapi"
    "github.com/nusa-dhipa/business-os/services/order/internal/repository"
    "github.com/nusa-dhipa/business-os/services/order/internal/service"
)

func main() {
    cfg := config.Load()

    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()

    dbURL := fmt.Sprintf(
        "postgres://%s:%s@%s:%s/%s",
        cfg.DBUser,
        cfg.DBPassword,
        cfg.DBHost,
        cfg.DBPort,
        cfg.DBName,
    )

    db, err := pgxpool.New(ctx, dbURL)
    if err != nil {
        log.Fatalf("database pool: %v", err)
    }
    defer db.Close()

    if err := db.Ping(ctx); err != nil {
        log.Fatalf("database ping: %v", err)
    }

    repo := repository.New(db)
    svc := service.New(repo)
    router := httpapi.NewRouter(svc, cfg.JWTSecret)

    server := &http.Server{
        Addr:              ":" + cfg.Port,
        Handler:           router,
        ReadHeaderTimeout: 10 * time.Second,
        ReadTimeout:       30 * time.Second,
        WriteTimeout:      30 * time.Second,
        IdleTimeout:       60 * time.Second,
    }

    log.Printf("order service listening on :%s", cfg.Port)

    if err := server.ListenAndServe(); err != nil &&
        err != http.ErrServerClosed {
        log.Fatalf("server: %v", err)
    }
}
'@ | Set-Content "$Order\cmd\server\main.go" -Encoding UTF8

@'
package config

import "os"

type Config struct {
    Port       string
    DBHost     string
    DBPort     string
    DBName     string
    DBUser     string
    DBPassword string
    JWTSecret  string
}

func getenv(key, fallback string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return fallback
}

func Load() Config {
    return Config{
        Port:       getenv("PORT", "8305"),
        DBHost:     getenv("DB_HOST", "localhost"),
        DBPort:     getenv("DB_PORT", "15440"),
        DBName:     getenv("DB_NAME", "nusa_dhipa"),
        DBUser:     getenv("DB_USER", "nusa_dhipa"),
        DBPassword: getenv("DB_PASSWORD", "change_me"),
        JWTSecret:  getenv("JWT_SECRET", "nusa-dhipa-development-secret-change-me"),
    }
}
'@ | Set-Content "$Order\internal\config\config.go" -Encoding UTF8

@'
package domain

import "time"

type DiningTable struct {
    ID        string    `json:"id"`
    TenantID  string    `json:"tenant_id"`
    BusinessID string   `json:"business_id"`
    BranchID  string    `json:"branch_id"`
    Code      string    `json:"code"`
    Name      string    `json:"name"`
    Capacity  int       `json:"capacity"`
    Status    string    `json:"status"`
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}

type Order struct {
    ID             string        `json:"id"`
    TenantID       string        `json:"tenant_id"`
    BusinessID     string        `json:"business_id"`
    BranchID       string        `json:"branch_id"`
    OrderNumber    string        `json:"order_number"`
    TableID        string        `json:"table_id"`
    CustomerName   string        `json:"customer_name,omitempty"`
    Status         string        `json:"status"`
    PaymentStatus  string        `json:"payment_status"`
    Subtotal       float64       `json:"subtotal"`
    DiscountAmount float64       `json:"discount_amount"`
    TaxAmount      float64       `json:"tax_amount"`
    ServiceCharge  float64       `json:"service_charge"`
    GrandTotal     float64       `json:"grand_total"`
    OpenedAt       time.Time     `json:"opened_at"`
    ClosedAt       *time.Time    `json:"closed_at,omitempty"`
    CreatedBy      *string       `json:"created_by,omitempty"`
    UpdatedBy      *string       `json:"updated_by,omitempty"`
    CreatedAt      time.Time     `json:"created_at"`
    UpdatedAt      time.Time     `json:"updated_at"`
    Items          []OrderItem   `json:"items,omitempty"`
}

type OrderItem struct {
    ID             string    `json:"id"`
    TenantID       string    `json:"tenant_id"`
    BusinessID     string    `json:"business_id"`
    BranchID       string    `json:"branch_id"`
    OrderID        string    `json:"order_id"`
    ProductID      string    `json:"product_id"`
    ProductName    string    `json:"product_name"`
    ProductSKU     string    `json:"product_sku"`
    Quantity       float64   `json:"quantity"`
    Unit           string    `json:"unit"`
    UnitPrice      float64   `json:"unit_price"`
    DiscountAmount float64   `json:"discount_amount"`
    Subtotal       float64   `json:"subtotal"`
    Notes          string    `json:"notes"`
    CreatedAt      time.Time `json:"created_at"`
    UpdatedAt      time.Time `json:"updated_at"`
}
'@ | Set-Content "$Order\internal\domain\order.go" -Encoding UTF8

@'
package repository

import (
    "context"
    "errors"
    "fmt"
    "strings"
    "time"

    "github.com/google/uuid"
    "github.com/jackc/pgx/v5"
    "github.com/jackc/pgx/v5/pgxpool"

    "github.com/nusa-dhipa/business-os/services/order/internal/domain"
)

var (
    ErrNotFound       = errors.New("not found")
    ErrInvalidContext = errors.New("invalid tenant/business/branch context")
    ErrConflict       = errors.New("conflict")
    ErrInvalidState   = errors.New("invalid order state")
)

type Repository struct {
    DB *pgxpool.Pool
}

func New(db *pgxpool.Pool) *Repository {
    return &Repository{DB: db}
}

func (r *Repository) ListTables(
    ctx context.Context,
    tenantID, businessID, branchID string,
) ([]domain.DiningTable, error) {
    rows, err := r.DB.Query(ctx, `
        SELECT id, tenant_id, business_id, branch_id,
               code, name, capacity, status, created_at, updated_at
        FROM dining_tables
        WHERE tenant_id = $1
          AND business_id = $2
          AND branch_id = $3
        ORDER BY code
    `, tenantID, businessID, branchID)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    result := make([]domain.DiningTable, 0)

    for rows.Next() {
        var t domain.DiningTable

        if err := rows.Scan(
            &t.ID,
            &t.TenantID,
            &t.BusinessID,
            &t.BranchID,
            &t.Code,
            &t.Name,
            &t.Capacity,
            &t.Status,
            &t.CreatedAt,
            &t.UpdatedAt,
        ); err != nil {
            return nil, err
        }

        result = append(result, t)
    }

    return result, rows.Err()
}

func (r *Repository) CreateTable(
    ctx context.Context,
    tenantID, businessID, branchID, code, name string,
    capacity int,
) (*domain.DiningTable, error) {
    if capacity <= 0 {
        return nil, fmt.Errorf("capacity must be greater than zero")
    }

    id := uuid.NewString()

    var t domain.DiningTable

    err := r.DB.QueryRow(ctx, `
        INSERT INTO dining_tables (
            id, tenant_id, business_id, branch_id,
            code, name, capacity
        )
        SELECT $1, $2, $3, $4, $5, $6, $7
        WHERE EXISTS (
            SELECT 1
            FROM businesses b
            JOIN branches br
              ON br.business_id = b.id
             AND br.tenant_id = b.tenant_id
            WHERE b.id = $3
              AND b.tenant_id = $2
              AND br.id = $4
        )
        RETURNING
            id, tenant_id, business_id, branch_id,
            code, name, capacity, status, created_at, updated_at
    `,
        id,
        tenantID,
        businessID,
        branchID,
        code,
        name,
        capacity,
    ).Scan(
        &t.ID,
        &t.TenantID,
        &t.BusinessID,
        &t.BranchID,
        &t.Code,
        &t.Name,
        &t.Capacity,
        &t.Status,
        &t.CreatedAt,
        &t.UpdatedAt,
    )

    if errors.Is(err, pgx.ErrNoRows) {
        return nil, ErrInvalidContext
    }

    if err != nil {
        return nil, ErrConflict
    }

    return &t, nil
}

func (r *Repository) UpdateTableStatus(
    ctx context.Context,
    tenantID, businessID, branchID, tableID, status string,
) error {
    result, err := r.DB.Exec(ctx, `
        UPDATE dining_tables
        SET status = $1,
            updated_at = NOW()
        WHERE id = $2
          AND tenant_id = $3
          AND business_id = $4
          AND branch_id = $5
    `,
        status,
        tableID,
        tenantID,
        businessID,
        branchID,
    )

    if err != nil {
        return err
    }

    if result.RowsAffected() == 0 {
        return ErrNotFound
    }

    return nil
}

func (r *Repository) CreateOrder(
    ctx context.Context,
    tenantID, businessID, branchID, tableID,
    orderNumber, customerName, createdBy string,
) (*domain.Order, error) {
    tx, err := r.DB.Begin(ctx)
    if err != nil {
        return nil, err
    }
    defer tx.Rollback(ctx)

    var tableExists bool

    err = tx.QueryRow(ctx, `
        SELECT EXISTS (
            SELECT 1
            FROM dining_tables
            WHERE id = $1
              AND tenant_id = $2
              AND business_id = $3
              AND branch_id = $4
              AND status <> 'inactive'
        )
    `,
        tableID,
        tenantID,
        businessID,
        branchID,
    ).Scan(&tableExists)

    if err != nil {
        return nil, err
    }

    if !tableExists {
        return nil, ErrInvalidContext
    }

    var activeOrder bool

    err = tx.QueryRow(ctx, `
        SELECT EXISTS (
            SELECT 1
            FROM restaurant_orders
            WHERE table_id = $1
              AND tenant_id = $2
              AND business_id = $3
              AND branch_id = $4
              AND status IN (
                  'open',
                  'confirmed',
                  'cooking',
                  'ready',
                  'served'
              )
        )
    `,
        tableID,
        tenantID,
        businessID,
        branchID,
    ).Scan(&activeOrder)

    if err != nil {
        return nil, err
    }

    if activeOrder {
        return nil, ErrConflict
    }

    id := uuid.NewString()

    var createdByValue *string
    if strings.TrimSpace(createdBy) != "" {
        createdByValue = &createdBy
    }

    var order domain.Order

    err = tx.QueryRow(ctx, `
        INSERT INTO restaurant_orders (
            id,
            tenant_id,
            business_id,
            branch_id,
            order_number,
            table_id,
            customer_name,
            created_by
        )
        VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8
        )
        RETURNING
            id,
            tenant_id,
            business_id,
            branch_id,
            order_number,
            table_id,
            COALESCE(customer_name, ''),
            status,
            payment_status,
            subtotal,
            discount_amount,
            tax_amount,
            service_charge,
            grand_total,
            opened_at,
            closed_at,
            created_by,
            updated_by,
            created_at,
            updated_at
    `,
        id,
        tenantID,
        businessID,
        branchID,
        orderNumber,
        tableID,
        customerName,
        createdByValue,
    ).Scan(
        &order.ID,
        &order.TenantID,
        &order.BusinessID,
        &order.BranchID,
        &order.OrderNumber,
        &order.TableID,
        &order.CustomerName,
        &order.Status,
        &order.PaymentStatus,
        &order.Subtotal,
        &order.DiscountAmount,
        &order.TaxAmount,
        &order.ServiceCharge,
        &order.GrandTotal,
        &order.OpenedAt,
        &order.ClosedAt,
        &order.CreatedBy,
        &order.UpdatedBy,
        &order.CreatedAt,
        &order.UpdatedAt,
    )

    if err != nil {
        return nil, err
    }

    _, err = tx.Exec(ctx, `
        UPDATE dining_tables
        SET status = 'occupied',
            updated_at = NOW()
        WHERE id = $1
          AND tenant_id = $2
          AND business_id = $3
          AND branch_id = $4
    `,
        tableID,
        tenantID,
        businessID,
        branchID,
    )

    if err != nil {
        return nil, err
    }

    if err := tx.Commit(ctx); err != nil {
        return nil, err
    }

    return &order, nil
}

func (r *Repository) ListOrders(
    ctx context.Context,
    tenantID, businessID, branchID, status string,
) ([]domain.Order, error) {
    query := `
        SELECT
            id, tenant_id, business_id, branch_id,
            order_number, table_id,
            COALESCE(customer_name, ''),
            status, payment_status,
            subtotal, discount_amount, tax_amount,
            service_charge, grand_total,
            opened_at, closed_at,
            created_by, updated_by,
            created_at, updated_at
        FROM restaurant_orders
        WHERE tenant_id = $1
          AND business_id = $2
          AND branch_id = $3
    `

    args := []any{
        tenantID,
        businessID,
        branchID,
    }

    if strings.TrimSpace(status) != "" {
        query += ` AND status = $4`
        args = append(args, status)
    }

    query += ` ORDER BY opened_at DESC LIMIT 200`

    rows, err := r.DB.Query(ctx, query, args...)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    result := make([]domain.Order, 0)

    for rows.Next() {
        var o domain.Order

        if err := rows.Scan(
            &o.ID,
            &o.TenantID,
            &o.BusinessID,
            &o.BranchID,
            &o.OrderNumber,
            &o.TableID,
            &o.CustomerName,
            &o.Status,
            &o.PaymentStatus,
            &o.Subtotal,
            &o.DiscountAmount,
            &o.TaxAmount,
            &o.ServiceCharge,
            &o.GrandTotal,
            &o.OpenedAt,
            &o.ClosedAt,
            &o.CreatedBy,
            &o.UpdatedBy,
            &o.CreatedAt,
            &o.UpdatedAt,
        ); err != nil {
            return nil, err
        }

        result = append(result, o)
    }

    return result, rows.Err()
}

func (r *Repository) GetOrder(
    ctx context.Context,
    tenantID, businessID, branchID, orderID string,
) (*domain.Order, error) {
    var o domain.Order

    err := r.DB.QueryRow(ctx, `
        SELECT
            id, tenant_id, business_id, branch_id,
            order_number, table_id,
            COALESCE(customer_name, ''),
            status, payment_status,
            subtotal, discount_amount, tax_amount,
            service_charge, grand_total,
            opened_at, closed_at,
            created_by, updated_by,
            created_at, updated_at
        FROM restaurant_orders
        WHERE id = $1
          AND tenant_id = $2
          AND business_id = $3
          AND branch_id = $4
    `,
        orderID,
        tenantID,
        businessID,
        branchID,
    ).Scan(
        &o.ID,
        &o.TenantID,
        &o.BusinessID,
        &o.BranchID,
        &o.OrderNumber,
        &o.TableID,
        &o.CustomerName,
        &o.Status,
        &o.PaymentStatus,
        &o.Subtotal,
        &o.DiscountAmount,
        &o.TaxAmount,
        &o.ServiceCharge,
        &o.GrandTotal,
        &o.OpenedAt,
        &o.ClosedAt,
        &o.CreatedBy,
        &o.UpdatedBy,
        &o.CreatedAt,
        &o.UpdatedAt,
    )

    if errors.Is(err, pgx.ErrNoRows) {
        return nil, ErrNotFound
    }

    if err != nil {
        return nil, err
    }

    rows, err := r.DB.Query(ctx, `
        SELECT
            id,
            tenant_id,
            business_id,
            branch_id,
            order_id,
            product_id,
            product_name,
            product_sku,
            quantity,
            unit,
            unit_price,
            discount_amount,
            subtotal,
            notes,
            created_at,
            updated_at
        FROM restaurant_order_items
        WHERE order_id = $1
          AND tenant_id = $2
          AND business_id = $3
          AND branch_id = $4
        ORDER BY created_at ASC
    `,
        orderID,
        tenantID,
        businessID,
        branchID,
    )
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    o.Items = make([]domain.OrderItem, 0)

    for rows.Next() {
        var item domain.OrderItem

        if err := rows.Scan(
            &item.ID,
            &item.TenantID,
            &item.BusinessID,
            &item.BranchID,
            &item.OrderID,
            &item.ProductID,
            &item.ProductName,
            &item.ProductSKU,
            &item.Quantity,
            &item.Unit,
            &item.UnitPrice,
            &item.DiscountAmount,
            &item.Subtotal,
            &item.Notes,
            &item.CreatedAt,
            &item.UpdatedAt,
        ); err != nil {
            return nil, err
        }

        o.Items = append(o.Items, item)
    }

    if err := rows.Err(); err != nil {
        return nil, err
    }

    return &o, nil
}

func (r *Repository) AddItem(
    ctx context.Context,
    tenantID, businessID, branchID, orderID,
    productID string,
    quantity, discount float64,
    notes string,
) (*domain.OrderItem, error) {
    if quantity <= 0 {
        return nil, fmt.Errorf("quantity must be greater than zero")
    }

    tx, err := r.DB.Begin(ctx)
    if err != nil {
        return nil, err
    }
    defer tx.Rollback(ctx)

    var orderStatus string

    err = tx.QueryRow(ctx, `
        SELECT status
        FROM restaurant_orders
        WHERE id = $1
          AND tenant_id = $2
          AND business_id = $3
          AND branch_id = $4
        FOR UPDATE
    `,
        orderID,
        tenantID,
        businessID,
        branchID,
    ).Scan(&orderStatus)

    if errors.Is(err, pgx.ErrNoRows) {
        return nil, ErrNotFound
    }

    if err != nil {
        return nil, err
    }

    if orderStatus == "completed" || orderStatus == "cancelled" {
        return nil, ErrInvalidState
    }

    var (
        productName string
        productSKU  string
        unit        string
        unitPrice   float64
        productStatus string
    )

    err = tx.QueryRow(ctx, `
        SELECT
            name,
            sku,
            unit,
            price,
            status
        FROM catalog_products
        WHERE id = $1
          AND tenant_id = $2
          AND business_id = $3
    `,
        productID,
        tenantID,
        businessID,
    ).Scan(
        &productName,
        &productSKU,
        &unit,
        &unitPrice,
        &productStatus,
    )

    if errors.Is(err, pgx.ErrNoRows) {
        return nil, ErrNotFound
    }

    if err != nil {
        return nil, err
    }

    if productStatus != "active" {
        return nil, ErrInvalidState
    }

    subtotal := quantity*unitPrice - discount
    if subtotal < 0 {
        return nil, fmt.Errorf("discount cannot exceed item amount")
    }

    itemID := uuid.NewString()

    var item domain.OrderItem

    err = tx.QueryRow(ctx, `
        INSERT INTO restaurant_order_items (
            id,
            tenant_id,
            business_id,
            branch_id,
            order_id,
            product_id,
            product_name,
            product_sku,
            quantity,
            unit,
            unit_price,
            discount_amount,
            subtotal,
            notes
        )
        VALUES (
            $1, $2, $3, $4, $5, $6,
            $7, $8, $9, $10, $11, $12,
            $13, $14
        )
        RETURNING
            id,
            tenant_id,
            business_id,
            branch_id,
            order_id,
            product_id,
            product_name,
            product_sku,
            quantity,
            unit,
            unit_price,
            discount_amount,
            subtotal,
            notes,
            created_at,
            updated_at
    `,
        itemID,
        tenantID,
        businessID,
        branchID,
        orderID,
        productID,
        productName,
        productSKU,
        quantity,
        unit,
        unitPrice,
        discount,
        subtotal,
        notes,
    ).Scan(
        &item.ID,
        &item.TenantID,
        &item.BusinessID,
        &item.BranchID,
        &item.OrderID,
        &item.ProductID,
        &item.ProductName,
        &item.ProductSKU,
        &item.Quantity,
        &item.Unit,
        &item.UnitPrice,
        &item.DiscountAmount,
        &item.Subtotal,
        &item.Notes,
        &item.CreatedAt,
        &item.UpdatedAt,
    )

    if err != nil {
        return nil, err
    }

    if orderStatus == "served" ||
        orderStatus == "ready" ||
        orderStatus == "cooking" {
        _, err = tx.Exec(ctx, `
            UPDATE restaurant_orders
            SET status = 'confirmed',
                updated_at = NOW()
            WHERE id = $1
        `, orderID)

        if err != nil {
            return nil, err
        }
    }

    if err := recalculateOrderTx(
        ctx,
        tx,
        tenantID,
        businessID,
        branchID,
        orderID,
    ); err != nil {
        return nil, err
    }

    if err := tx.Commit(ctx); err != nil {
        return nil, err
    }

    return &item, nil
}

func (r *Repository) UpdateItem(
    ctx context.Context,
    tenantID, businessID, branchID, orderID, itemID string,
    quantity, discount float64,
    notes string,
) (*domain.OrderItem, error) {
    if quantity <= 0 {
        return nil, fmt.Errorf("quantity must be greater than zero")
    }

    tx, err := r.DB.Begin(ctx)
    if err != nil {
        return nil, err
    }
    defer tx.Rollback(ctx)

    var unitPrice float64

    err = tx.QueryRow(ctx, `
        SELECT unit_price
        FROM restaurant_order_items
        WHERE id = $1
          AND order_id = $2
          AND tenant_id = $3
          AND business_id = $4
          AND branch_id = $5
        FOR UPDATE
    `,
        itemID,
        orderID,
        tenantID,
        businessID,
        branchID,
    ).Scan(&unitPrice)

    if errors.Is(err, pgx.ErrNoRows) {
        return nil, ErrNotFound
    }

    if err != nil {
        return nil, err
    }

    subtotal := quantity*unitPrice - discount
    if subtotal < 0 {
        return nil, fmt.Errorf("discount cannot exceed item amount")
    }

    var item domain.OrderItem

    err = tx.QueryRow(ctx, `
        UPDATE restaurant_order_items
        SET quantity = $1,
            discount_amount = $2,
            subtotal = $3,
            notes = $4,
            updated_at = NOW()
        WHERE id = $5
          AND order_id = $6
          AND tenant_id = $7
          AND business_id = $8
          AND branch_id = $9
        RETURNING
            id,
            tenant_id,
            business_id,
            branch_id,
            order_id,
            product_id,
            product_name,
            product_sku,
            quantity,
            unit,
            unit_price,
            discount_amount,
            subtotal,
            notes,
            created_at,
            updated_at
    `,
        quantity,
        discount,
        subtotal,
        notes,
        itemID,
        orderID,
        tenantID,
        businessID,
        branchID,
    ).Scan(
        &item.ID,
        &item.TenantID,
        &item.BusinessID,
        &item.BranchID,
        &item.OrderID,
        &item.ProductID,
        &item.ProductName,
        &item.ProductSKU,
        &item.Quantity,
        &item.Unit,
        &item.UnitPrice,
        &item.DiscountAmount,
        &item.Subtotal,
        &item.Notes,
        &item.CreatedAt,
        &item.UpdatedAt,
    )

    if err != nil {
        return nil, err
    }

    if err := recalculateOrderTx(
        ctx,
        tx,
        tenantID,
        businessID,
        branchID,
        orderID,
    ); err != nil {
        return nil, err
    }

    if err := tx.Commit(ctx); err != nil {
        return nil, err
    }

    return &item, nil
}

func (r *Repository) DeleteItem(
    ctx context.Context,
    tenantID, businessID, branchID, orderID, itemID string,
) error {
    tx, err := r.DB.Begin(ctx)
    if err != nil {
        return err
    }
    defer tx.Rollback(ctx)

    result, err := tx.Exec(ctx, `
        DELETE FROM restaurant_order_items
        WHERE id = $1
          AND order_id = $2
          AND tenant_id = $3
          AND business_id = $4
          AND branch_id = $5
    `,
        itemID,
        orderID,
        tenantID,
        businessID,
        branchID,
    )

    if err != nil {
        return err
    }

    if result.RowsAffected() == 0 {
        return ErrNotFound
    }

    if err := recalculateOrderTx(
        ctx,
        tx,
        tenantID,
        businessID,
        branchID,
        orderID,
    ); err != nil {
        return err
    }

    return tx.Commit(ctx)
}

func (r *Repository) Transition(
    ctx context.Context,
    tenantID, businessID, branchID, orderID, target string,
    updatedBy string,
) error {
    tx, err := r.DB.Begin(ctx)
    if err != nil {
        return err
    }
    defer tx.Rollback(ctx)

    var (
        current string
        payment string
        tableID string
    )

    err = tx.QueryRow(ctx, `
        SELECT status, payment_status, table_id
        FROM restaurant_orders
        WHERE id = $1
          AND tenant_id = $2
          AND business_id = $3
          AND branch_id = $4
        FOR UPDATE
    `,
        orderID,
        tenantID,
        businessID,
        branchID,
    ).Scan(
        &current,
        &payment,
        &tableID,
    )

    if errors.Is(err, pgx.ErrNoRows) {
        return ErrNotFound
    }

    if err != nil {
        return err
    }

    if !validTransition(current, target) {
        return ErrInvalidState
    }

    if target == "completed" && payment != "paid" {
        return fmt.Errorf("order cannot be completed before payment is paid")
    }

    var closedAt *time.Time
    if target == "completed" || target == "cancelled" {
        now := time.Now()
        closedAt = &now
    }

    _, err = tx.Exec(ctx, `
        UPDATE restaurant_orders
        SET status = $1,
            closed_at = COALESCE($2, closed_at),
            updated_by = NULLIF($3, ''),
            updated_at = NOW()
        WHERE id = $4
    `,
        target,
        closedAt,
        updatedBy,
        orderID,
    )

    if err != nil {
        return err
    }

    if target == "completed" || target == "cancelled" {
        _, err = tx.Exec(ctx, `
            UPDATE dining_tables
            SET status = 'available',
                updated_at = NOW()
            WHERE id = $1
              AND tenant_id = $2
              AND business_id = $3
              AND branch_id = $4
        `,
            tableID,
            tenantID,
            businessID,
            branchID,
        )

        if err != nil {
            return err
        }
    }

    return tx.Commit(ctx)
}

func validTransition(current, target string) bool {
    switch current {
    case "open":
        return target == "confirmed" || target == "cancelled"
    case "confirmed":
        return target == "cooking" || target == "cancelled"
    case "cooking":
        return target == "ready" || target == "cancelled"
    case "ready":
        return target == "served" || target == "cancelled"
    case "served":
        return target == "completed" || target == "cancelled"
    case "cancelled":
        return target == "reopen"
    default:
        return false
    }
}

func recalculateOrderTx(
    ctx context.Context,
    tx pgx.Tx,
    tenantID, businessID, branchID, orderID string,
) error {
    _, err := tx.Exec(ctx, `
        UPDATE restaurant_orders o
        SET subtotal = x.subtotal,
            grand_total =
                x.subtotal
                - o.discount_amount
                + o.tax_amount
                + o.service_charge,
            updated_at = NOW()
        FROM (
            SELECT
                COALESCE(SUM(subtotal), 0) AS subtotal
            FROM restaurant_order_items
            WHERE order_id = $1
              AND tenant_id = $2
              AND business_id = $3
              AND branch_id = $4
        ) x
        WHERE o.id = $1
          AND o.tenant_id = $2
          AND o.business_id = $3
          AND o.branch_id = $4
    `,
        orderID,
        tenantID,
        businessID,
        branchID,
    )

    return err
}
'@ | Set-Content "$Order\internal\repository\order_repository.go" -Encoding UTF8

@'
package service

import (
    "context"
    "fmt"
    "strings"
    "time"

    "github.com/google/uuid"

    "github.com/nusa-dhipa/business-os/services/order/internal/domain"
    "github.com/nusa-dhipa/business-os/services/order/internal/repository"
)

type Service struct {
    Repository *repository.Repository
}

func New(repo *repository.Repository) *Service {
    return &Service{Repository: repo}
}

func (s *Service) ListTables(
    ctx context.Context,
    tenantID, businessID, branchID string,
) ([]domain.DiningTable, error) {
    return s.Repository.ListTables(ctx, tenantID, businessID, branchID)
}

func (s *Service) CreateTable(
    ctx context.Context,
    tenantID, businessID, branchID, code, name string,
    capacity int,
) (*domain.DiningTable, error) {
    code = strings.TrimSpace(code)
    name = strings.TrimSpace(name)

    if code == "" || name == "" {
        return nil, fmt.Errorf("code and name are required")
    }

    return s.Repository.CreateTable(
        ctx,
        tenantID,
        businessID,
        branchID,
        code,
        name,
        capacity,
    )
}

func (s *Service) UpdateTableStatus(
    ctx context.Context,
    tenantID, businessID, branchID, tableID, status string,
) error {
    status = strings.ToLower(strings.TrimSpace(status))

    switch status {
    case "available", "occupied", "reserved", "inactive":
    default:
        return fmt.Errorf("invalid table status")
    }

    return s.Repository.UpdateTableStatus(
        ctx,
        tenantID,
        businessID,
        branchID,
        tableID,
        status,
    )
}

type CreateOrderInput struct {
    TenantID     string
    BusinessID   string
    BranchID     string
    TableID      string
    OrderNumber  string
    CustomerName string
    CreatedBy    string
}

func (s *Service) CreateOrder(
    ctx context.Context,
    input CreateOrderInput,
) (*domain.Order, error) {
    input.TableID = strings.TrimSpace(input.TableID)
    input.OrderNumber = strings.TrimSpace(input.OrderNumber)
    input.CustomerName = strings.TrimSpace(input.CustomerName)

    if input.TableID == "" {
        return nil, fmt.Errorf("table_id is required")
    }

    if input.OrderNumber == "" {
        input.OrderNumber = fmt.Sprintf(
            "ORD-%s-%s",
            time.Now().Format("20060102150405"),
            uuid.NewString()[:8],
        )
    }

    return s.Repository.CreateOrder(
        ctx,
        input.TenantID,
        input.BusinessID,
        input.BranchID,
        input.TableID,
        input.OrderNumber,
        input.CustomerName,
        input.CreatedBy,
    )
}

func (s *Service) ListOrders(
    ctx context.Context,
    tenantID, businessID, branchID, status string,
) ([]domain.Order, error) {
    return s.Repository.ListOrders(
        ctx,
        tenantID,
        businessID,
        branchID,
        strings.ToLower(strings.TrimSpace(status)),
    )
}

func (s *Service) GetOrder(
    ctx context.Context,
    tenantID, businessID, branchID, orderID string,
) (*domain.Order, error) {
    return s.Repository.GetOrder(
        ctx,
        tenantID,
        businessID,
        branchID,
        orderID,
    )
}

type AddItemInput struct {
    TenantID   string
    BusinessID string
    BranchID   string
    OrderID    string
    ProductID  string
    Quantity   float64
    Discount   float64
    Notes      string
}

func (s *Service) AddItem(
    ctx context.Context,
    input AddItemInput,
) (*domain.OrderItem, error) {
    input.ProductID = strings.TrimSpace(input.ProductID)
    input.Notes = strings.TrimSpace(input.Notes)

    if input.ProductID == "" {
        return nil, fmt.Errorf("product_id is required")
    }

    if input.Quantity <= 0 {
        return nil, fmt.Errorf("quantity must be greater than zero")
    }

    if input.Discount < 0 {
        return nil, fmt.Errorf("discount cannot be negative")
    }

    return s.Repository.AddItem(
        ctx,
        input.TenantID,
        input.BusinessID,
        input.BranchID,
        input.OrderID,
        input.ProductID,
        input.Quantity,
        input.Discount,
        input.Notes,
    )
}

type UpdateItemInput struct {
    TenantID   string
    BusinessID string
    BranchID   string
    OrderID    string
    ItemID     string
    Quantity   float64
    Discount   float64
    Notes      string
}

func (s *Service) UpdateItem(
    ctx context.Context,
    input UpdateItemInput,
) (*domain.OrderItem, error) {
    if input.Quantity <= 0 {
        return nil, fmt.Errorf("quantity must be greater than zero")
    }

    if input.Discount < 0 {
        return nil, fmt.Errorf("discount cannot be negative")
    }

    return s.Repository.UpdateItem(
        ctx,
        input.TenantID,
        input.BusinessID,
        input.BranchID,
        input.OrderID,
        input.ItemID,
        input.Quantity,
        input.Discount,
        strings.TrimSpace(input.Notes),
    )
}

func (s *Service) DeleteItem(
    ctx context.Context,
    tenantID, businessID, branchID, orderID, itemID string,
) error {
    return s.Repository.DeleteItem(
        ctx,
        tenantID,
        businessID,
        branchID,
        orderID,
        itemID,
    )
}

func (s *Service) Transition(
    ctx context.Context,
    tenantID, businessID, branchID,
    orderID, target, updatedBy string,
) error {
    target = strings.ToLower(strings.TrimSpace(target))

    switch target {
    case "confirmed", "cooking", "ready",
        "served", "completed", "cancelled":
    default:
        return fmt.Errorf("invalid target status")
    }

    return s.Repository.Transition(
        ctx,
        tenantID,
        businessID,
        branchID,
        orderID,
        target,
        updatedBy,
    )
}
'@ | Set-Content "$Order\internal\service\order_service.go" -Encoding UTF8

@'
package httpapi

import (
    "context"
    "encoding/json"
    "errors"
    "net/http"
    "strings"
    "time"

    "github.com/go-chi/chi/v5"
    "github.com/golang-jwt/jwt/v5"

    "github.com/nusa-dhipa/business-os/services/order/internal/domain"
    "github.com/nusa-dhipa/business-os/services/order/internal/repository"
    "github.com/nusa-dhipa/business-os/services/order/internal/service"
)

type contextKey string

const (
    userIDKey   contextKey = "user_id"
    tenantIDKey contextKey = "tenant_id"
    roleKey     contextKey = "role"
)

type Handler struct {
    Service   *service.Service
    JWTSecret string
}

type claims struct {
    UserID   string `json:"user_id"`
    TenantID string `json:"tenant_id"`
    Role     string `json:"role"`
    jwt.RegisteredClaims
}

type createTableRequest struct {
    Code     string `json:"code"`
    Name     string `json:"name"`
    Capacity int    `json:"capacity"`
}

type createOrderRequest struct {
    TableID      string `json:"table_id"`
    OrderNumber  string `json:"order_number"`
    CustomerName string `json:"customer_name"`
}

type addItemRequest struct {
    ProductID string  `json:"product_id"`
    Quantity  float64 `json:"quantity"`
    Discount  float64 `json:"discount_amount"`
    Notes     string  `json:"notes"`
}

type updateItemRequest struct {
    Quantity float64 `json:"quantity"`
    Discount float64 `json:"discount_amount"`
    Notes    string  `json:"notes"`
}

type tableStatusRequest struct {
    Status string `json:"status"`
}

func NewRouter(svc *service.Service, jwtSecret string) http.Handler {
    h := &Handler{
        Service:   svc,
        JWTSecret: jwtSecret,
    }

    r := chi.NewRouter()

    r.Get("/health", h.health)

    r.Route("/api/v1", func(r chi.Router) {
        r.Use(h.jwtMiddleware)

        r.Route("/dining-tables", func(r chi.Router) {
            r.Get("/", h.listTables)
            r.Post("/", h.createTable)
            r.Patch("/{tableID}", h.updateTable)
        })

        r.Route("/orders", func(r chi.Router) {
            r.Get("/", h.listOrders)
            r.Post("/", h.createOrder)
            r.Get("/{orderID}", h.getOrder)

            r.Post("/{orderID}/items", h.addItem)
            r.Patch("/{orderID}/items/{itemID}", h.updateItem)
            r.Delete("/{orderID}/items/{itemID}", h.deleteItem)

            r.Post("/{orderID}/confirm", h.confirm)
            r.Post("/{orderID}/cooking", h.cooking)
            r.Post("/{orderID}/ready", h.ready)
            r.Post("/{orderID}/served", h.served)
            r.Post("/{orderID}/complete", h.complete)
            r.Post("/{orderID}/cancel", h.cancel)
            r.Post("/{orderID}/reopen", h.reopen)
        })
    })

    return r
}

func (h *Handler) health(w http.ResponseWriter, r *http.Request) {
    writeJSON(w, http.StatusOK, map[string]any{
        "success": true,
        "data": map[string]any{
            "service": "order",
            "status":  "ok",
        },
    })
}

func (h *Handler) jwtMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        header := strings.TrimSpace(r.Header.Get("Authorization"))

        if !strings.HasPrefix(header, "Bearer ") {
            writeJSON(w, http.StatusUnauthorized, map[string]any{
                "success": false,
                "error":   "missing bearer token",
            })
            return
        }

        tokenString := strings.TrimSpace(strings.TrimPrefix(header, "Bearer "))

        c := &claims{}

        token, err := jwt.ParseWithClaims(
            tokenString,
            c,
            func(token *jwt.Token) (interface{}, error) {
                if token.Method != jwt.SigningMethodHS256 {
                    return nil, errors.New("unexpected signing method")
                }

                return []byte(h.JWTSecret), nil
            },
        )

        if err != nil || !token.Valid ||
            c.UserID == "" ||
            c.TenantID == "" ||
            c.Role == "" {

            writeJSON(w, http.StatusUnauthorized, map[string]any{
                "success": false,
                "error":   "invalid token",
            })
            return
        }

        if c.ExpiresAt != nil && time.Now().After(c.ExpiresAt.Time) {
            writeJSON(w, http.StatusUnauthorized, map[string]any{
                "success": false,
                "error":   "token expired",
            })
            return
        }

        ctx := context.WithValue(r.Context(), userIDKey, c.UserID)
        ctx = context.WithValue(ctx, tenantIDKey, c.TenantID)
        ctx = context.WithValue(ctx, roleKey, c.Role)

        next.ServeHTTP(w, r.WithContext(ctx))
    })
}

func tenantIDFromContext(r *http.Request) (string, bool) {
    value, ok := r.Context().Value(tenantIDKey).(string)
    return value, ok && value != ""
}

func userIDFromContext(r *http.Request) string {
    value, _ := r.Context().Value(userIDKey).(string)
    return value
}

func contextIDs(r *http.Request) (string, string, string, bool) {
    tenantID, ok := tenantIDFromContext(r)
    if !ok {
        return "", "", "", false
    }

    businessID := strings.TrimSpace(r.URL.Query().Get("business_id"))
    branchID := strings.TrimSpace(r.URL.Query().Get("branch_id"))

    if businessID == "" || branchID == "" {
        return "", "", "", false
    }

    return tenantID, businessID, branchID, true
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    _ = json.NewEncoder(w).Encode(payload)
}

func decodeJSON(w http.ResponseWriter, r *http.Request, target any) bool {
    if err := json.NewDecoder(r.Body).Decode(target); err != nil {
        writeJSON(w, http.StatusBadRequest, map[string]any{
            "success": false,
            "error":   "invalid JSON",
        })
        return false
    }

    return true
}

func mapError(w http.ResponseWriter, err error) {
    switch {
    case errors.Is(err, repository.ErrNotFound):
        writeJSON(w, http.StatusNotFound, map[string]any{
            "success": false,
            "error":   "not found",
        })

    case errors.Is(err, repository.ErrInvalidContext):
        writeJSON(w, http.StatusNotFound, map[string]any{
            "success": false,
            "error":   "invalid tenant/business/branch context",
        })

    case errors.Is(err, repository.ErrConflict):
        writeJSON(w, http.StatusConflict, map[string]any{
            "success": false,
            "error":   "conflict",
        })

    case errors.Is(err, repository.ErrInvalidState):
        writeJSON(w, http.StatusConflict, map[string]any{
            "success": false,
            "error":   "invalid order state",
        })

    default:
        writeJSON(w, http.StatusInternalServerError, map[string]any{
            "success": false,
            "error":   err.Error(),
        })
    }
}

func (h *Handler) listTables(w http.ResponseWriter, r *http.Request) {
    tenantID, businessID, branchID, ok := contextIDs(r)

    if !ok {
        writeJSON(w, http.StatusBadRequest, map[string]any{
            "success": false,
            "error":   "business_id and branch_id are required",
        })
        return
    }

    tables, err := h.Service.ListTables(
        r.Context(),
        tenantID,
        businessID,
        branchID,
    )

    if err != nil {
        mapError(w, err)
        return
    }

    writeJSON(w, http.StatusOK, map[string]any{
        "success": true,
        "data":    tables,
    })
}

func (h *Handler) createTable(w http.ResponseWriter, r *http.Request) {
    tenantID, businessID, branchID, ok := contextIDs(r)

    if !ok {
        writeJSON(w, http.StatusBadRequest, map[string]any{
            "success": false,
            "error":   "business_id and branch_id are required",
        })
        return
    }

    var req createTableRequest

    if !decodeJSON(w, r, &req) {
        return
    }

    table, err := h.Service.CreateTable(
        r.Context(),
        tenantID,
        businessID,
        branchID,
        req.Code,
        req.Name,
        req.Capacity,
    )

    if err != nil {
        mapError(w, err)
        return
    }

    writeJSON(w, http.StatusCreated, map[string]any{
        "success": true,
        "data":    table,
    })
}

func (h *Handler) updateTable(w http.ResponseWriter, r *http.Request) {
    tenantID, businessID, branchID, ok := contextIDs(r)

    if !ok {
        writeJSON(w, http.StatusBadRequest, map[string]any{
            "success": false,
            "error":   "business_id and branch_id are required",
        })
        return
    }

    tableID := strings.TrimSpace(chi.URLParam(r, "tableID"))

    var req tableStatusRequest

    if !decodeJSON(w, r, &req) {
        return
    }

    err := h.Service.UpdateTableStatus(
        r.Context(),
        tenantID,
        businessID,
        branchID,
        tableID,
        req.Status,
    )

    if err != nil {
        mapError(w, err)
        return
    }

    writeJSON(w, http.StatusOK, map[string]any{
        "success": true,
        "message": "table updated",
    })
}

func (h *Handler) listOrders(w http.ResponseWriter, r *http.Request) {
    tenantID, businessID, branchID, ok := contextIDs(r)

    if !ok {
        writeJSON(w, http.StatusBadRequest, map[string]any{
            "success": false,
            "error":   "business_id and branch_id are required",
        })
        return
    }

    orders, err := h.Service.ListOrders(
        r.Context(),
        tenantID,
        businessID,
        branchID,
        r.URL.Query().Get("status"),
    )

    if err != nil {
        mapError(w, err)
        return
    }

    writeJSON(w, http.StatusOK, map[string]any{
        "success": true,
        "data":    orders,
    })
}

func (h *Handler) createOrder(w http.ResponseWriter, r *http.Request) {
    tenantID, businessID, branchID, ok := contextIDs(r)

    if !ok {
        writeJSON(w, http.StatusBadRequest, map[string]any{
            "success": false,
            "error":   "business_id and branch_id are required",
        })
        return
    }

    var req createOrderRequest

    if !decodeJSON(w, r, &req) {
        return
    }

    order, err := h.Service.CreateOrder(
        r.Context(),
        service.CreateOrderInput{
            TenantID:     tenantID,
            BusinessID:   businessID,
            BranchID:     branchID,
            TableID:      req.TableID,
            OrderNumber:  req.OrderNumber,
            CustomerName: req.CustomerName,
            CreatedBy:    userIDFromContext(r),
        },
    )

    if err != nil {
        mapError(w, err)
        return
    }

    writeJSON(w, http.StatusCreated, map[string]any{
        "success": true,
        "data":    order,
    })
}

func (h *Handler) getOrder(w http.ResponseWriter, r *http.Request) {
    tenantID, businessID, branchID, ok := contextIDs(r)

    if !ok {
        writeJSON(w, http.StatusBadRequest, map[string]any{
            "success": false,
            "error":   "business_id and branch_id are required",
        })
        return
    }

    orderID := strings.TrimSpace(chi.URLParam(r, "orderID"))

    order, err := h.Service.GetOrder(
        r.Context(),
        tenantID,
        businessID,
        branchID,
        orderID,
    )

    if err != nil {
        mapError(w, err)
        return
    }

    writeJSON(w, http.StatusOK, map[string]any{
        "success": true,
        "data":    order,
    })
}

func (h *Handler) addItem(w http.ResponseWriter, r *http.Request) {
    tenantID, businessID, branchID, ok := contextIDs(r)

    if !ok {
        writeJSON(w, http.StatusBadRequest, map[string]any{
            "success": false,
            "error":   "business_id and branch_id are required",
        })
        return
    }

    var req addItemRequest

    if !decodeJSON(w, r, &req) {
        return
    }

    item, err := h.Service.AddItem(
        r.Context(),
        service.AddItemInput{
            TenantID:   tenantID,
            BusinessID: businessID,
            BranchID:   branchID,
            OrderID:    chi.URLParam(r, "orderID"),
            ProductID:  req.ProductID,
            Quantity:   req.Quantity,
            Discount:   req.Discount,
            Notes:      req.Notes,
        },
    )

    if err != nil {
        mapError(w, err)
        return
    }

    writeJSON(w, http.StatusCreated, map[string]any{
        "success": true,
        "data":    item,
    })
}

func (h *Handler) updateItem(w http.ResponseWriter, r *http.Request) {
    tenantID, businessID, branchID, ok := contextIDs(r)

    if !ok {
        writeJSON(w, http.StatusBadRequest, map[string]any{
            "success": false,
            "error":   "business_id and branch_id are required",
        })
        return
    }

    var req updateItemRequest

    if !decodeJSON(w, r, &req) {
        return
    }

    item, err := h.Service.UpdateItem(
        r.Context(),
        service.UpdateItemInput{
            TenantID:   tenantID,
            BusinessID: businessID,
            BranchID:   branchID,
            OrderID:    chi.URLParam(r, "orderID"),
            ItemID:     chi.URLParam(r, "itemID"),
            Quantity:   req.Quantity,
            Discount:   req.Discount,
            Notes:      req.Notes,
        },
    )

    if err != nil {
        mapError(w, err)
        return
    }

    writeJSON(w, http.StatusOK, map[string]any{
        "success": true,
        "data":    item,
    })
}

func (h *Handler) deleteItem(w http.ResponseWriter, r *http.Request) {
    tenantID, businessID, branchID, ok := contextIDs(r)

    if !ok {
        writeJSON(w, http.StatusBadRequest, map[string]any{
            "success": false,
            "error":   "business_id and branch_id are required",
        })
        return
    }

    err := h.Service.DeleteItem(
        r.Context(),
        tenantID,
        businessID,
        branchID,
        chi.URLParam(r, "orderID"),
        chi.URLParam(r, "itemID"),
    )

    if err != nil {
        mapError(w, err)
        return
    }

    writeJSON(w, http.StatusOK, map[string]any{
        "success": true,
        "message": "item deleted",
    })
}

func (h *Handler) transition(w http.ResponseWriter, r *http.Request, target string) {
    tenantID, businessID, branchID, ok := contextIDs(r)

    if !ok {
        writeJSON(w, http.StatusBadRequest, map[string]any{
            "success": false,
            "error":   "business_id and branch_id are required",
        })
        return
    }

    err := h.Service.Transition(
        r.Context(),
        tenantID,
        businessID,
        branchID,
        chi.URLParam(r, "orderID"),
        target,
        userIDFromContext(r),
    )

    if err != nil {
        mapError(w, err)
        return
    }

    writeJSON(w, http.StatusOK, map[string]any{
        "success": true,
        "message": "order status updated",
        "status":  target,
    })
}

func (h *Handler) confirm(w http.ResponseWriter, r *http.Request) {
    h.transition(w, r, "confirmed")
}

func (h *Handler) cooking(w http.ResponseWriter, r *http.Request) {
    h.transition(w, r, "cooking")
}

func (h *Handler) ready(w http.ResponseWriter, r *http.Request) {
    h.transition(w, r, "ready")
}

func (h *Handler) served(w http.ResponseWriter, r *http.Request) {
    h.transition(w, r, "served")
}

func (h *Handler) complete(w http.ResponseWriter, r *http.Request) {
    h.transition(w, r, "completed")
}

func (h *Handler) cancel(w http.ResponseWriter, r *http.Request) {
    h.transition(w, r, "cancelled")
}

func (h *Handler) reopen(w http.ResponseWriter, r *http.Request) {
    tenantID, businessID, branchID, ok := contextIDs(r)

    if !ok {
        writeJSON(w, http.StatusBadRequest, map[string]any{
            "success": false,
            "error":   "business_id and branch_id are required",
        })
        return
    }

    err := h.Service.Transition(
        r.Context(),
        tenantID,
        businessID,
        branchID,
        chi.URLParam(r, "orderID"),
        "open",
        userIDFromContext(r),
    )

    if err != nil {
        mapError(w, err)
        return
    }

    writeJSON(w, http.StatusOK, map[string]any{
        "success": true,
        "message": "order reopened",
        "status":  "open",
    })
}

// Keep domain imported intentionally so this package documents the response model boundary.
var _ domain.Order
'@ | Set-Content "$Order\internal\httpapi\handler.go" -Encoding UTF8

@'
package httpapi

import (
    "errors"
    "strings"
    "time"

    "github.com/golang-jwt/jwt/v5"
)

type jwtClaims struct {
    UserID   string `json:"user_id"`
    TenantID string `json:"tenant_id"`
    Role     string `json:"role"`
    jwt.RegisteredClaims
}

func parseToken(tokenString, secret string) (*jwtClaims, error) {
    tokenString = strings.TrimSpace(tokenString)

    if tokenString == "" {
        return nil, errors.New("empty token")
    }

    claims := &jwtClaims{}

    token, err := jwt.ParseWithClaims(
        tokenString,
        claims,
        func(token *jwt.Token) (interface{}, error) {
            if token.Method != jwt.SigningMethodHS256 {
                return nil, errors.New("unexpected signing method")
            }

            return []byte(secret), nil
        },
    )

    if err != nil {
        return nil, err
    }

    if !token.Valid {
        return nil, errors.New("invalid token")
    }

    if claims.UserID == "" ||
        claims.TenantID == "" ||
        claims.Role == "" {
        return nil, errors.New("required claims missing")
    }

    if claims.ExpiresAt != nil &&
        time.Now().After(claims.ExpiresAt.Time) {
        return nil, errors.New("token expired")
    }

    return claims, nil
}
'@ | Set-Content "$Order\internal\httpapi\jwt.go" -Encoding UTF8

@'
FROM golang:1.25-alpine AS builder

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" \
    -o /out/order ./cmd/server

FROM alpine:3.22

RUN addgroup -S app && adduser -S app -G app

WORKDIR /app

COPY --from=builder /out/order /app/order

USER app

EXPOSE 8305

ENTRYPOINT ["/app/order"]
'@ | Set-Content "$Order\Dockerfile" -Encoding UTF8

@'
# Order Service

Restaurant dine-in order service for NUSA-DHIPA BUSINESS OS.

Responsibilities:
- Dining tables
- Restaurant orders
- Restaurant order items
- Kitchen order state
- Order totals
- Tenant/business/branch isolation

Payment ownership remains in Payment Service.
Invoice ownership remains in Invoice Service.
'@ | Set-Content "$Order\README.md" -Encoding UTF8

Write-Host ""
Write-Host "Running gofmt..."

Push-Location $Order
go mod tidy
gofmt -w .\cmd\server\main.go .\internal\config\config.go .\internal\domain\order.go .\internal\repository\order_repository.go .\internal\service\order_service.go .\internal\httpapi\handler.go .\internal\httpapi\jwt.go
go test ./...
Pop-Location

Write-Host ""
Write-Host "============================================================"
Write-Host " ORDER SERVICE CREATED"
Write-Host "============================================================"

Get-ChildItem $Order -Recurse -File |
    Select-Object FullName

Write-Host ""
Write-Host "Next:"
Write-Host "  cd $Order"
Write-Host "  go test ./..."