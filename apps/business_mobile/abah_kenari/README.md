# RM Abah Kenari Operational Mobile Apps

Custom operational mobile applications built on top of
NUSA-DHIPA BUSINESS OS.

## Applications

### 1. abah_kenari_cashier

Role:
- CASHIER

Focus:
- Orders
- Tables
- Payments
- Direct payment
- Pay-after-meal
- Transaction history
- Invoice

### 2. abah_kenari_kitchen

Role:
- KITCHEN

Focus:
- New orders
- Confirmed orders
- Cooking
- Ready
- Served

### 3. abah_kenari_catalog

Role:
- WAITER

Focus:
- Menu catalog
- Menu availability
- Variants
- Add-ons
- Customer ordering
- Table/order context

## Architecture

These apps are client-specific operational applications for
RM Abah Kenari.

The main NUSA-DHIPA business_mobile remains a generic
multi-UMKM Owner Mobile.

Operational apps consume NUSA-DHIPA Business OS APIs.

Tenant and authorization must be determined by backend
authentication/session context.

Do not hardcode tenant IDs in business logic.
