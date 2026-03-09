# Changelog

All notable changes to this specification will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [1.5.0] — 2026-03-09

### Added
- `docs/10-government-observer-node.md` — Government Observer Node full specification: Option A
  (Metadata-only) and Option B (Targeted Tax Manifest), JSONata extraction map, Observer ACK
  format, re-encryption flow, and cryptographic requirements table.
- `docs/11-dlt-merkle-anchoring.md` — DLT / Merkle Root Anchoring Protocol: Two-stage J-MDN
  state machine (NETWORK_DELIVERED → FISCAL_CLEARED), L2-style hourly rollup batching (99.8%
  gas reduction), `IFideXAnchor` Solidity interface, catalog `sync_state` receiver state
  machine, and latency targets table.
- `docs/12-jsonata-maps.md` — JSONata Transformation Maps Reference: `maps/` directory
  convention, file header standard, full Odoo→FideX example, Hub→ERP routing diagram, `$env`
  runtime context, error handling, and map testing conventions.
- `examples/_invalid/` — Negative test suite (3 fixtures testing `if/then` enforcement and
  `pattern` validation); `make validate-negative` and `make validate-all` Makefile targets.

### Changed
- `gs1-order.schema.json` — Added `if/then` enforcement: `QUOTE` requires `related_order`;
  `ORDER_CONFIRMED` requires both `related_order` and `related_quote`. Mirrors the invoice
  if/then pattern added in v1.1.
- `gs1-catalog.schema.json`, `gs1-customer-master.schema.json`,
  `gs1-despatch-advice.schema.json`, `product-identity.schema.json` — Added `minLength: 1`
  to all required string fields that were missing it.
- `Makefile` — New targets: `validate-negative` (inverted exit-code logic), `validate-all`.
- `package.json` — Version bumped `1.4.0` → `1.5.0`.

## [1.4.0] — 2026-03-09

### Added

#### Spanish Documentation — Foundational Docs 01–04 (`docs/es/`)
Complete Spanish translation of the four foundational architecture documents, closing the gap left in v1.3.0:
- `docs/es/01-descripcion-general.md` — Two-layer architecture, document type registry, payload structure, FideX protocol integration
- `docs/es/02-sobre-de-enrutamiento.md` — `kontext_routing` field-by-field guide, hub routing flow diagram, Separation of Concerns principle
- `docs/es/03-seguridad-jose.md` — JOSE Sign-then-Encrypt pattern, JWKS key management, J-MDN two-stage acknowledgment, Targeted Tax Manifest privacy model, QR onboarding handshake
- `docs/es/04-identificadores-gs1.md` — GTIN/GLN/SSCC/SICM/RIF identifiers with Venezuelan-specific context, SSCC warehouse receiving workflow, SICM hard-block mechanics

#### GitHub Actions CI/CD Pipeline (`.github/workflows/validate.yml`)
- Automated validation on every push to `main`/`develop` and all pull requests to `main`
- Runs `npm ci`, `make validate` (schema + example validation), and `make lint` (prettier format check)
- CI status badge added to `README.md`

#### Memory Bank Completion (GOS Standard)
Three missing Memory Bank files added to complete the GOS project documentation standard:
- `memory-bank/activeContext.md` — Current version, active focus, recent changes, active decisions, key patterns, learnings
- `memory-bank/progress.md` — What works, what's left to build, current status, known issues, decision evolution
- `memory-bank/techContext.md` — Technology stack, development setup, `$id` namespace, technical constraints, file naming conventions, CI/CD details

### Changed

#### `ajv-formats` — Real `date-time` Format Validation Enabled
- Added `ajv-formats: ^3.0.1` to `devDependencies`
- Removed `--validate-formats=false` from Makefile `AJV_FLAGS`
- Added `-c ajv-formats` plugin flag to all validation commands
- All 13 existing examples confirmed passing with format validation active
- `date-time`, `email`, and `uri` fields in all schemas are now actively validated

#### Makefile — `validate-one` Path Normalization
- Added `patsubst ./%,%` to strip `./` prefix before domain extraction
- Resolves failure when shell tab-completion produces `./examples/order/01.json` style paths

