# Tech Context — FideX Document Specifications

## Technology Stack

| Layer | Technology | Version | Purpose |
|---|---|---|---|
| Schema Standard | JSON Schema | 2020-12 | Document structure definitions |
| Validator | `ajv-cli` | ^5.0.0 (ajv v8.x) | CLI validation via Makefile |
| Format Validation | `ajv-formats` | ^3.0.1 | `date-time`, `email` format assertions |
| Formatter | `prettier` | ^3.3.0 | Consistent JSON formatting |
| Runtime | Node.js | >=18.0.0 | ajv-cli execution environment |
| Build System | GNU Make | system | Task orchestration |
| Version Control | Git | system | Source control |
| CI/CD | GitHub Actions | — | Automated validate + lint on push/PR |

---

## Development Setup

### Prerequisites
```bash
node --version   # >= 18.0.0
npm --version    # >= 9.x
```

### Install
```bash
npm install        # installs ajv-cli, ajv-formats, prettier
```

### Common Commands
```bash
make validate                                         # validate all examples
make validate-one FILE=examples/order/01-purchase-order.json  # validate one file
make lint                                             # check JSON formatting
make format                                           # auto-format JSON
make list-schemas                                     # list all schema files
make list-examples                                    # list all example files
make check-deps                                       # verify tool versions
```

---

## Schema Toolchain Details

### ajv-cli v5 / ajv v8.x Flags Used
```makefile
AJV_FLAGS := --spec draft2020 --strict=false --validate-formats=false --errors=text
```

| Flag | Reason |
|---|---|
| `--spec draft2020` | JSON Schema 2020-12 support |
| `--strict=false` | Allows `allOf` sub-schemas without explicit `type` (needed for `kontext_routing` `allOf` pattern) |
| `--validate-formats=false` | **Temporary** — remove once `ajv-formats` is installed and confirmed working |
| `--errors=text` | Human-readable error output |

### URI-based `$ref` Loading
Common schemas are loaded via the `-r` flag:
```bash
ajv validate -s schemas/invoice/gs1-invoice.schema.json \
             -d "examples/invoice/*.json" \
             -r "schemas/_common/*.schema.json" \
             --spec draft2020 --strict=false
```

The `$id` URIs (`https://schemas.fidex.io/v1/common/party`) are resolved by ajv when the files are registered via `-r`. The HTTP URI does **not** need to be live — ajv maps it internally from the loaded files.

---

## $id Namespace Convention

All schemas use:
```
https://schemas.fidex.io/v1/{domain}/{name}
```

| Domain | Examples |
|---|---|
| `common` | `https://schemas.fidex.io/v1/common/party` |
| `order` | `https://schemas.fidex.io/v1/order/schema` |
| `invoice` | `https://schemas.fidex.io/v1/invoice/schema` |
| `retention` | `https://schemas.fidex.io/v1/retention/schema` |

---

## Technical Constraints

1. **`unevaluatedProperties: false`** — strict mode on all domain schemas. Every new field must be declared in the schema before appearing in examples.
2. **`allOf` + `const` pattern for `document_type`** — ajv `--strict=false` required to avoid "unknown keyword" errors in sub-schemas.
3. **Glob expansion** — `SCHEMAS_COMMON_GLOB` must remain a quoted string passed to ajv; do not expand it with `$(wildcard)` as this produces a space-separated list that ajv cannot parse.
4. **`validate-one` domain detection** — uses `$(word 2, $(subst /, ,$(FILE)))`. Requires file path format `examples/{domain}/filename.json`. Strip `./` prefix with `patsubst ./%,%` before extraction.

---

## File Naming Conventions

| Type | Pattern | Example |
|---|---|---|
| Domain schemas | `gs1-{domain}.schema.json` | `gs1-invoice.schema.json` |
| Common schemas | `{name}.schema.json` | `party.schema.json` |
| Examples | `{nn}-{scenario-slug}.json` | `01-invoice-standard.json` |
| Docs (EN) | `{nn}-{topic}.md` | `06-document-lifecycle.md` |
| Docs (ES) | `{nn}-{topic-es}.md` | `06-ciclo-de-documentos.md` |

---

## Dependencies

### Runtime
None — this is a specification repository, not an application.

### Dev
- `ajv-cli` — JSON Schema validation CLI
- `ajv-formats` — Format validators for `date-time`, `email`, `uri`, etc.
- `prettier` — JSON formatter (enforced via `.prettierrc`)

### `.prettierrc` Configuration
Stored at root; applies to all JSON files in `schemas/` and `examples/`.

---

## CI/CD

### GitHub Actions (`.github/workflows/validate.yml`)
Triggers: push to `main`/`develop`, pull requests to `main`
Steps:
1. `actions/checkout@v4`
2. `actions/setup-node@v4` (Node 20, npm cache)
3. `npm ci`
4. `make validate` — schema validation
5. `make lint` — prettier format check

---

## Related Repositories

| Repo | Language | Purpose |
|---|---|---|
| `greicodex/fidex-protocol` | Go | AS5 transport, JOSE security, J-MDN |
| `greicodex/fidex-hub` | Go | Kontext routing engine |
| `greicodex/fidex-odoo` | Python | Odoo ERP adapter |
