# Agent Cookbook — FideX Document Specifications

> Task-oriented recipes for AI coding agents and human developers.  
> Each recipe is self-contained: follow the steps exactly, run `make validate-all` at the end.

---

## Before Any Recipe

```bash
npm install          # only if node_modules/ is missing
make validate-all    # baseline must be green: 15 positive ✅ + 8 negative ✅
```

Read `memory-bank/activeContext.md` to understand the current version and any active constraints.

---

## Recipe 1 — Add a New Document Type

> Use this when the spec requires an entirely new `document_type` enum value and a new schema.

### Ingredients

- A clear business context: what does this document represent? When is it sent?
- The list of required fields (with types, patterns, and Venezuelan extensions if any)
- At least one valid example scenario
- One invalid example scenario (what should be rejected?)

### Steps

**Step 1 — Write the spec doc**

Create `docs/{nn}-{topic}.md` (next sequential number after the last in `docs/`):

```markdown
# {Document Type} — FideX Specification

## Business Context
...when is this document sent, by whom, to whom...

## Fields
| Field | Type | Required | Description |
|---|---|---|---|
...

## Venezuelan Extensions (if applicable)
...any fiscal_totals_ves or fiscal_control requirements...

## Lifecycle
...how does this document relate to other documents...
```

**Step 2 — Design the schema**