#### Schema Hardening — `minLength: 1` on Required Strings
Added `"minLength": 1` to all required `string` fields that could silently accept empty string `""`:
- `schemas/_common/kontext-routing.schema.json` — `tenant_id`, `receiver_id`, `correlation_id`
- `schemas/_common/party.schema.json` — `name`
- `schemas/_common/related-documents.schema.json` — `document_number`, `currency_base`
- `schemas/_common/retention-detail.schema.json` — `related_invoice.document_number`
- `schemas/invoice/gs1-invoice.schema.json` — `document_number`, `related_order`, `currency_base`
- `schemas/retention/gs1-retention.schema.json` — `document_number`

#### Schema Hardening — ISLR Rounding Rule
- `schemas/_common/retention-detail.schema.json` — `amount_retained_usd` description now explicitly specifies **half-up rounding to 2 decimal places** (e.g. `$157.50 × 1% = $1.575 → $1.58`). All parties and ERP implementations must apply the same rule to avoid SENIAT fiscal book reconciliation mismatches.

#### Version Synchronization
- `package.json` version updated from `1.0.0` → `1.3.0` (was never updated from initial value)
- `README.md` schema-version badge updated from `v1.2.0` → `v1.3.0`

### Fixed
- Memory Bank `03_AGENTIC_WORKFLOW.md`: removed stale `_comment` known issue (file never had `_comment`; entry was erroneous)
- Memory Bank `03_AGENTIC_WORKFLOW.md`: marked `docs/erp-mapping/` as resolved (completed in v1.2.0)

### Design Decisions
- `$defs/NonNegativeNumber` pattern considered but deferred: URI-based cross-file `$ref` architecture makes shared `$defs` impractical without adding a new common schema file; the DRY benefit doesn't justify the added schema complexity at this stage
- `ajv-formats` plugin loaded via `-c ajv-formats` flag in ajv-cli v5, which calls `require('ajv-formats')(ajv)` — the correct initialization pattern for the plugin system

---

## [1.3.0] — 2026-03-09

### Added

#### Documentación en Español — Spanish Documentation Layer (`docs/es/`)

Complete Spanish translation of all FideX documentation. All files include a cross-link to the English counterpart.

**Fiscal guides (translated):**
- `docs/es/05-fiscal-venezolano.md` — IVA (16%), IGTF (3%), tasa BCV, RIF format, Número de Control SENIAT, ISLR overview, SICM permit mechanics
- `docs/es/06-ciclo-de-documentos.md` — Full order-to-cash flow diagrams in Spanish, document state machines (Orden/ASN/Factura), `related_documents` chaining, retention direction rules, `correlation_id` grouping
- `docs/es/07-notas-credito-debito.md` — Credit/Debit Note fiscal math (NC/ND), JSON Schema `if/then` enforcement explanation, ERP mapping table (all 5 ERPs), SENIAT Número de Control on NC/ND
- `docs/es/08-retenciones-fiscales.md` — IVA retention mechanics (Prov. 049/056, 75% default), ISLR mechanics (Decreto 1808 Tabla 26), payload examples, filing deadlines (Días 3 y 10), comprobante as crédito fiscal, ERP mapping table

**ERP integration index (translated):**
- `docs/es/09-integracion-erp/00-indice.md` — ERP × document-type matrix (Spanish), integration architecture diagram, Venezuelan fiscal field reference table

**ERP field mapping guides (translated):**
- `docs/es/09-integracion-erp/01-odoo-17-18.md` — Odoo 17/18 JSON-RPC + REST; all 6 document types; `l10n_ve` module notes; custom `x_*` field guidance; multi-currency and SICM blocking
- `docs/es/09-integracion-erp/02-profit.md` — Profit Plus v12 SQL Server / `ProfitSDK.dll` COM; Spanish column names (`cod_cli`, `nro_control`, `comp_ret_iva`); SQL MERGE pattern; fiscal sequence warning
- `docs/es/09-integracion-erp/03-saint.md` — Saint Enterprise v6+ REST API v1; `CampoLibre1–5` / `CampoFecha1–3` strategy; all 6 doc types; IGTF v6.2+ note
- `docs/es/09-integracion-erp/04-galac.md` — Galac Software v5+ fiscal-only scope; XML import format example; Bs-centric field mapping; ISLR `CodigoConcepto` / Decreto 1808 Tabla 26; automatic SENIAT sequence numbering
- `docs/es/09-integracion-erp/05-sap-business-one.md` — SAP B1 10.0 Service Layer REST; UDF (`U_*`) creation guide; batch number flow (ODLN before OINV); retention Option A (OWHT codes) and Option B (UDO `U_RETENCION`)

**Root README (updated):**
- `README.es.md` — Full Spanish README with document types table, repo structure, quick-start commands, order-to-cash diagram, ERP integration table, and design principles
- `README.md` — Added `🇪🇸 [Versión en español](README.es.md)` badge link

