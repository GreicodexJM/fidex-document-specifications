# Active Context — FideX Document Specifications

## Current Version: v1.7.0

---

## Current Focus

**Last completed**: v1.7.0 — `schemas/_common/patterns.schema.json` added (`$id`
`https://schemas.fidex.io/v1/common/patterns`), hosting reusable `$defs` for `rif`, `gln`,
`gtin`, `sicm` extracted verbatim from `party.schema.json`, `product-identity.schema.json`,
`customer-master`, and `jmdn` schemas. Downstream repos can now `$ref` a single `$def` without
inheriting `unevaluatedProperties: false` — the 2020-12 closed-schema extension gap is closed.
`party.schema.json`, `product-identity.schema.json`, `gs1-customer-master.schema.json`, and
`gs1-jmdn.schema.json` refactored to `$ref` the shared defs (pure refactor, no validation
behavior change). `Makefile`'s `validate-jmdn` target updated to load `_common` schemas since
J-MDN now depends on `patterns.schema.json`. SSCC and SHA-256 were investigated but not
extracted — neither pattern is duplicated *across* schema files (SSCC appears once; SHA-256
appears twice but both occurrences are within the single `jmdn` schema). `make validate-all`
stays green: 15 positive ✅ + 8 negative ✅ (unchanged from baseline).

**Next (v1.8.0 candidates)**:
- Logo optimization (`pngquant` — 766K → ~80K)
- `docs/es/00-referencia-rapida.md` — Spanish quick-reference translation
- Revisit SSCC/SHA-256 `$defs` if/when a second schema needs to duplicate those patterns

---

## Recent Changes

| Version | Date | Change |
|---|---|---|
| v1.7.0 | 2026-07-22 | `schemas/_common/patterns.schema.json` — shared `$defs` (RIF, GLN, GTIN, SICM); refactored `party`, `product-identity`, `customer-master`, `jmdn` schemas to `$ref` them |
| v1.6.1 | 2026-03-09 | AI agent tooling: AGENTS.md, llms.txt, GLOSSARY.md, .clinerules, agent cookbook, `examples` on all schemas |
| v1.6.0 | 2026-03-09 | J-MDN schema, Spanish docs 10–12, 8 negative fixtures, quick-reference, logos |
| v1.5.0 | 2026-03-09 | Observer Node spec, DLT anchoring, JSONata maps, negative test suite |
| v1.4.0 | 2026-03-09 | GitHub Actions CI/CD, `ajv-formats`, Spanish docs 01–04, Memory Bank completion |
| v1.3.0 | 2026-03-09 | Spanish documentation layer added (`docs/es/05–09`, `README.es.md`) |
| v1.2.0 | 2026-03-09 | ERP integration mapping guides for Odoo, Profit, Saint, Galac, SAP B1 |
| v1.1.0 | 2026-03-09 | Credit/Debit Notes + IVA/ISLR Tax Retention added |
| v1.0.0 | 2026-03-09 | Initial release — 6 document types, 10 common schemas, full docs |

---

## Active Decisions & Considerations

### Resolved in v1.6 ✅
- `schemas/jmdn/gs1-jmdn.schema.json` with `if/then/else` stage enforcement
- Spanish translations docs 10–12 (EN/ES parity restored)
- 8 negative test fixtures across all 7 schema domains
- `docs/00-quick-reference.md` implementor cheat sheet
- FideX + Greicodex logos in README headers
- GLN pattern normalized to `^[0-9]{13}$` across all schemas
- `npm test` added to `package.json`

### Resolved in v1.7 ✅
- `schemas/_common/patterns.schema.json` — centralized RIF/GLN/GTIN/SICM `$defs`; SSCC/SHA-256
  investigated but left inline (not duplicated across schema files)
- `party`, `product-identity`, `customer-master`, `jmdn` schemas refactored to `$ref` the
  shared `$defs`
- `Makefile` `validate-jmdn` target updated to load `_common` schemas

### Next (v1.8 candidates)
- `docs/es/00-referencia-rapida.md` — Spanish quick-reference translation
- Logo optimization (766K PNG → WebP ~80K)

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