Create `schemas/{domain}/gs1-{domain}.schema.json`. Use this template:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://schemas.fidex.io/v1/{domain}/schema",
  "title": "{Document Title}",
  "description": "{English description}. / {Descripción en español}.",
  "type": "object",
  "required": ["kontext_routing", "payload"],
  "properties": {
    "kontext_routing": {
      "allOf": [
        { "$ref": "https://schemas.fidex.io/v1/common/kontext-routing" },
        {
          "properties": {
            "document_type": { "const": "GS1_{DOMAIN}_JSON" }
          }
        }
      ]
    },
    "payload": {
      "type": "object",
      "required": ["document_info"],
      "properties": {
        "document_info": {
          "type": "object",
          "required": ["doc_type", "document_number"],
          "properties": {
            "doc_type": {
              "type": "string",
              "enum": ["{DOC_TYPE_VALUE}"],
              "description": "{English}. / {Español}.",
              "examples": ["{DOC_TYPE_VALUE}"]
            },
            "document_number": {
              "type": "string",
              "minLength": 1,
              "description": "Unique document identifier. / Identificador único del documento.",
              "examples": ["DOC-2026-00001"]
            }
          },
          "unevaluatedProperties": false
        }
      },
      "unevaluatedProperties": false
    }
  },
  "unevaluatedProperties": false
}
```

Rules for the schema:
- Every `required` string field → add `"minLength": 1`
- Every property → add `"examples": [...]` with 2-3 realistic values
- Every property → add bilingual `"description"`: `"English. / Español."`
- Reuse common schemas via `$ref`: `"$ref": "https://schemas.fidex.io/v1/common/party"`
- Add `"unevaluatedProperties": false` at every object level

**Step 3 — Write a valid example**

Create `examples/{domain}/01-{scenario-slug}.json`:

```json
{
  "kontext_routing": {
    "tenant_id": "tenant-leti-01",
    "receiver_id": "partner-drogueria-x",
    "document_type": "GS1_{DOMAIN}_JSON",
    "correlation_id": "ORD-2026-XXXX"
  },
  "payload": {
    "document_info": {
      "doc_type": "{DOC_TYPE_VALUE}",
      "document_number": "DOC-2026-00001"
    }
  }
}
```

Validate it:

```bash
make validate-one FILE=examples/{domain}/01-{scenario-slug}.json
```

Fix any errors before continuing.

**Step 4 — Update the registry**

Add the new `document_type` to `schemas/_common/kontext-routing.schema.json` enum:

```json
"enum": [
  "GS1_CUSTOMER_MASTER_JSON",
  ...existing values...,
  "GS1_{DOMAIN}_JSON"   ← add here
]
```

Update `README.md` — add a row to the Document Types table.  
Update `CHANGELOG.md` — add an entry under `[Unreleased]`.  
Update `docs/00-quick-reference.md` — add row to Document Types table.

**Step 5 — Write a negative test**

Create `examples/_invalid/{domain}/01-{bad-scenario}.json` — a structurally valid JSON that fails your schema for a meaningful reason (missing required field, wrong enum, bad pattern).

Verify it fails:

```bash
make validate-negative
```

The output must show `✅ examples/_invalid/{domain}/01-{bad-scenario}.json correctly rejected by schema`.

**Step 6 — Run full suite and update memory bank**

```bash
make validate-all
make lint
```

Update `memory-bank/activeContext.md` — add the new document type under "Recent Changes".  
Update `memory-bank/progress.md` — check off the new items under "What Works".

---

## Recipe 2 — Add a New Field to an Existing Schema

> Use this when an existing schema needs a new property (required or optional).

### Steps

**Step 1 — Add the property to the schema**

Open the appropriate schema file (`schemas/{domain}/gs1-{domain}.schema.json` or `schemas/_common/{name}.schema.json`).

Add the property with all required annotations:

```json
"new_field_name": {
  "type": "string",
  "minLength": 1,
  "description": "English description of what this field means. / Descripción en español.",
  "examples": ["example-value-1", "example-value-2"]
}
```

If required, add `"new_field_name"` to the parent object's `"required"` array.

If it has a specific format, add the appropriate constraint:
- String patterns: `"pattern": "^regex$"`
- Dates: `"format": "date-time"` (requires `ajv-formats`)
- Enums: `"enum": ["VALUE_A", "VALUE_B"]` (English only)
- Numbers: `"minimum"`, `"maximum"`, `"multipleOf"`

**Step 2 — Update the corresponding example**

Add the new field to at least one example in `examples/{domain}/`. If the field is required, add it to ALL examples in that domain.

**Step 3 — Validate**

```bash
make validate-one FILE=examples/{domain}/01-{scenario}.json
make validate-all
```

Fix any `unevaluatedProperties` errors (field in example but not declared in schema) or `required` errors (field in schema but missing from example).

**Step 4 — Update documentation**

If this field changes the Venezuelan fiscal architecture, update `docs/05-venezuelan-fiscal.md`.  
If this affects ERP mapping, update the relevant `docs/09-erp-mapping/` guide.  
Always update `memory-bank/activeContext.md`.

---

## Recipe 3 — Write a Negative Test Fixture

> Use this to prove a schema rule is actually enforced (not just documented).

### When to Write a Negative Test

- A new `if/then` conditional was added to a schema
- A new `required` field was added
- A new `pattern` or `format` was added
- A new `minLength: 1` was added on a string
- A new `enum` was added

### Steps

**Step 1 — Identify the rule to test**

Pick one specific schema rule. Each negative fixture should test exactly one failure mode.

**Step 2 — Create the fixture**

Create `examples/_invalid/{domain}/{nn}-{what-fails}.json`.

Start from a valid example (copy from `examples/{domain}/01-*.json`), then introduce exactly one violation:

```json
// Testing: CREDIT_NOTE must have related_documents
{
  "kontext_routing": { ... },
  "payload": {
    "document_info": {
      "doc_type": "CREDIT_NOTE",   ← triggers the if/then
      "document_number": "CN-001"
    }
    // related_documents intentionally absent ← the violation
  }
}
```

**Step 3 — Verify it fails**

```bash
make validate-negative
```

Expected output:
```
✅  examples/_invalid/{domain}/{nn}-{what-fails}.json correctly rejected by schema
```

If the fixture unexpectedly **passes** validation (`❌ should have FAILED`), the schema rule is not working. Debug the `if/then` logic in the schema.

**Step 4 — Document the fixture**

Update `examples/_invalid/README.md` — add a row to the test matrix table.

---

## Recipe 4 — Debug a Validation Failure

> Use this when `make validate-all` goes red.

### Diagnosis Steps

**Step 1 — Isolate the failing file**

```bash
make validate-all 2>&1 | grep "❌"
```

Run the failing file alone to get detailed errors:

```bash
make validate-one FILE=examples/{domain}/{failing-file}.json
```

**Step 2 — Read the error message**

ajv errors are in this format:
```
examples/invoice/01-invoice-standard.json - data/payload/summary must have required property 'total_gross_usd'
```

Parse it: `data/` = root of the document, then follow the path to the problem location.

**Step 3 — Common error types and fixes**

| Error | Cause | Fix |
|---|---|---|
| `must have required property '{field}'` | Required field missing from example | Add the field to the example |
| `unevaluatedProperties` | Field in example not declared in schema | Add property declaration to schema, OR remove field from example |
| `must match pattern "{regex}"` | Field value doesn't match pattern constraint | Fix the value in the example (e.g., RIF format, GLN digits) |
| `must be equal to one of the allowed values` | Invalid enum value | Use only the English enum values defined in the schema |
| `must be string` / `must be number` | Wrong type for a field | Check schema `type` and correct the example value |
| `must NOT have fewer than 1 characters` | Empty string `""` on a `minLength: 1` field | Provide a non-empty value |
| `$ref` resolution failure | Common schema not loaded | Ensure `-r "schemas/_common/*.schema.json"` is in the Makefile AJV command |

**Step 4 — Verify the fix**

```bash
make validate-one FILE=examples/{domain}/{fixed-file}.json
make validate-all
make lint
```

---

## Recipe 5 — Map a New ERP Field to FideX

> Use this when integrating a new ERP or adding missing field coverage to an existing ERP guide.

### Steps

**Step 1 — Identify the FideX field**

Find the field in the relevant schema. For example, to map an ERP's "supplier_code" to FideX:

```bash
grep -r "supplier" schemas/
```

Or read the schema directly:
```bash
cat schemas/_common/party.schema.json
```

**Step 2 — Find the ERP equivalent**

Consult the ERP's documentation for the equivalent field. For Odoo, the typical path is `res.partner.ref`. For SAP B1, it might be `BusinessPartners.CardCode`.

**Step 3 — Document the mapping**

Open `docs/09-erp-mapping/{nn}-{erp-name}.md` and add a row to the appropriate mapping table:

```markdown
| FideX Field | Path in Schema | ERP Model | ERP Field | Notes |
|---|---|---|---|---|
| Supplier code | `payload.parties.seller.rif` | `res.partner` | `vat` | Venezuelan RIF stored as VAT in Odoo |
```

**Step 4 — Validate that the field exists in the schema**

If the FideX field doesn't exist yet, use Recipe 2 to add it first.

**Step 5 — Update the ERP index**

Update `docs/09-erp-mapping/00-index.md` if the new mapping affects the comparison matrix.

---

## Recipe 6 — Update the Memory Bank After a Version Release

> Use this after completing all changes for a version milestone.

### Steps

**Step 1 — Run the full suite**

```bash
make validate-all
make lint
```

Both must be green before releasing.

**Step 2 — Bump the version**

Update `package.json` version field.  
Update the schema version badge in `README.md` and `README.es.md`.  
Update the version number in `docs/00-quick-reference.md`.

**Step 3 — Update CHANGELOG.md**

Move items from `[Unreleased]` to a new version section:

```markdown
## [v1.X.0] — YYYY-MM-DD

