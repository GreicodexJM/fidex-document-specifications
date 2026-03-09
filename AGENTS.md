# AGENTS.md — FideX Document Specifications

> **For any AI coding agent** (Cline, Claude Code, GitHub Copilot, Cursor, OpenAI Codex, Gemini CLI, etc.).  
> Read this file before touching any file in this repository.

---

## What Is This Repository?

This is the **canonical specification** for JSON payloads exchanged over the FideX AS5 pharmaceutical B2B protocol in Venezuela. It contains:

- **JSON Schema 2020-12** definitions for every business document type
- **Validated example payloads** (positive + negative test fixtures)
- **Narrative documentation** explaining the Venezuelan fiscal context, GS1 standards, and ERP integrations
- **Memory Bank** (`memory-bank/`) — the authoritative project context files

There is **no application code**. This is a pure specification/documentation repository.

---

## First Steps for Any Agent Session

1. Read `memory-bank/activeContext.md` — current version, recent changes, next steps
2. Read `docs/00-quick-reference.md` — the one-page cheat sheet
3. Run `make validate-all` to confirm baseline is green before any changes

```bash
npm install          # if node_modules/ is missing
make validate-all    # must be: 15 positive ✅ + 8 negative ✅
```

---

## Repository Layout

```
fidex-document-specs/
├── AGENTS.md                     ← You are here
├── llms.txt                      ← Machine-readable repo index
├── GLOSSARY.md                   ← Domain term definitions (read if unfamiliar with Venezuelan pharma)
├── CHANGELOG.md                  ← Version history
├── Makefile                      ← All developer commands (see below)
├── package.json                  ← ajv-cli + prettier + npm test
│
├── memory-bank/                  ← Project context (read before working)
│   ├── 01_PROJECT_CHARTER.md     ← What this project is and why it exists
│   ├── 02_ARCHITECTURE_PRINCIPLES.md  ← Core design rules (MUST READ)
│   ├── 03_AGENTIC_WORKFLOW.md    ← How to add new document types (SPARC)
│   ├── activeContext.md          ← Current focus, recent changes, next steps
│   ├── progress.md               ← What works, what's left, known issues
│   └── techContext.md            ← Tech stack, commands, constraints
│
├── docs/                         ← Narrative documentation
│   ├── 00-quick-reference.md     ← One-page cheat sheet
│   ├── 01-overview.md            ← Architecture & design philosophy
│   ├── 06-document-lifecycle.md  ← Order→Invoice full flow diagram
│   ├── 09-erp-mapping/           ← ERP field mapping guides
│   └── es/                       ← Spanish translations (mirror of EN)
│
├── schemas/                      ← JSON Schema 2020-12 definitions
│   ├── _common/                  ← Reusable $ref components (party, address, tax-line, etc.)
│   ├── invoice/gs1-invoice.schema.json
│   ├── order/gs1-order.schema.json
│   └── ...                       ← one domain per folder
│
└── examples/                     ← Runnable payload examples
    ├── invoice/                  ← Valid examples (must PASS validate)
    ├── _invalid/                 ← Negative fixtures (must FAIL validate)
    └── ...
```

---

## Available Commands

| Command | Description |
|---|---|
| `make validate-all` | **Run after every change** — 15 positive + 8 negative tests |
| `make validate` | Positive examples only |
| `make validate-negative` | Negative fixtures only (must fail schema) |
| `make validate-one FILE=examples/order/01-purchase-order.json` | Single file |
| `make lint` | Check JSON formatting (Prettier) |
| `make format` | Auto-format all JSON files |
| `make list-schemas` | List all schema files |
| `make list-examples` | List all example files |
| `make check-deps` | Verify node, ajv-cli, prettier versions |

**After any change to a schema or example:** always run `make validate-all`.  
**After any change to JSON formatting:** run `make format` then `make lint`.

---

## Core Architecture Rules (Non-Negotiable)

### ✅ DO

