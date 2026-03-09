# FideX Document Specifications (`fidex-document-specs`)

> **AS5/FideX Pharmaceutical B2B Payload Standard — Venezuelan & LATAM Edition**

[![Schema Version](https://img.shields.io/badge/schema--version-v1.0.0-blue)](CHANGELOG.md)
[![JSON Schema](https://img.shields.io/badge/JSON%20Schema-2020--12-green)](https://json-schema.org/draft/2020-12/schema)
[![GS1 Compliant](https://img.shields.io/badge/GS1-LATAM%20Compliant-orange)](docs/04-gs1-identifiers.md)

---

## What is this repository?

This repository is the **canonical source of truth** for all business document payload formats exchanged over the [FideX AS5 protocol](https://github.com/greicodex/fidex-protocol). It defines, validates, and documents the JSON payload structure for each B2B document type in the Venezuelan pharmaceutical supply chain.

The FideX standard bridges enterprise B2B EDI (GS1/AS5) with Venezuelan fiscal requirements (SENIAT/SUDEBAN), enabling secure, traceable, and legally compliant document exchange between laboratories, distributors (droguerías), and pharmacies.

---

## 📋 Document Types (v1.0 — Core Cycle)

| Document | `document_type` enum | Venezuelan Name | Description |
|---|---|---|---|
| Customer Master | `GS1_CUSTOMER_MASTER_JSON` | Ficha de Cliente | Pharmacy/distributor master data with SICM health permits |
| Product Catalog | `GS1_CATALOG_JSON` | Catálogo / Lista de Precios | SKUs, multi-tier pricing, real-time inventory |
| Purchase Order | `GS1_ORDER_JSON` | Orden de Compra | Buyer-initiated order request |
| Quote / Proposal | `GS1_ORDER_JSON` | Presupuesto | Vendor's priced response to a purchase order |
| Confirmed Order | `GS1_ORDER_JSON` | Orden Confirmada | Buyer confirms the vendor's presupuesto |
| Despatch Advice | `GS1_DESPATCH_ADVICE_JSON` | Nota de Entrega / ASN | Advance Ship Notice with SSCC lot tracking |
| Invoice | `GS1_INVOICE_JSON` | Factura | Fiscal document with SENIAT multi-currency compliance |

### Planned (v1.1)
- Credit Note (`CREDIT_NOTE`) / Debit Note (`DEBIT_NOTE`)
- Tax Retention IVA (`GS1_RETENTION_JSON` / `RETENTION_IVA`)
- Tax Retention ISLR (`GS1_RETENTION_JSON` / `RETENTION_ISLR`)

---

## 🗂 Repository Structure

```
fidex-document-specs/
├── README.md                          # This file
├── CHANGELOG.md                       # Version history
├── Makefile                           # Developer commands
├── package.json                       # ajv-cli + prettier
│
├── memory-bank/                       # Project context (GOS standard)
│   ├── 01_PROJECT_CHARTER.md
│   ├── 02_ARCHITECTURE_PRINCIPLES.md
│   └── 03_AGENTIC_WORKFLOW.md
│
├── docs/                              # Narrative & conceptual documentation
│   ├── 01-overview.md                 # Architecture & design philosophy
│   ├── 02-routing-envelope.md         # kontext_routing deep-dive
│   ├── 03-security-jose.md            # JWS/JWE Sign-then-Encrypt
│   ├── 04-gs1-identifiers.md          # GTIN, GLN, SSCC, SICM explained
│   ├── 05-venezuelan-fiscal.md        # IVA, IGTF, SENIAT, BCV rates
│   └── 06-document-lifecycle.md       # Order→Quote→Confirm→Invoice flow
│
├── schemas/                           # JSON Schema 2020-12 definitions
│   ├── _common/                       # Reusable $ref components
│   │   ├── kontext-routing.schema.json
│   │   ├── party.schema.json
│   │   ├── address.schema.json
│   │   ├── product-identity.schema.json
│   │   ├── pharma-attributes.schema.json
│   │   ├── tax-line.schema.json
│   │   ├── fiscal-totals-ves.schema.json
│   │   ├── fiscal-control.schema.json
│   │   └── related-documents.schema.json
│   ├── customer-master/
│   │   └── gs1-customer-master.schema.json
│   ├── catalog/
│   │   └── gs1-catalog.schema.json
│   ├── order/
│   │   └── gs1-order.schema.json
│   ├── despatch-advice/
│   │   └── gs1-despatch-advice.schema.json
│   └── invoice/
│       └── gs1-invoice.schema.json
│
└── examples/                          # Valid, runnable payload examples
    ├── customer-master/
    │   └── 01-pharmacy-independent.json
    ├── catalog/
    │   ├── 01-delta-update.json
    │   └── 02-full-sync-baseline.json
    ├── order/
    │   ├── 01-purchase-order.json
    │   ├── 02-quote-presupuesto.json
    │   └── 03-order-confirmed.json
    ├── despatch-advice/
    │   └── 01-asn-standard.json
    └── invoice/
        ├── 01-invoice-standard.json
        └── 02-invoice-with-fiscal-control.json
```

---

## 🚀 Quick Start

### Validate all examples against their schemas

```bash
# Install dependencies
npm install

# Validate everything
make validate

# Validate a single example
make validate-one FILE=examples/invoice/01-invoice-standard.json
```

### Explore the lifecycle

Read [`docs/06-document-lifecycle.md`](docs/06-document-lifecycle.md) to understand the full Venezuelan B2B order-to-cash flow:

```
Buyer                         Vendor (Laboratorio)
  │                                │
  │── PURCHASE_ORDER ─────────────►│  "Orden de Compra"
  │                                │
  │◄── QUOTE (Presupuesto) ────────│  Vendor prices the request
  │                                │
  │── ORDER_CONFIRMED ────────────►│  Buyer accepts the quote
  │                                │
  │◄── DESPATCH_ADVICE (ASN) ──────│  Goods are shipped
  │                                │
  │◄── INVOICE (Factura) ──────────│  Fiscal document issued
  │                                │
```

---

## 🏗 Design Principles

1. **Separation of Concerns** — The `kontext_routing` envelope carries transport metadata; `payload` carries business logic. The AS5 Hub routes without parsing sensitive content.

2. **English Enums, Bilingual Docs** — All machine-readable values are in English (`PENDING`, `SHIPPED`, `PURCHASE_ORDER`). Documentation and `description` fields are bilingual (EN/ES).

3. **GS1 Compliance** — Mandatory use of `gtin` (Global Trade Item Number) and `gln` (Global Location Number) for pharmaceutical traceability and LATAM regulatory compliance.

4. **Venezuelan Fiscal Isolation** — SENIAT-specific data (`fiscal_totals_ves`, `fiscal_control`) is isolated in dedicated nested objects, keeping the core format internationally viable.

5. **Merkle Root State Sync** — Catalog/inventory documents use `sync_state` with `previous_merkle_root` / `current_merkle_root` for self-healing "Rsync-style" synchronization.

---

## 🔗 Related Repositories

- **FideX Protocol (AS5)**: `greicodex/fidex-protocol` — Transport layer, JOSE security, J-MDN receipts
- **FideX Hub**: `greicodex/fidex-hub` — Kontext AS5 routing engine (Go)
- **FideX Odoo Plugin**: `greicodex/fidex-odoo` — AS5 mixin for Odoo ERP

---

## 📜 License

MIT © Greicodex — Open standard for the Venezuelan pharmaceutical supply chain.