### Design Decisions
- All Spanish docs use a `> 🇬🇧 [English version](...)` link at the top for discoverability
- All machine-readable enums remain in English across both language editions
- Galac documented as fiscal-only in Spanish edition (consistent with English v1.2 design decision)
- SAP B1 UDF names (`U_*`) are language-neutral by convention; Spanish docs use the same UDF names as English docs

---

## [1.2.0] — 2026-03-09

### Added

#### ERP Integration Mapping Guides (`docs/09-erp-mapping/`)
New documentation directory with field-level mapping tables and API endpoint references for all 5 target ERPs used in the Venezuelan pharmaceutical supply chain:

- `docs/09-erp-mapping/00-index.md` — Master index: ERP comparison matrix, document family matrix (all 6 FideX types × 5 ERPs), integration architecture diagram, Venezuelan fiscal field reference (RIF, SICM, BCV rate, IGTF, IVA/ISLR retention, comprobante)
- `docs/09-erp-mapping/01-odoo-17-18.md` — **Odoo 17/18** (Odoo S.A.): JSON-RPC + REST API (`/web/dataset/call_kw`, `/api/`), full mapping for all 6 document types to `res.partner`, `product.template`, `sale.order`, `stock.picking`, `account.move` (incl. `l10n_ve` localization fields and `x_*` custom field guidance)
- `docs/09-erp-mapping/02-profit.md` — **Profit Plus v12** (Softech C.A., miprofit.com): SQL Server direct + COM SDK (`ProfitSDK.dll`) mapping to `clientes`, `articulos`, `ped_venta`, `guia_despacho`, `factura`, `comp_ret`; includes SQL MERGE upsert patterns
- `docs/09-erp-mapping/03-saint.md` — **Saint Enterprise v6+** (Business Technology C.A., saintve.com): REST API v1 (`/api/v1/`) mapping to `ClCliente`, `InArticulo`, `VePedido`, `VeDespacho`, `VeFactura`, `VeRetencion`; includes `CampoLibre` field strategy for SICM/GLN/SSCC
- `docs/09-erp-mapping/04-galac.md` — **Galac Software v5+** (Galac Software C.A.): fiscal-only scope (invoices + retentions); XML import format + REST API (`/api/v1/`); Bs-centric field mapping for `FacturasVentas`, `NotasCredito`, `ComprobantesRetencion`; ISLR `CodigoConcepto` / Decreto 1808 Tabla 26 fields
- `docs/09-erp-mapping/05-sap-business-one.md` — **SAP Business One 10.0** (SAP SE): Service Layer REST (`https://{server}:50000/b1s/v1/`) mapping to `OCRD`, `OITM`, `ORDR`, `ODLN`, `OINV`/`ORIN`; UDF creation guide; withholding tax codes (Option A) and User-Defined Object `U_RETENCION` (Option B) for Venezuelan retention compliance

### Design Decisions
- Galac is documented as a **fiscal-only adapter** (no catalog, orders, or despatch); its scope deliberately excludes operational ERP functions
- SAP B1 retention uses **two implementation options** (withholding tax codes vs. UDO) to accommodate different partner localization levels
- Saint `CampoLibre1–5` / `CampoFecha1–3` are the recommended extension points for SICM, GLN, Merkle Root, and SSCC (avoids schema changes in older Saint versions)
- Profit integrations must use `ProfitSDK.dll` for transactional documents (`factura`, `ped_venta`) to preserve legal fiscal sequence; SQL Server direct is safe only for master data

---


## [1.1.0] — 2026-03-09

### Added

#### Credit Notes & Debit Notes (`GS1_INVOICE_JSON`)
- `doc_type: "CREDIT_NOTE"` — Nota de Crédito. Reduces a prior invoice for returns, price adjustments, or billing corrections. Requires `related_documents` back-link.
- `doc_type: "DEBIT_NOTE"` — Nota de Débito. Increases a prior invoice for missed charges, price corrections, or additional quantities. Requires `related_documents` back-link.
- Updated `schemas/invoice/gs1-invoice.schema.json` with JSON Schema `if/then` constraint that structurally enforces `related_documents` when `doc_type` is `CREDIT_NOTE` or `DEBIT_NOTE`
- `examples/invoice/03-credit-note.json` — Credit Note for 5 returned boxes of Amoxicilina (IVA-exempt, linked to INV-2026-00145)
- `examples/invoice/04-debit-note.json` — Debit Note for 10 additional units of Alcohol Antiséptico (IVA 16% + IGTF 3%, linked to INV-2026-00146)
- `docs/07-credit-debit-notes.md` — Conceptual guide covering triggers, fiscal math, routing rules, ERP mapping (Odoo/Profit/Saint), and full transaction flow diagrams

