# FideX AS5 — Quick Reference Card

> One-page implementor cheat sheet. Version **v1.6.0**.  
> 🇪🇸 [Versión en español](es/00-referencia-rapida.md)

---

## Document Types (`document_type` enum)

| `document_type` | Schema | `doc_type` / `retention_type` values |
|---|---|---|
| `GS1_CUSTOMER_MASTER_JSON` | `gs1-customer-master.schema.json` | — |
| `GS1_CATALOG_JSON` | `gs1-catalog.schema.json` | `DELTA_UPDATE`, `FULL_SYNC`, `MASTER_UPDATE` |
| `GS1_ORDER_JSON` | `gs1-order.schema.json` | `PURCHASE_ORDER`, `QUOTE`, `ORDER_CONFIRMED` |
| `GS1_DESPATCH_ADVICE_JSON` | `gs1-despatch-advice.schema.json` | `DESPATCH_ADVICE` |
| `GS1_INVOICE_JSON` | `gs1-invoice.schema.json` | `INVOICE`, `CREDIT_NOTE`, `DEBIT_NOTE` |
| `GS1_RETENTION_JSON` | `gs1-retention.schema.json` | `RETENTION_IVA`, `RETENTION_ISLR` |
| *(receipt)* | `gs1-jmdn.schema.json` | `NETWORK_DELIVERED`, `FISCAL_CLEARED` |

---

## Schema `$id` URLs

| Schema | `$id` |
|---|---|
| customer-master | `https://schemas.fidex.io/v1/customer-master/schema` |
| catalog | `https://schemas.fidex.io/v1/catalog/schema` |
| order | `https://schemas.fidex.io/v1/order/schema` |
| despatch-advice | `https://schemas.fidex.io/v1/despatch-advice/schema` |
| invoice | `https://schemas.fidex.io/v1/invoice/schema` |
| retention | `https://schemas.fidex.io/v1/retention/schema` |
| J-MDN | `https://schemas.fidex.io/v1/jmdn/schema` |

---

## Key Field Patterns (Regex)

| Field | Pattern | Example |
|---|---|---|
| GLN (13 digits) | `^[0-9]{13}$` | `7590000000001` |
| GTIN-13 or GTIN-14 | `^[0-9]{13,14}$` | `07591234567890` |
| SSCC (18 digits) | `^[0-9]{18}$` | `175912345678901234` |
| RIF (Venezuela) | `^[JVEGPjvegp]-[0-9]{8}-[0-9]$` | `J-12345678-9` |
| SICM permit | `^S-[0-9]+$` | `S-98765` |
| Retention period | `^[0-9]{4}-(0[1-9]\|1[0-2])$` | `2026-03` |
| SHA-256 hash | `^[0-9a-f]{64}$` | `a3f1b9c8...` |
| ISO 3166-1 alpha-2 | `^[A-Z]{2}$` | `VE` |

---

## Envelope Structure

Every domain document (except J-MDN) wraps in `kontext_routing` + `payload`:

```json
{
  "kontext_routing": {
    "spec_version": "1.0",
    "message_id": "MSG-<timestamp>-<seq>",
    "timestamp": "2026-03-09T14:30:00Z",
    "tenant_id": "leti-ve",
    "receiver_id": "drogueria-xyz",
    "document_type": "GS1_INVOICE_JSON",
    "correlation_id": "ORD-2026-9921"
  },
  "payload": { ... }
}
```

J-MDN receipts are **flat** (no envelope wrapper) — see `schemas/jmdn/gs1-jmdn.schema.json`.

---

## Venezuelan Fiscal Extension Fields

These fields are **optional** in all schemas. Documents without them are globally valid.

| Field | Schema | Purpose |
|---|---|---|
| `fiscal_control` | `_common/fiscal-control.schema.json` | Machine serial, fiscal control number |
| `fiscal_totals_ves` | `_common/fiscal-totals-ves.schema.json` | IVA, IGTF, ISLR totals in VES + BCV rate |
| `retention_period` | `_common/retention-detail.schema.json` | YYYY-MM retention period (SENIAT) |
| `tax_id` (RIF) | domain schemas | Venezuelan taxpayer ID |
| `sicm` | `_common/party.schema.json` | SUDEBAN pharmaceutical distributor permit |

