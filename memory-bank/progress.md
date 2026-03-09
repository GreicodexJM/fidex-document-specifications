# Progress — FideX Document Specifications

## What Works ✅

### Core Specification (v1.0.0)
- [x] `GS1_CUSTOMER_MASTER_JSON` — schema + example + docs
- [x] `GS1_CATALOG_JSON` (DELTA_UPDATE + FULL_SYNC) — schema + 2 examples + docs
- [x] `GS1_ORDER_JSON` (PURCHASE_ORDER / QUOTE / ORDER_CONFIRMED) — schema + 3 examples + docs
- [x] `GS1_DESPATCH_ADVICE_JSON` — schema + example + docs
- [x] `GS1_INVOICE_JSON` (INVOICE) — schema + 2 examples + docs

### Fiscal Cycle Extension (v1.1.0)
- [x] `GS1_INVOICE_JSON` (CREDIT_NOTE) — schema (`if/then` enforcement) + example
- [x] `GS1_INVOICE_JSON` (DEBIT_NOTE) — schema + example
- [x] `GS1_RETENTION_JSON` (RETENTION_IVA) — schema + example
- [x] `GS1_RETENTION_JSON` (RETENTION_ISLR) — schema + example
- [x] `retention-detail.schema.json` common schema

### ERP Integration Guides (v1.2.0)
- [x] `docs/09-erp-mapping/00-index.md` — ERP comparison matrix
- [x] `docs/09-erp-mapping/01-odoo-17-18.md` — Odoo 17/18
- [x] `docs/09-erp-mapping/02-profit.md` — Profit Plus v12
- [x] `docs/09-erp-mapping/03-saint.md` — Saint Enterprise v6+
- [x] `docs/09-erp-mapping/04-galac.md` — Galac Software v5+
- [x] `docs/09-erp-mapping/05-sap-business-one.md` — SAP Business One 10.0

### Spanish Documentation (v1.3.0)
- [x] `docs/es/05-fiscal-venezolano.md`
- [x] `docs/es/06-ciclo-de-documentos.md`
- [x] `docs/es/07-notas-credito-debito.md`
- [x] `docs/es/08-retenciones-fiscales.md`
- [x] `docs/es/09-integracion-erp/` (all 5 ERPs)
- [x] `README.es.md`

### Toolchain
- [x] `Makefile` with `validate`, `validate-one`, `lint`, `format`, `check-deps`
- [x] `package.json` with `ajv-cli` + `prettier`
- [x] `.prettierrc` formatting rules
- [x] `make validate` passes all 16 examples

---

### Infrastructure & Hardening (v1.4.0)
- [x] GitHub Actions CI/CD pipeline (`.github/workflows/validate.yml`)
- [x] `ajv-formats` — `date-time`, `email` format validation active
- [x] ISLR rounding rule (half-up, 2 decimals) in `retention-detail.schema.json`
- [x] `minLength: 1` on all required string fields (6 schemas updated)
- [x] Spanish translations `docs/es/01–04` (overview, routing, security, GS1)
- [x] Memory Bank files (`activeContext.md`, `progress.md`, `techContext.md`)
- [x] `validate-one` `./` prefix path normalization
- [x] `package.json` version sync + README badge sync
- [x] Stale known-issue entries cleared from `03_AGENTIC_WORKFLOW.md`
- [x] All 29 JSON files formatted with prettier

## What's Left to Build ❌

### v1.5.0 (Protocol Integration)
- [ ] Government Observer Node integration spec
- [ ] JSONata transformation map reference for Hub → ERP routing
- [ ] DLT / Merkle Root anchoring protocol specification
- [ ] `greicodex/fidex-hub` schema integration tests

### v2.0.0 (Future Scope — Out of Current Spec)
- [ ] Transport Protocol (see `greicodex/fidex-protocol`)
- [ ] ERP-specific adapter code (see `greicodex/fidex-odoo`)
- [ ] SICM permit validation API integration spec
- [ ] Multi-currency catalog (VES + USD + EUR)

---

## Current Status

**Repository**: Stable — all 13 examples passing `make validate` + `make lint`
**Documentation**: Complete for EN docs 01–09; ES docs 01–09 now fully translated
**CI/CD**: GitHub Actions pipeline active (`.github/workflows/validate.yml`)
**Format validation**: ENABLED — `ajv-formats` installed, `-c ajv-formats` in Makefile

---

## Known Issues

No open issues as of v1.4.0. All previous items resolved:

| Issue | Status |
|---|---|
| `date-time` format not validated | ✅ Fixed — `ajv-formats` enabled in v1.4 |
| ISLR rounding rule unspecified | ✅ Fixed — half-up rule documented in `retention-detail.schema.json` |
| Spanish docs 01–04 missing | ✅ Fixed — all 4 translated in v1.4 |
| `validate-one` `./` prefix path | ✅ Fixed — `patsubst ./%,%` normalization in Makefile |

---

## Evolution of Key Decisions

| Decision | Original | Evolution |
|---|---|---|
| Schema validation draft | Initially considered draft-07 | Upgraded to 2020-12 for `unevaluatedProperties` support |
| Credit/Debit Note routing | Considered separate `document_type` | Kept under `GS1_INVOICE_JSON` — AS5 routing identical; `doc_type` differentiates |
| Venezuelan fiscal fields | Initially required on all invoices | Made optional — keeps format internationally viable |
| ISLR retention scope | One retention per invoice | Allows multi-invoice consolidation within same fiscal period |
