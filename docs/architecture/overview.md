# Nusa Dhipa Business OS Architecture

## Layers

1. Client Applications
2. API Gateway
3. Business Services
4. Commerce Engine
5. Omnichannel Engine
6. AI Intelligence Layer
7. PostgreSQL / Redis
8. External Integrations

## Core Principle

Business verticals use the same core platform while enabling
specific workflows through business templates.

## Multi-Tenant

All tenant-owned business data must be isolated using tenant_id.

## AI

AI is implemented as an intelligence layer over business data
and workflows, not as an isolated chatbot feature.
