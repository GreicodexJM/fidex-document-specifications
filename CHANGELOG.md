# Changelog

All notable changes to this specification will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [1.1.0] — 2026-03-09

### Added

#### Credit Notes & Debit Notes (`GS1_INVOICE_JSON`)
- `doc_type: "CREDIT_NOTE"` — Nota de Crédito. Reduces a prior invoice for returns, price adjustments, or billing corrections. Requires `related_documents` back-link.
- `doc_type: "DEBIT_NOTE"` — Nota de Débito. Increases a prior invoice for missed charges, price corrections, or additional quantities. Requires `related_documents` back-link.
- Updated `schemas/invoice/gs1-invoice.schema.json` with JSON Schema `if/then` constraint that structurally enforces `related_documents` when `doc_type` is `CREDIT_NOTE` or `DEBIT_NOTE`
- `examples/invoice/03-credit-note.json` — Credit Note for 5 returned boxes of Amoxicilina (IVA-exempt, linked to INV-2026-00145)
- `examples/invoice/04-debit-note.json` — Debit Note for 10 additional units of Alcohol Antiséptico (IVA 16% + IGTF 3%, linked to INV-2026-00146)
- `docs/07-credit-debit-notes.md` — Conceptual guide covering triggers, fiscal math, routing rules, ERP mapping (Odoo/Profit/Saint), and full transaction flow diagrams

#### Tax Retention (`GS1_RETENTION_JSON`)
- `schemas/retention/gs1-retention.schema.json` — New schema for Venezuelan tax withholding documents covering:
  - `RETENTION_IVA`: 75% VAT withholding by Contribuyentes Especiales (SENIAT Providencia 049/056, Form AR-C)
  - `RETENTION_ISLR`: Income tax withholding per Decreto 1808 Tabla 26 (concept codes, rates by payment type)
- `schemas/_common/retention-detail.schema.json` — New common schema for retention line items with full bilingual field documentation
- `examples/retention/01-retention-iva.json` — IVA retention (75%, $18.00 USD / $810.00 VES) by Droguería X on INV-2026-00146
- `examples/retention/02-retention-islr.json` — ISLR retention (1%, Código 1, $1.58 USD / $71.10 VES) by Droguería X on INV-2026-00145
- `docs/08-tax-retention.md` — Conceptual guide covering who must retain, IVA vs. ISLR calculation mechanics, SENIAT compliance (ISENIAT portal, filing deadlines), comprobante as tax credit, and multi-invoice consolidation rules

### Updated
- `Makefile` — Added `validate-retention` target; `validate` now includes all 6 document types
- `README.md` — Updated version badge to v1.1.0; expanded document types table; updated repository structure
- `schemas/_common/kontext-routing.schema.json` — `GS1_RETENTION_JSON` enum value already present from v1.0 planning; confirmed in routing

### Design Decisions
- Credit/Debit Notes reuse `GS1_INVOICE_JSON` (not a new `document_type`) — the AS5 Hub routing for invoice and notes is identical; `doc_type` differentiates at the payload level
- `related_documents` enforcement uses JSON Schema 2020-12 `if/then` instead of application-level validation — aligns with the Tier 2 (Schema) validation principle
- Retention documents use reversed routing direction (`withholder` as `tenant_id`) — the droguería/Agente de Retención is the sender
- `retention_period` (YYYY-MM) is a top-level required field to prevent cross-period mixing of retention lines in a single comprobante
- ISLR `taxable_base_usd` represents the gross payment (not just IVA) — matches Decreto 1808 basis for income withholding

---


## [1.0.0] — 2026-03-09

### Added
- **Core transaction cycle** covering the full Venezuelan B2B order-to-cash flow
- `GS1_CUSTOMER_MASTER_JSON` schema — customer master with SICM health permits and multi-currency financial profiles
- `GS1_CATALOG_JSON` schema — product catalog supporting `DELTA_UPDATE` and `FULL_SYNC` variants with Merkle Root state vector
- `GS1_ORDER_JSON` schema — covers three Venezuelan order states:
  - `PURCHASE_ORDER` ("Orden de Compra") — buyer-initiated request
  - `QUOTE` ("Presupuesto") — vendor's priced response
  - `ORDER_CONFIRMED` ("Orden Confirmada") — buyer confirmation
- `GS1_DESPATCH_ADVICE_JSON` schema — Advance Ship Notice with SSCC packaging, lot/batch tracking, and driver details
- `GS1_INVOICE_JSON` schema — invoice with `fiscal_totals_ves` block for SENIAT multi-currency compliance
- **Common schemas** (`_common/`): `kontext-routing`, `party`, `address`, `product-identity`, `pharma-attributes`, `tax-line`, `fiscal-totals-ves`, `fiscal-control`, `related-documents`
- **Example payloads** for all document types
- **Documentation** (6 conceptual guides covering architecture, routing, security, GS1 identifiers, Venezuelan fiscal requirements, and document lifecycle)
- `Makefile` with `validate`, `validate-one`, `lint`, and `format` targets
- Memory Bank (`memory-bank/`) conforming to GOS project standards

### Design Decisions
- JSON Schema Draft 2020-12 (`https://json-schema.org/draft/2020-12/schema`)
- All machine-readable enums in English; descriptions bilingual (EN/ES)
- `$id` namespace: `https://schemas.fidex.io/v1/`
- Common schemas referenced via URI `$ref` (loaded with `ajv -r`)
