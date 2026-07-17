# Neighbor-Node

Neighbor-Node is a hyper-local rental marketplace: people within a 5km radius
rent everyday items — tools, books, electronics, sports gear — from each other.
Its defining feature is the **Node**: a managed physical storeroom (in an
apartment complex, hostel, or co-working space) where a Node Manager witnesses
every pickup and return, verified by a QR-based digital handshake.

## Repo layout

| Directory | Contents |
|---|---|
| [`backend/`](backend/) | Django 5 + DRF + PostgreSQL/PostGIS API |
| [`mobile/`](mobile/) | Flutter app (Clean Architecture, BLoC) |
| [`docs/`](docs/) | Project documentation and decision records |

## Documentation

The source of truth is [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md) — project
summary (§1), stack decision (§2), architecture (§3), data models (§4),
API map (§5), and the phase plan (§6).