### Added
- ...new schemas, docs, examples...

### Changed
- ...schema changes...

### Fixed
- ...bug fixes...
```

**Step 4 — Update Memory Bank files**

`memory-bank/activeContext.md`:
- Update `## Current Version` header
- Move completed items to "Recent Changes" table
- Update "Next (vX.Y candidates)" section

`memory-bank/progress.md`:
- Check off completed items under "What Works"
- Remove completed items from "What's Left to Build"
- Update "Current Status" paragraph

`memory-bank/03_AGENTIC_WORKFLOW.md`:
- Update "Current Status" header
- Move resolved issues to "All Previously Resolved" table
- Add new decisions to "Decision Log"

**Step 5 — Verify version consistency**

```bash
grep -r "v1\." README.md package.json docs/00-quick-reference.md memory-bank/activeContext.md
```

All version references must match.

---

## Recipe 7 — Add `examples` Arrays to Schema Properties

> Use this to improve AI autocomplete, IDE tooling, and agent-generated payloads.

### When to Use

When adding a new property or auditing existing schemas for missing `examples` annotations.

### Rules for `examples` Arrays

- Add 2-3 values that are **realistic** for the Venezuelan pharmaceutical context
- Values must be **valid** against any `pattern`, `enum`, `type`, or `format` constraint
- For identifier fields (RIF, GTIN, GLN, SSCC), use the correct format
- For monetary fields, use realistic USD amounts (pharmaceutical supplies range $1–$500/unit)
- For dates, use ISO 8601 format: `"2026-03-09T14:30:00Z"`