#### Tax Retention (`GS1_RETENTION_JSON`)
- `schemas/retention/gs1-retention.schema.json` — New schema for Venezuelan tax withholding documents covering:
  - `RETENTION_IVA`: 75% VAT withholding by Contribuyentes Especiales (SENIAT Providencia 049/056, Form AR-C)
  - `RETENTION_ISLR`: Income tax withholding per Decreto 1808 Tabla 26 (concept codes, rates by payment type)
- `schemas/_common/retention-detail.schema.json` — New common schema for retention line items with full bilingual field documentation
- `examples/retention/01-retention-iva.json` — IVA retention (75%, $18.00 USD / $810.00 VES) by Droguería X on INV-2026-00146
- `examples/retention/02-retention-islr.json` — ISLR retention (1%, Código 1, $1.58 USD / $71.10 VES) by Droguería X on INV-2026-00145
- `docs/08-tax-retention.md` — Conceptual guide covering who must retain, IVA vs. ISLR calculation mechanics, SENIAT compliance (ISENIAT portal, filing deadlines), comprobante as tax credit, and multi-invoice consolidation rules

### Updated
- `Makefile` — Added `validate-retention` target; `validate` now includes all 6 document types
- `README.md` — Updated version badge to v1.1.0; expanded document types table; updated repository structure
- `schemas/_common/kontext-routing.schema.json` — `GS1_RETENTION_JSON` enum value already present from v1.0 planning; confirmed in routing

### Design Decisions
- Credit/Debit Notes reuse `GS1_INVOICE_JSON` (not a new `document_type`) — the AS5 Hub routing for invoice and notes is identical; `doc_type` differentiates at the payload level
- `related_documents` enforcement uses JSON Schema 2020-12 `if/then` instead of application-level validation — aligns with the Tier 2 (Schema) validation principle
- Retention documents use reversed routing direction (`withholder` as `tenant_id`) — the droguería/Agente de Retención is the sender
- `retention_period` (YYYY-MM) is a top-level required field to prevent cross-period mixing of retention lines in a single comprobante
- ISLR `taxable_base_usd` represents the gross payment (not just IVA) — matches Decreto 1808 basis for income withholding

---


## [1.0.0] — 2026-03-09

### Added
- **Core transaction cycle** covering the full Venezuelan B2B order-to-cash flow
- `GS1_CUSTOMER_MASTER_JSON` schema — customer master with SICM health permits and multi-currency financial profiles
- `GS1_CATALOG_JSON` schema — product catalog supporting `DELTA_UPDATE` and `FULL_SYNC` variants with Merkle Root state vector
- `GS1_ORDER_JSON` schema — covers three Venezuelan order states:
  - `PURCHASE_ORDER` ("Orden de Compra") — buyer-initiated request
  - `QUOTE` ("Presupuesto") — vendor's priced response
  - `ORDER_CONFIRMED` ("Orden Confirmada") — buyer confirmation
- `GS1_DESPATCH_ADVICE_JSON` schema — Advance Ship Notice with SSCC packaging, lot/batch tracking, and driver details
- `GS1_INVOICE_JSON` schema — invoice with `fiscal_totals_ves` block for SENIAT multi-currency compliance
- **Common schemas** (`_common/`): `kontext-routing`, `party`, `address`, `product-identity`, `pharma-attributes`, `tax-line`, `fiscal-totals-ves`, `fiscal-control`, `related-documents`
- **Example payloads** for all document types
- **Documentation** (6 conceptual guides covering architecture, routing, security, GS1 identifiers, Venezuelan fiscal requirements, and document lifecycle)
- `Makefile` with `validate`, `validate-one`, `lint`, and `format` targets
- Memory Bank (`memory-bank/`) conforming to GOS project standards

### Design Decisions
- JSON Schema Draft 2020-12 (`https://json-schema.org/draft/2020-12/schema`)
- All machine-readable enums in English; descriptions bilingual (EN/ES)
- `$id` namespace: `https://schemas.fidex.io/v1/`
- Common schemas referenced via URI `$ref` (loaded with `ajv -r`)
