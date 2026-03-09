# Active Context — FideX Document Specifications

## Current Version: v1.4.0

---

## Current Focus

**Last completed**: v1.4.0 — Infrastructure hardening + documentation completeness. GitHub Actions CI/CD, `ajv-formats` format validation, `minLength` schema hardening, Spanish docs 01–04, Memory Bank completion, ISLR rounding rule.

**In progress (v1.5.0)**:
- Government Observer Node integration specification
- JSONata transformation map reference (Hub → ERP)
- DLT / Merkle anchoring protocol spec

**Next planned milestone (v1.5.0)**:
- Government Observer Node integration specification
- JSONata transformation map reference (Hub → ERP)
- DLT / Merkle anchoring protocol spec

---

## Recent Changes

| Version | Date | Change |
|---|---|---|
| v1.3.0 | 2026-03-09 | Spanish documentation layer added (`docs/es/05–09`, `README.es.md`) |
| v1.2.0 | 2026-03-09 | ERP integration mapping guides for Odoo, Profit, Saint, Galac, SAP B1 |
| v1.1.0 | 2026-03-09 | Credit/Debit Notes + IVA/ISLR Tax Retention added |
| v1.0.0 | 2026-03-09 | Initial release — 6 document types, 10 common schemas, full docs |

---

## Active Decisions & Considerations

### Next: Government Observer Node Spec (v1.5)
- Need to specify the JSONata extraction pattern for `fiscal_totals_ves`
- Define the re-encryption flow: invoice JWE → extract `fiscal_totals_ves` → re-encrypt with SENIAT pubkey
- Spec the Observer ACK format

### Next: JSONata Transformation Maps (v1.5)
- Hub needs map files for each `document_type` → ERP adapter translation
- Pattern: `schemas/{domain}/gs1-{domain}.jsonata` or separate `maps/` directory

### Resolved in v1.4 ✅
- `ajv-formats` installed and enabled — `date-time` format validation active
- ISLR rounding rule specified in `retention-detail.schema.json` (half-up, 2 decimals)
- Spanish docs 01–04 created
- `validate-one` `./` prefix fixed

---

## Important Patterns & Preferences

1. **All enum values in English** — never add Spanish enum values even for Venezuelan-specific fields
2. **`unevaluatedProperties: false`** on all domain schemas — strict by default, prevents undocumented fields
3. **`$ref` via URI** (`https://schemas.fidex.io/v1/common/...`) — ajv loads all common schemas with `-r` flag
4. **Bilingual descriptions** — every `description` field ends with ` / ` and Spanish translation
5. **Version badge in README** — must match `package.json` version and latest CHANGELOG entry
6. **Fiscal isolation** — Venezuelan fields (`fiscal_totals_ves`, `fiscal_control`) always optional; document valid without them

---

## Learnings & Insights

- The `if/then` approach in invoice schema for `related_documents` enforcement works well but requires `--strict=false` in ajv due to `allOf` sub-schema type inference
- `unevaluatedProperties: false` on the root level document correctly rejects undeclared root-level keys
- The `DOMAIN` extraction heuristic in `validate-one` is sufficient for all standard `examples/{domain}/` paths but fails on `./` prefixed paths — fixed with `patsubst`
- `retention_period` as a required YYYY-MM field is a SENIAT compliance requirement — never make it optional