- Use **English-only enum values**: `PURCHASE_ORDER`, `SHIPPED`, `RETENTION_IVA`, etc.
- Add **`minLength: 1`** to every required string field to reject empty strings
- Use **`unevaluatedProperties: false`** on every domain schema root
- Write **bilingual `description`** fields: `"English description. / Descripción en español."`
- Reference common schemas via **URI `$ref`**: `"$ref": "https://schemas.fidex.io/v1/common/party"`
- Add **`examples` arrays** to every property for AI tooling and autocomplete
- Keep Venezuelan fiscal fields (`fiscal_totals_ves`, `fiscal_control`) **optional** — not all documents are Venezuelan
- Use the **`$id` namespace** `https://schemas.fidex.io/v1/{domain}/{name}` for all schemas
- Require **`related_documents`** on `CREDIT_NOTE` / `DEBIT_NOTE` via `if/then`
- Use **YYYY-MM format** for `retention_period` (SENIAT requirement)

### ❌ DO NOT

- Add Spanish enum values (`ORDEN_DE_COMPRA`, `DESPACHADO`) — machine-readable values must be English
- Duplicate common schema structures — always use `$ref` to `schemas/_common/`
- Add undeclared fields to examples — `unevaluatedProperties: false` will reject them
- Remove `unevaluatedProperties: false` from domain schemas
- Mix VES and USD in the same `pricing` field — USD is always the base; VES is derived via `exchange_rate_applied`
- Commit a schema change without a corresponding example update
- Leave `description` fields empty or monolingual

---

## How to Add a New Document Type (5 Steps)

> See full guide: `memory-bank/03_AGENTIC_WORKFLOW.md` and `docs/13-agent-cookbook.md`

1. **Spec doc** → Create `docs/{nn}-{topic}.md` with business context, fields, and Venezuelan extensions
2. **Schema** → Create `schemas/{domain}/gs1-{domain}.schema.json` using the standard envelope template
3. **Example** → Create `examples/{domain}/01-{scenario}.json` and run `make validate-one FILE=...`
4. **Registry** → Add `document_type` enum to `schemas/_common/kontext-routing.schema.json`, update `README.md` table, update `CHANGELOG.md`
5. **Negative test** → Create `examples/_invalid/{domain}/01-{bad-scenario}.json` and verify it fails

---

## How to Add a New Field to an Existing Schema

1. Add the property to the correct schema (domain or `_common/`)
2. Add `minLength: 1` if it's a required string
3. Add `examples` array with 2-3 realistic values
4. Add bilingual `description`
5. Update the corresponding example in `examples/{domain}/`
6. Run `make validate-all`
7. Update `memory-bank/activeContext.md` under "Recent Changes"

---

## Key Patterns to Know

### Every document has two top-level keys

```json
{
  "kontext_routing": { ... },   // AS5 transport metadata — hub reads ONLY this
  "payload": { ... }            // Business data — never inspected by the hub
}
```

### Party references (buyer, seller, etc.) use `$ref`

```json
"seller": { "$ref": "https://schemas.fidex.io/v1/common/party" }
```

### Venezuelan fiscal totals live in `summary.fiscal_totals_ves`

```json
"fiscal_totals_ves": {
  "exchange_rate_applied": 45.0,
  "base_imponible_ves": 7087.5,
  "total_iva_ves": 0.0,
  "total_gross_ves": 7087.5
}
```

### Back-references use `related_documents` array

```json
"related_documents": [
  { "doc_type": "INVOICE", "document_number": "INV-2026-00145" }
]
```

---

## Validation Mechanics

- `ajv-cli` v5 / ajv v8.x with `--spec draft2020 --strict=false -c ajv-formats`
- Common schemas are loaded via `-r "schemas/_common/*.schema.json"`
- `$id` URIs do **not** need to be live URLs — ajv resolves them from `-r` loaded files
- Negative test logic: `ajv` exit code `1` (invalid) = **test PASS**; exit code `0` (valid) = **test FAIL**

---

## Memory Bank Update Policy

Update `memory-bank/activeContext.md` and `memory-bank/progress.md` **after every meaningful change**. This is not a final step — it is concurrent with code changes.

When a version is complete, also update:
- `CHANGELOG.md` (add version entry)
- `README.md` badges and document table
- `docs/00-quick-reference.md` version number

---

## Related Repositories

| Repo | Language | Purpose |
|---|---|---|
| `greicodex/fidex-protocol` | Go | AS5 transport, JOSE security, J-MDN receipts |
| `greicodex/fidex-hub` | Go | Kontext routing engine |
| `greicodex/fidex-odoo` | Python | Odoo ERP adapter |
