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

### Infrastructure & Hardening (v1.4.0)
- [x] GitHub Actions CI/CD pipeline (`.github/workflows/validate.yml`)
- [x] `ajv-formats` — `date-time`, `email` format validation active
- [x] ISLR rounding rule (half-up, 2 decimals) in `retention-detail.schema.json`
- [x] `minLength: 1` on all required string fields (6 schemas in v1.4; 4 more in v1.5)
- [x] Spanish translations `docs/es/01–04` (overview, routing, security, GS1)
- [x] Memory Bank files (`activeContext.md`, `progress.md`, `techContext.md`)
- [x] `validate-one` `./` prefix path normalization
- [x] `package.json` version sync + README badge sync

### Protocol Integration Specs & Test Hardening (v1.5.0)
- [x] `docs/10-government-observer-node.md` — Observer Node spec, re-encryption flow, Tax Manifest
- [x] `docs/11-dlt-merkle-anchoring.md` — Two-stage J-MDN, hourly Merkle rollup, Solidity interface
- [x] `docs/12-jsonata-maps.md` — JSONata maps reference, Hub→ERP routing, `$env` context
- [x] `gs1-order.schema.json` — `if/then` enforcement for QUOTE/ORDER_CONFIRMED back-references
- [x] `minLength: 1` added to catalog, customer-master, despatch-advice, product-identity
- [x] `examples/_invalid/` — negative test suite (3 fixtures)
- [x] `make validate-negative` — inverted exit-code validation target
- [x] `make validate-all` — full suite (positive + negative)
- [x] GitHub Actions CI — added separate `validate-negative` step


### AI Agent Tooling (v1.6.1)
- [x] `AGENTS.md` — universal agent entry point (what repo is, first steps, DO/DON'T rules, 5-step recipe, validation mechanics)
- [x] `llms.txt` — machine-readable repo index (schema map, example map, key relationships)
- [x] `GLOSSARY.md` — Venezuelan pharmaceutical and fiscal term definitions (RIF, GTIN, GLN, IVA, IGTF, ISLR, SICM, BCV, talonario, etc.)
- [x] `.clinerules` — project-level agent rules (schema authoring rules, file conventions, architecture constraints, validation mechanics)
- [x] `docs/13-agent-cookbook.md` — 7 task recipes (new document type, new field, negative test, debug failure, ERP mapping, version release, examples audit)
- [x] `examples` arrays added to all 12 schemas: 5 `_common` (kontext-routing, address, tax-line, related-documents, pharma-attributes) + 7 domain (order, invoice, customer-master, catalog, despatch-advice, retention, jmdn)
- [x] `make validate-all` stays green: 15 positive ✅ + 8 negative ✅

### J-MDN, Quick Reference & Hardening (v1.6.0)
- [x] `schemas/jmdn/gs1-jmdn.schema.json` — J-MDN receipt schema with `if/then/else`
- [x] `examples/jmdn/01-technical-receipt.json` + `02-fiscal-receipt.json`
- [x] `docs/es/10-nodo-observador-gubernamental.md` — Spanish Observer Node
- [x] `docs/es/11-anclaje-dlt-merkle.md` — Spanish DLT/Merkle anchoring
- [x] `docs/es/12-mapas-jsonata.md` — Spanish JSONata maps reference
- [x] `docs/00-quick-reference.md` — implementor cheat sheet
- [x] `docs/assets/fidex-as5-logo.png` + README hero headers (FideX + Greicodex)
- [x] Negative test suite expanded to 8 fixtures (customer-master + catalog added)
- [x] `examples/_invalid/README.md` test matrix updated (all 8 fixtures, domain coverage table)
- [x] `package.json` — `npm test` script added (`make validate-all`)
- [x] GLN pattern normalized to `^[0-9]{13}$` in J-MDN schema
- [x] `make validate-all` passes: 15 positive ✅ + 8 negative ✅

### Toolchain
- [x] `Makefile` with `validate`, `validate-one`, `validate-negative`, `validate-all`, `lint`, `format`, `check-deps`
- [x] `package.json` with `ajv-cli` + `prettier` + `ajv-formats`
- [x] `.prettierrc` formatting rules
- [x] `make validate-all` passes: 15 positive ✅ + 8 negative ✅

---

## What's Left to Build ❌


### v2.0.0 (Future Scope — Out of Current Spec)
- [ ] Transport Protocol (see `greicodex/fidex-protocol`)
- [ ] ERP-specific adapter code (see `greicodex/fidex-odoo`)
- [ ] SICM permit validation API integration spec
- [ ] Multi-currency catalog (VES + USD + EUR)

---

## Current Status

**Repository**: Stable — 15 positive examples + 8 negative examples all pass `make validate-all`. AI agent tooling in place.
**Documentation**: Complete for EN docs 01–12; ES docs 01–09 (10–12 pending)
**CI/CD**: GitHub Actions runs `validate` + `validate-negative` + `lint` on every push to main/develop
**Format validation**: ENABLED — `ajv-formats` installed, `-c ajv-formats` in Makefile

---

## Known Issues

No open issues as of v1.5.0.

| Issue | Status |
|---|---|
| `date-time` format not validated | ✅ Fixed — `ajv-formats` enabled in v1.4 |
| ISLR rounding rule unspecified | ✅ Fixed — half-up rule in `retention-detail.schema.json` v1.4 |
| Spanish docs 01–04 missing | ✅ Fixed — all 4 translated in v1.4 |
| `validate-one` `./` prefix path | ✅ Fixed — `patsubst ./%,%` normalization in v1.4 |
| Order schema no `if/then` | ✅ Fixed — QUOTE/ORDER_CONFIRMED enforcement added in v1.5 |
| CI only ran positive tests | ✅ Fixed — `validate-negative` step added to GitHub Actions in v1.5 |
| Spanish docs 10–12 missing | 🔴 Open — added in v1.5, Spanish translation pending v1.6 |
| J-MDN has no JSON Schema | 🔴 Open — referenced in docs/03 + docs/11, schema pending v1.6 |

---

## Evolution of Key Decisions

| Decision | Original | Evolution |
|---|---|---|
| Schema validation draft | Initially considered draft-07 | Upgraded to 2020-12 for `unevaluatedProperties` support |
| Credit/Debit Note routing | Considered separate `document_type` | Kept under `GS1_INVOICE_JSON` — AS5 routing identical; `doc_type` differentiates |
| Venezuelan fiscal fields | Initially required on all invoices | Made optional — keeps format internationally viable |
| ISLR retention scope | One retention per invoice | Allows multi-invoice consolidation within same fiscal period |
| Negative tests location | Could have been inline `not:` in schemas | Separate `examples/_invalid/` is more readable and discoverable |
| CI validation | Only positive tests | v1.5: split into `validate` + `validate-negative` steps for clearer failure diagnosis |
