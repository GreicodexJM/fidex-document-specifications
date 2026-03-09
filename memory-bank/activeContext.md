# Active Context — FideX Document Specifications

## Current Version: v1.5.0

---

## Current Focus

**Last completed**: v1.5.0 — Government Observer Node spec, DLT/Merkle anchoring protocol spec, JSONata transformation maps reference, negative test suite (`examples/_invalid/`), `make validate-negative` + `make validate-all` Makefile targets, `if/then` enforcement on order schema for QUOTE/ORDER_CONFIRMED.

**In progress (v1.6.0)**:
- J-MDN schema (`schemas/jmdn/gs1-jmdn.schema.json`) — machine-readable contract for Technical + Fiscal receipts
- Spanish translations for docs 10–12
- README structure tree sync

---

## Recent Changes

| Version | Date | Change |
|---|---|---|
| v1.5.0 | 2026-03-09 | Observer Node spec, DLT anchoring, JSONata maps, negative test suite |
| v1.4.0 | 2026-03-09 | GitHub Actions CI/CD, `ajv-formats`, Spanish docs 01–04, Memory Bank completion |
| v1.3.0 | 2026-03-09 | Spanish documentation layer added (`docs/es/05–09`, `README.es.md`) |
| v1.2.0 | 2026-03-09 | ERP integration mapping guides for Odoo, Profit, Saint, Galac, SAP B1 |
| v1.1.0 | 2026-03-09 | Credit/Debit Notes + IVA/ISLR Tax Retention added |
| v1.0.0 | 2026-03-09 | Initial release — 6 document types, 10 common schemas, full docs |

---

## Active Decisions & Considerations

### Next: J-MDN Schema (v1.6)
- `NETWORK_DELIVERED` (Technical J-MDN) and `FISCAL_CLEARED` (Fiscal J-MDN) are specified in `docs/03` and `docs/11` but have no JSON Schema
- Implementors need a machine-readable contract for the receipt format
- Suggest: `schemas/jmdn/gs1-jmdn.schema.json` with `if/then` enforcement (Fiscal J-MDN requires `merkle_proof`)

### Next: Spanish Docs 10–12 (v1.6)
- `docs/es/10-nodo-observador-gubernamental.md`
- `docs/es/11-anclaje-dlt-merkle.md`
- `docs/es/12-mapas-jsonata.md`
- EN/ES parity is a project invariant — broken by v1.5.0 additions

### Resolved in v1.5 ✅
- `gs1-order.schema.json` `if/then` enforcement for QUOTE/ORDER_CONFIRMED
- `minLength: 1` on remaining required string fields (catalog, customer-master, despatch-advice, product-identity)
- Government Observer Node spec (`docs/10`)
- DLT/Merkle anchoring protocol (`docs/11`)
- JSONata transformation maps reference (`docs/12`)
- Negative test suite (`examples/_invalid/`, `make validate-negative`, `make validate-all`)

---

## Important Patterns & Preferences

1. **All enum values in English** — never add Spanish enum values even for Venezuelan-specific fields
2. **`unevaluatedProperties: false`** on all domain schemas — strict by default, prevents undocumented fields
3. **`$ref` via URI** (`https://schemas.fidex.io/v1/common/...`) — ajv loads all common schemas with `-r` flag
4. **Bilingual descriptions** — every `description` field ends with ` / ` and Spanish translation
5. **Version badge in README** — must match `package.json` version and latest CHANGELOG entry
6. **Fiscal isolation** — Venezuelan fields (`fiscal_totals_ves`, `fiscal_control`) always optional; document valid without them
7. **EN/ES parity** — every new English doc in `docs/` must have a Spanish counterpart in `docs/es/`

---

## Learnings & Insights

- The `if/then` approach works well in both invoice and order schemas; requires `--strict=false` in ajv due to `allOf` sub-schema type inference
- `unevaluatedProperties: false` on the root level document correctly rejects undeclared root-level keys
- The `DOMAIN` extraction heuristic in `validate-one` is sufficient for all standard `examples/{domain}/` paths but fails on `./` prefixed paths — fixed with `patsubst`
- `retention_period` as a required YYYY-MM field is a SENIAT compliance requirement — never make it optional
- Negative test examples in `examples/_invalid/` must be structurally valid JSON but semantically invalid — they confirm the schema rules work as intended
- The `validate-negative` Makefile target uses inverted exit-code logic: ajv exit 0 (valid) = test failure; ajv exit 1 (invalid) = test pass