### Format

```json
"property_name": {
  "type": "string",
  "description": "English. / Español.",
  "examples": ["realistic-value-1", "realistic-value-2", "realistic-value-3"]
}
```

### Reference Examples by Field Type

| Field | Good examples |
|---|---|
| RIF | `"J-00000000-1"`, `"J-11111111-2"`, `"V-12345678-9"` |
| GTIN | `"7591234567890"`, `"07591234567890"` |
| GLN | `"7590000000001"`, `"7590000000002"` |
| SSCC | `"175912345678901234"`, `"075900000000000001"` |
| SICM | `"S-12345"`, `"S-98765"` |
| retention_period | `"2026-03"`, `"2026-02"`, `"2025-12"` |
| currency | `"USD"` (base only — never `"VES"` in pricing) |
| SHA-256 hash | `"a3f1b9c8d2e4f6a1b3c5d7e9f0a2b4c6d8e0f2a4b6c8d0e2f4a6b8c0d2e4f6a8"` |
| date-time | `"2026-03-09T14:30:00Z"`, `"2026-03-11T10:00:00Z"` |
| tenant_id | `"tenant-leti-01"`, `"tenant-belo-01"` |
| receiver_id | `"partner-drogueria-x"`, `"partner-belo-distribuciones"` |
| correlation_id | `"ORD-2026-9921"`, `"CAT-2026-03-VE"` |
| document_number | `"INV-2026-00145"`, `"ORD-2026-9921"`, `"CN-2026-00012"` |
| unit price (USD) | `2.5`, `1.8`, `45.0` |
| exchange_rate | `45.0`, `46.5`, `48.0` |
| UoM | `"Caja"`, `"Unidad"`, `"Blister"` |

### After Adding Examples

```bash
make lint       # prettier may reformat spacing
make validate-all
```

---

## Quick Reference: Common Errors for Agents

| Symptom | Root Cause | Solution |
|---|---|---|
| `unevaluatedProperties` error on example | Field exists in example but not in schema | Declare the field in the schema first (Recipe 2) |
| `$ref` resolution fails | Common schema not registered with `-r` | Check `Makefile` AJV_FLAGS; do not remove `-r "schemas/_common/*.schema.json"` |
| Negative test unexpectedly passes | `if/then` condition not triggered | Check that the example actually violates the `if` condition |
| `minLength` error on example | Empty string `""` used as placeholder | Provide a real non-empty value |
| `pattern` mismatch on RIF | Wrong RIF format | Use `^[JVEGPjvegp]-[0-9]{8}-[0-9]$`, e.g., `J-12345678-9` |
| `pattern` mismatch on GLN | Wrong digit count | GLN must be exactly 13 digits: `^[0-9]{13}$` |
| `enum` error | Spanish enum value used | Use English: `PURCHASE_ORDER`, not `ORDEN_DE_COMPRA` |
| Lint fails after schema edit | JSON not formatted | Run `make format` before `make lint` |
