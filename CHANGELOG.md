# Changelog

All notable changes to this specification will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned (v1.1.0)
- `GS1_INVOICE_JSON`: Add `CREDIT_NOTE` and `DEBIT_NOTE` doc_types with `related_documents` back-linking
- `GS1_RETENTION_JSON`: New schema for Venezuelan IVA and ISLR tax withholding documents
- `schemas/_common/retention-detail.schema.json`: Perceiver profiles and concept codes

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