---

## `make` Command Reference

| Command | What it does |
|---|---|
| `make install` | Install npm deps (`ajv-cli`, `prettier`) |
| `make validate` | Validate all 15 positive examples |
| `make validate-negative` | Run 8 negative fixtures (must-fail) |
| `make validate-all` | Both positive + negative (`npm test`) |
| `make validate-jmdn` | Validate J-MDN receipts only |
| `make validate-one FILE=...` | Validate a single file |
| `make lint` | Check JSON formatting (Prettier) |
| `make format` | Auto-format all JSON files |
| `make list-schemas` | List all schema files |
| `make list-examples` | List all example files |
| `make check-deps` | Verify node, ajv-cli, prettier versions |

---

## J-MDN Two-Stage Receipt Flow

```
Sender ──[JWE]──► Hub ──[JWE]──► Receiver
          │                          │
          │◄── Technical J-MDN ◄─────┤  status: NETWORK_DELIVERED  (< 2 s)
          │    received_at, hash      │
          │                          │
          │◄── Fiscal J-MDN ─────────┤  status: FISCAL_CLEARED  (< 61 min)
               cleared_at            │
               merkle_proof {...}     │
               observer_registration_id
```

**Rule**: Sender cannot demand payment without a `FISCAL_CLEARED` J-MDN.

---

## Document Lifecycle States

| Document | Status progression |
|---|---|
| Order | `DRAFT` → `PENDING` → `CONFIRMED` → `SHIPPED` → `CLOSED` |
| Invoice | `PENDING` → `APPROVED` → `CANCELLED` |
| Retention | `PENDING` → `ISSUED` → `DELIVERED` |
| Catalog | `DRAFT` → `ACTIVE` → `ARCHIVED` |
| J-MDN | `NETWORK_DELIVERED` → `FISCAL_CLEARED` |

---

## Key Design Rules

1. **`unevaluatedProperties: false`** on all domain schemas — extra fields are rejected
2. **All `required` string fields have `minLength: 1`** — empty strings are rejected
3. **`if/then` enforcement** — CREDIT_NOTE must have `related_documents`; ORDER_CONFIRMED must back-reference a QUOTE; FISCAL_CLEARED J-MDN must have `merkle_proof`
4. **Bilingual descriptions** — every JSON Schema `description` has `/ ` Spanish translation
5. **Fiscal fields are optional** — `fiscal_totals_ves` absence is valid (international documents)
6. **All enum values in English** — never Spanish enum values

---

## Documentation Index

| # | English | Español |
|---|---|---|
| 01 | [Overview](01-overview.md) | [Descripción General](es/01-descripcion-general.md) |
| 02 | [Routing Envelope](02-routing-envelope.md) | [Sobre de Enrutamiento](es/02-sobre-de-enrutamiento.md) |
| 03 | [Security / JOSE](03-security-jose.md) | [Seguridad JOSE](es/03-seguridad-jose.md) |
| 04 | [GS1 Identifiers](04-gs1-identifiers.md) | [Identificadores GS1](es/04-identificadores-gs1.md) |
| 05 | [Venezuelan Fiscal](05-venezuelan-fiscal.md) | [Fiscal Venezolano](es/05-fiscal-venezolano.md) |
| 06 | [Document Lifecycle](06-document-lifecycle.md) | [Ciclo de Documentos](es/06-ciclo-de-documentos.md) |
| 07 | [Credit/Debit Notes](07-credit-debit-notes.md) | [Notas Crédito/Débito](es/07-notas-credito-debito.md) |
| 08 | [Tax Retention](08-tax-retention.md) | [Retenciones Fiscales](es/08-retenciones-fiscales.md) |
| 09 | [ERP Mapping](09-erp-mapping/00-index.md) | [Integración ERP](es/09-integracion-erp/00-indice.md) |
| 10 | [Observer Node](10-government-observer-node.md) | [Nodo Observador](es/10-nodo-observador-gubernamental.md) |
| 11 | [DLT / Merkle](11-dlt-merkle-anchoring.md) | [Anclaje DLT/Merkle](es/11-anclaje-dlt-merkle.md) |
| 12 | [JSONata Maps](12-jsonata-maps.md) | [Mapas JSONata](es/12-mapas-jsonata.md) |
