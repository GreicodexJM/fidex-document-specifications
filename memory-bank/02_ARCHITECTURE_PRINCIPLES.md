# Architecture Principles — FideX Document Specifications

## 1. Core Design Philosophy

### 1.1 Separation of Concerns
Every document consists of exactly two top-level objects:
- **`kontext_routing`** — Transport metadata (where to send, who sent it, what type). The AS5 Hub reads ONLY this layer for routing decisions. It never inspects `payload`.
- **`payload`** — Business data (what is being communicated). Contains all commercial and fiscal logic.

This means the hub can route, log, and audit documents without ever decrypting sensitive commercial content (line items, pricing, margins).

### 1.2 English Enums, Bilingual Descriptions
**Rule**: All `enum` values, field names, and `$id` identifiers use English machine-readable strings.

```json
// ✅ Correct
"doc_type": "PURCHASE_ORDER"
"status": "SHIPPED"
"catalog_type": "DELTA_UPDATE"

// ❌ Wrong
"doc_type": "ORDEN_DE_COMPRA"
"status": "DESPACHADO"
```

Rationale: JSON processing libraries (ajv, jsonata, Go encoding/json) and international trading partners handle English enums natively. Spanish UI labels belong in the presentation layer only.

**Exception**: Free-text fields (`description`, `notes`, `printable_notes`) may be in Spanish as they are human-facing, not machine-parsed.

### 1.3 GS1 Identifiers Are Mandatory for Products and Locations
| Identifier | Type | Required for |
|---|---|---|
| `gtin` | 13-14 digit string | Any product line item |
| `gln` | 13 digit string | Physical locations (warehouses, stores) |
| `sscc` | 18 digit string | Pallet/shipment containers |

GTIN eliminates ambiguity between products with similar names but different concentrations (e.g., Amoxicilina 250mg vs 500mg). It is a **hard requirement** for pharmaceutical traceability and SICM compliance.

---

## 2. Schema Architecture

### 2.1 $id Namespace
All schemas use the canonical URI namespace:
```
https://schemas.fidex.io/v1/{domain}/{name}
```

Examples:
- `https://schemas.fidex.io/v1/common/party`
- `https://schemas.fidex.io/v1/order/schema`
- `https://schemas.fidex.io/v1/invoice/schema`

### 2.2 Common Schema Reuse via $ref
Shared objects are defined once in `schemas/_common/` and referenced in domain schemas via `$ref`. This is the Single Source of Truth (SSoT) principle:

```json
"parties": {
  "properties": {
    "seller": { "$ref": "https://schemas.fidex.io/v1/common/party" },
    "buyer":  { "$ref": "https://schemas.fidex.io/v1/common/party" }
  }
}
```

**Never duplicate** common object structures across domain schemas. Changes to `party.schema.json` propagate automatically to all 5 domain schemas.

### 2.3 Strict Validation by Default
Domain schemas use `"unevaluatedProperties": false` to prevent undocumented fields from silently passing validation. Every field added to an integration must be defined in the schema first.

---

## 3. Venezuelan Fiscal Architecture

### 3.1 Extensible Object Philosophy
Venezuelan SENIAT requirements are isolated in dedicated nested objects that do NOT break the core GS1/AS5 format:

| Object | Location | Purpose |
|---|---|---|
| `fiscal_control` | `payload` top-level | Talonario digital series, amount in letters, BCV message |
| `fiscal_totals_ves` | `payload.summary` | VES currency totals for SENIAT extraction |
| `retention_details` | `payload` top-level (v1.1) | ISLR/IVA withholding perceiver profiles |

**Principle**: A document without `fiscal_control` is still valid for international B2B. The Venezuelan fields are optional extensions, not core requirements.

### 3.2 Multi-Currency Decoupling
The base of all commercial calculations is **USD**. Bolívares (VES) amounts are always derived by applying the `exchange_rate_applied` (BCV official rate) to the USD base:

```
amount_ves = amount_usd × exchange_rate_applied
```

This prevents decimal rounding mismatches between ERPs when the VES rate fluctuates.

### 3.3 Payment Method Capture
The `applied_payments` array in Order and Invoice supports Venezuelan-specific payment methods:
- `PAGO_MOVIL` — requires `bank_code`, `payer_phone`, `confirmation_number`
- `ZELLE` — requires `confirmation_number`, `sender_email`
- `TRANSFERENCIA` — requires `bank_code`, `account_reference`
- `TARJETA_DEBITO` / `TARJETA_CREDITO` — requires `pos_terminal_id`

---

## 4. State Machine Architecture

### 4.1 Order Lifecycle States
```
DRAFT → PURCHASE_ORDER → QUOTE → ORDER_CONFIRMED → FULFILLED / CANCELLED
```

### 4.2 Catalog Sync States
```
DELTA_UPDATE (normal operation)
    └─ Merkle Root mismatch detected
        └─ FULL_SYNC (baseline reset)
            └─ current_merkle_root verified
                └─ Resume DELTA_UPDATE (sequence_id + 1)
```

### 4.3 Correlation Triangle (Three-Way Match)
Every Invoice and ASN must carry back-references to enable "Three-Way Match":
```
GS1_ORDER_JSON          ← correlation_id: "ORD-2026-9921"
GS1_DESPATCH_ADVICE_JSON ← related_order: "ORD-2026-9921"
GS1_INVOICE_JSON         ← related_order: "ORD-2026-9921"
                           related_asn: "ASN-88421"
```

---

## 5. Validation Funnel (3-Tier)
1. **Tier 1 — Structural**: Valid JSON syntax, correct top-level keys present
2. **Tier 2 — Schema**: `ajv` validates against JSON Schema 2020-12 (types, enums, required fields, patterns)
3. **Tier 3 — Business Logic**: ERP-level validation (SICM permit not expired, GTIN exists in master, credit limit not exceeded)

This repository covers Tiers 1 and 2. Tier 3 is implemented in the FideX Hub and ERP adapters.
