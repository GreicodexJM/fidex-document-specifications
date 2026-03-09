# Agentic Workflow — FideX Document Specifications

## Current Status: v1.5.0 — COMPLETE

---

## Active Context

**Last Action**: v1.5.0 implemented — Government Observer Node spec (`docs/10`), DLT/Merkle anchoring protocol (`docs/11`), JSONata transformation maps reference (`docs/12`), negative test suite (`examples/_invalid/`), `if/then` enforcement on order schema for QUOTE/ORDER_CONFIRMED, `minLength: 1` on 4 more schemas, `make validate-negative` + `make validate-all`.

**Current Focus**: Specification stable. EN docs 01–12 complete. ES docs 01–09 complete (10–12 pending). All 13 positive + 3 negative examples pass `make validate-all`.

**Next Milestone**: v1.6.0 — J-MDN JSON Schema (`schemas/jmdn/`), Spanish translations for docs 10–12, README structure tree sync.

---

## How to Contribute a New Document Type

Follow the SPARC methodology (Specification → Pseudocode → Architecture → Refinement → Completion):

### Step 1 — Specification
Define the document's purpose, triggers, and fields in `docs/`. Create a new doc file like `docs/07-credit-debit-notes.md` covering:
- Business context (when is this document sent?)
- Fields required by GS1 standard
- Venezuelan fiscal extensions needed (if any)
- Relationship to other documents

### Step 2 — Schema Design
Create `schemas/_common/` objects for any new reusable components.
Then create `schemas/{domain}/gs1-{domain}.schema.json`.

Follow this template:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://schemas.fidex.io/v1/{domain}/schema",
  "title": "...",
  "description": "... / ...",
  "type": "object",
  "required": ["kontext_routing", "payload"],
  "properties": {
    "kontext_routing": {
      "allOf": [
        { "$ref": "https://schemas.fidex.io/v1/common/kontext-routing" },
        { "properties": { "document_type": { "const": "GS1_XXX_JSON" } } }
      ]
    },
    "payload": { ... }
  },
  "unevaluatedProperties": false
}
```

### Step 3 — Examples
Write at least one valid example in `examples/{domain}/01-{scenario}.json`.
Run `make validate-one FILE=examples/{domain}/01-{scenario}.json` to confirm it passes.

### Step 4 — Update Registry
- Add the new `document_type` enum to `schemas/_common/kontext-routing.schema.json`
- Update the document table in `README.md`
- Add an entry to `CHANGELOG.md` under `[Unreleased]`
- Add validation target to `Makefile`

### Step 5 — PR & Review
Open a Pull Request with all four artifacts (doc, schema, example, registry updates) together.

---

## Known Issues / Technical Debt

Two open items as of v1.5.0:

| Issue | Status | Target |
|---|---|---|
| Spanish docs 10–12 missing | 🔴 Open | v1.6 |
| J-MDN has no JSON Schema | 🔴 Open | v1.6 |

**All Previously Resolved:**
| Issue | Resolution |
|---|---|
| `validate-one` Makefile `./`-prefix path bug | ✅ Fixed v1.4 — `patsubst ./%,%` normalization |
| No CI/CD pipeline | ✅ Fixed v1.4 — GitHub Actions `.github/workflows/validate.yml` |
| ISLR rounding rule unspecified | ✅ Fixed v1.4 — half-up 2 decimals in `retention-detail.schema.json` |
| Spanish docs 01–04 missing | ✅ Fixed v1.4 — all 4 docs created in `docs/es/` |
| CI ran positive tests only | ✅ Fixed v1.5 — `validate-negative` step added to GitHub Actions |
| Order schema missing `if/then` enforcement | ✅ Fixed v1.5 — QUOTE/ORDER_CONFIRMED constraints added |
| `_comment` root key known issue | ✅ Removed v1.4 — was a stale erroneous entry |
| `docs/erp-mapping/` placeholder not written | ✅ Fixed v1.2 — all 5 ERP guides written |

---

## Decision Log

| Date | Decision | Rationale |
|---|---|---|
| 2026-03-09 | Use JSON Schema 2020-12 | Latest standard, best `$ref` and `unevaluatedProperties` support |
| 2026-03-09 | Separate `kontext_routing` envelope | AS5 Separation of Concerns — hub never reads payload |
| 2026-03-09 | English enums only | Machine interoperability with international libraries |
| 2026-03-09 | Three order doc_types (PO/QUOTE/CONFIRMED) | Venezuelan workflow requires presupuesto step before confirmation |
| 2026-03-09 | `fiscal_totals_ves` as optional nested object | Keeps core format internationally viable; SENIAT fields are extensions |
| 2026-03-09 | URI-based $ref with ajv -r flag | DRY principle — common schemas defined once, loaded by ajv at validation time |
| 2026-03-09 | Credit/Debit Notes reuse `GS1_INVOICE_JSON` document_type | AS5 Hub routing for invoice/notes is identical; `doc_type` differentiates at payload level |
| 2026-03-09 | `if/then` in invoice schema for related_documents | Tier 2 (Schema) validation — structural enforcement over application-level checks |
| 2026-03-09 | `GS1_RETENTION_JSON` separate document_type | Retention is a different routing concern: reversed direction (droguería→lab), different SENIAT hook |
| 2026-03-09 | `retention_period` YYYY-MM as required field | Prevents cross-period consolidation errors; SENIAT requires period-accurate comprobanets |
| 2026-03-09 | Order `if/then` mirrors invoice pattern | QUOTE/ORDER_CONFIRMED back-reference enforcement — same approach as invoice CREDIT_NOTE in v1.1 |
| 2026-03-09 | Negative tests in `examples/_invalid/` (not inline `not:`) | More readable, discoverable, and closer to real-world invalid payloads than inline schema negation |
| 2026-03-09 | CI split into `validate` + `validate-negative` steps | Separate steps give clearer failure diagnosis in GitHub Actions dashboard |
