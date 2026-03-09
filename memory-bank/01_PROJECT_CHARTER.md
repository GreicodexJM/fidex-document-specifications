# Project Charter — FideX Document Specifications

## Project Identity

| Field | Value |
|---|---|
| **Repository** | `greicodex/fidex-document-specs` |
| **Version** | v1.0.0 |
| **Protocol** | AS5 / FideX |
| **Industry** | Pharmaceutical — Venezuela & LATAM |
| **Schema Standard** | JSON Schema 2020-12 |

---

## Problem Statement

The Venezuelan pharmaceutical supply chain (Laboratorios → Droguerías → Farmacias) currently operates on fragmented, legacy EDI formats (CSV over SFTP, AS2 with XML) that:
1. Lack machine-readable, programmable structure for modern ERP integration (Odoo, Profit, Saint)
2. Have no standardized way to capture Venezuelan fiscal requirements (SENIAT IVA/IGTF, SICM health permits)
3. Cannot bridge private B2B commerce with government transaction control (SENIAT/SUDEBAN visibility)
4. Fail to support Venezuelan payment methods (PagoMóvil, Zelle, multi-currency VES/USD)

---

## Solution

A **canonical JSON payload specification** repository that:

- Defines the exact structure of every B2B document exchanged over the FideX AS5 protocol
- Provides **JSON Schema 2020-12** definitions for machine validation (zero-ambiguity)
- Provides **example payloads** that pass validation as integration test fixtures
- Bridges GS1 international standards with Venezuelan fiscal and pharmaceutical regulations
- Serves as shared documentation between trading partners, ERP integrators, and the FideX Hub

---

## Scope (v1.0 — Core Transaction Cycle)

### In Scope
- Customer Master Data (`GS1_CUSTOMER_MASTER_JSON`)
- Product Catalog / Pricelist (`GS1_CATALOG_JSON`) — DELTA_UPDATE and FULL_SYNC
- Order lifecycle (`GS1_ORDER_JSON`):
  - `PURCHASE_ORDER` — "Orden de Compra" (buyer initiates)
  - `QUOTE` — "Presupuesto" (vendor responds)
  - `ORDER_CONFIRMED` — "Orden Confirmada" (buyer confirms)
- Advance Ship Notice (`GS1_DESPATCH_ADVICE_JSON`)
- Invoice / Factura (`GS1_INVOICE_JSON`)

### Out of Scope (v1.1)
- Credit/Debit Notes
- Tax Retention documents (IVA / ISLR)
- Transport Protocol (see `greicodex/fidex-protocol`)
- ERP-specific adapters (see `greicodex/fidex-odoo`)

---

## Primary Stakeholders

| Role | Organization | Interest |
|---|---|---|
| Payload Author | Greicodex / Kontext Systems | Defines & maintains the standard |
| Sender | Laboratorios (e.g., Leti) | Emits GS1_ORDER_JSON, GS1_INVOICE_JSON |
| Receiver | Droguerías / Farmacias | Consumes and validates against schemas |
| ERP Integrators | Odoo, Profit, Saint partners | Maps fields to ERP data models |
| Fiscal Authority | SENIAT (via Government Observer) | Consumes `fiscal_totals_ves` block |

---

## Success Criteria

1. All example payloads in `examples/` pass `make validate` without errors
2. Every field in every schema has a meaningful `description` (bilingual EN/ES)
3. The lifecycle documented in `docs/06-document-lifecycle.md` is fully covered by examples
4. A new trading partner integration can be completed using only this repo's docs + examples
