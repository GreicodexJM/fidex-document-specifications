# Glossary — FideX Document Specifications

Domain terminology for Venezuelan pharmaceutical B2B, GS1 standards, and FideX/AS5 protocol concepts.  
Use this file to resolve ambiguous terms before editing schemas, examples, or documentation.

> 🇪🇸 Spanish equivalents are shown in parentheses where applicable.

---

## A

**AS5**  
Application Statement 5 — an EDI messaging standard originally from EDIINT/AS2 family. FideX adapts AS5 for JSON-native B2B document exchange, adding JOSE security (JWS/JWE) and a hub-based routing model. Not to be confused with AS2 (XML/MIME) or AS4 (SOAP).

**ASN (Advance Ship Notice)**  
See: *Despatch Advice*. The document sent by the shipper before goods arrive, carrying SSCC lot tracking information.

---

## B

**Base Imponible** *(taxable base)*  
The portion of the invoice total subject to IVA taxation, after exempt line items are excluded. In FideX: `summary.fiscal_totals_ves.base_imponible_ves`.

**BCV (Banco Central de Venezuela)**  
Venezuela's central bank. Publishes the official USD/VES exchange rate daily. In FideX schemas, this rate is captured as `exchange_rate_applied` in the `fiscal_totals_ves` object. All VES amounts derive from this rate applied to the USD base price.

---

## C

**Contribuyente Especial** *(special taxpayer)*  
A large-revenue business formally designated by SENIAT as a special taxpayer. Contribuyentes Especiales are legally required to withhold IVA from their suppliers and remit it directly to SENIAT (under Providencia 049/056). In FideX, they issue `RETENTION_IVA` documents.

**Correlation ID** (`correlation_id`)  
The business key that links all documents in a single transaction chain: `PURCHASE_ORDER` → `QUOTE` → `ORDER_CONFIRMED` → `DESPATCH_ADVICE` → `INVOICE`. Typically the originating order number (e.g., `ORD-2026-9921`). Lives in `kontext_routing`, not `payload`.

**Credit Note** (`CREDIT_NOTE`)  
A document reducing a previously issued invoice (returns, overpayments, price adjustments). In FideX, uses `GS1_INVOICE_JSON` document type with `doc_type: "CREDIT_NOTE"`. **Requires** `related_documents` referencing the original invoice — enforced by `if/then` in `gs1-invoice.schema.json`.

---

## D

**Debit Note** (`DEBIT_NOTE`)  
A document increasing a previously issued invoice (missed charges, additional costs, corrections). In FideX, uses `GS1_INVOICE_JSON` document type with `doc_type: "DEBIT_NOTE"`. **Requires** `related_documents` — same `if/then` enforcement as Credit Note.

**Decreto 1808**  
Venezuelan presidential decree governing ISLR (income tax) withholding. *Tabla 26* within the decree specifies withholding percentages by activity and taxpayer type. Referenced in `docs/08-tax-retention.md`.

**DELTA_UPDATE**  
Catalog synchronization mode sending only changed products since the last update. Identified by `catalog_type: "DELTA_UPDATE"`. Contrast with `FULL_SYNC`. Uses Merkle root chaining to detect missed deltas.

**Despatch Advice** *(Nota de Entrega / ASN)*  
Document type `GS1_DESPATCH_ADVICE_JSON`. Sent by the vendor before or during shipment to notify the buyer of what is being shipped, with SSCC (pallet) tracking and lot/expiry information.

**DLT (Distributed Ledger Technology)**  
In FideX, used for Merkle anchoring of fiscal documents. The `docs/11-dlt-merkle-anchoring.md` spec defines an hourly Merkle rollup where document hashes are chained and anchored to an external ledger. The root hash appears in `FISCAL_CLEARED` J-MDN receipts.

**Droguería** *(drug distributor)*  
A licensed pharmaceutical wholesale distributor. The middle tier in the Venezuelan pharma supply chain: Laboratorio → **Droguería** → Farmacia. Must hold a SICM permit. In FideX schemas, typically appears as the `buyer` or `receiver` of orders and invoices.

---

## E

**Exchange Rate** (`exchange_rate_applied`)  
The BCV official USD/VES rate at the time of document issuance. Stored in `payload.summary.fiscal_totals_ves.exchange_rate_applied`. All VES amounts are derived from this single rate to prevent rounding mismatches across ERPs.

---

## F

**Factura** *(invoice)*  
The Venezuelan fiscal document for B2B sales. In FideX: `GS1_INVOICE_JSON` with `doc_type: "INVOICE"`. Must include SENIAT fiscal control data for Venezuelan operations (`fiscal_control` and `fiscal_totals_ves`).

**Farmacia** *(pharmacy)*  
A retail pharmacy — the final tier of the Venezuelan pharmaceutical supply chain. Typically the `ship_to` party in delivery documents and sometimes the `payer` in invoices if buying directly from a distributor.

**FideX**  
The B2B protocol and document standard defined in this repository. FideX stands for **Fi**scal **D**ocument **Ex**change. It layers Venezuelan fiscal requirements on top of GS1/AS5 standards. Not a company — it's an open standard maintained by Greicodex.

**Fiscal Control** (`fiscal_control`)  
Venezuelan-specific data block capturing the SENIAT-issued *número de control* (control number), the *número de talonario* (serial series), and optionally the amount in letters and BCV notice message. Optional in schemas — its absence is valid for non-Venezuelan documents.

**Fiscal Totals VES** (`fiscal_totals_ves`)  
Optional nested object in `payload.summary` carrying all VES-denominated fiscal totals required by SENIAT: `base_imponible_ves`, `total_iva_ves`, `total_igtf_ves`, `total_exempt_ves`, `total_gross_ves`, and `exchange_rate_applied`.

**FULL_SYNC**  
Catalog synchronization mode sending all active products as a complete baseline. Used to reset after Merkle root mismatch is detected. `catalog_type: "FULL_SYNC"`. A FULL_SYNC resets `sequence_id` to 1 and establishes a new `current_merkle_root`.

---

## G

**GLN (Global Location Number)**  
GS1 13-digit identifier for physical locations: warehouses, stores, distribution centers. Venezuelan GTINs/GLNs use country prefix `759`. Pattern: `^[0-9]{13}$`. Required for identifying parties with physical locations. Distinct from RIF (fiscal identity).

**GS1**  
Global standards organization that maintains GTIN, GLN, SSCC, and related B2B identifiers and document standards (DESADV, INVOIC, ORDERS). FideX is GS1-LATAM compliant.

**GTIN (Global Trade Item Number)**  
GS1 13 or 14-digit product identifier. In Venezuelan pharma, uses country prefix `759`. Pattern: `^[0-9]{13,14}$`. **Mandatory** on every product line item. Eliminates ambiguity between similar products (e.g., Amoxicilina 250mg vs 500mg).

**Government Observer Node**  
A privacy-preserving bridge between the FideX Hub and SENIAT's tax system. Described in `docs/10-government-observer-node.md`. It re-encrypts fiscal payload data for SENIAT without exposing commercial terms to the government. Produces the `observer_registration_id` in Fiscal J-MDN receipts.

---

## I

**IGTF (Impuesto a las Grandes Transacciones Financieras)**  
Venezuela's large financial transactions tax, applied to certain payment methods (bank transfers, PagoMóvil, Zelle) above threshold amounts. Rate varies (currently ~3%). Captured in `fiscal_totals_ves.total_igtf_ves`.

**ISLR (Impuesto sobre la Renta)**  
Venezuelan income tax. In FideX, ISLR withholding is captured in `GS1_RETENTION_JSON` with `retention_type: "RETENTION_ISLR"`. Governed by *Decreto 1808 Tabla 26*. The buyer withholds a percentage of the vendor's invoice amount and remits it to SENIAT.

**IVA (Impuesto al Valor Agregado)**  
Venezuelan Value Added Tax. Standard rate: 16%. Zero-rated (0%) for essential medicines (*medicamentos esenciales*). IVA withholding is captured in `GS1_RETENTION_JSON` with `retention_type: "RETENTION_IVA"`. Governed by *Providencia 049/056*.

---

## J

**J-MDN (JSON Message Disposition Notification)**  
A receipt document defined in `schemas/jmdn/gs1-jmdn.schema.json`. Unlike domain documents, J-MDN is **flat** (no `kontext_routing` + `payload` envelope). Two stages:
- `NETWORK_DELIVERED` — confirms the AS5 hub received the message (< 2 seconds)
- `FISCAL_CLEARED` — confirms the Government Observer Node registered the fiscal data (< 61 minutes); includes `merkle_proof`

**JOSE (JSON Object Signing and Encryption)**  
Security framework for signing and encrypting JSON payloads. FideX uses:
- **JWS (JSON Web Signature)** — sign documents (non-repudiation)
- **JWE (JSON Web Encryption)** — encrypt payloads in transit (confidentiality)
See `docs/03-security-jose.md`.

---

## K

**Kontext Routing** (`kontext_routing`)  
The AS5 transport envelope at the root of every domain document. Contains: `tenant_id`, `receiver_id`, `document_type`, `correlation_id`. The AS5 Hub reads **only** this layer for routing — it never inspects `payload`. Defined in `schemas/_common/kontext-routing.schema.json`.

---

## L

**Laboratorio** *(pharmaceutical laboratory)*  
A drug manufacturer or license holder — the top tier in the Venezuelan pharma supply chain: **Laboratorio** → Droguería → Farmacia. In FideX documents, typically the `seller`/`biller` in invoices and the sender of orders.

---

## M

**Merkle Root**  
A cryptographic hash summarizing a set of document hashes in a Merkle tree. In FideX catalogs, `previous_merkle_root` and `current_merkle_root` enable "Rsync-style" delta verification. A mismatch triggers a `FULL_SYNC`. In J-MDN fiscal receipts, `merkle_proof` proves inclusion of a specific document in the hourly rollup. See `docs/11-dlt-merkle-anchoring.md`.

**MPPS (Ministerio del Poder Popular para la Salud)**  
Venezuela's Ministry of Health. Issues SICM permits to pharmaceutical distributors and manufacturers.

---

## N

**Número de Control** *(fiscal control number)*  
SENIAT-assigned sequential number for Venezuelan fiscal documents (facturas, notas de crédito/débito). Required on every physical or electronic fiscal document. In FideX: `payload.fiscal_control.fiscal_control_number`.

**Número de Talonario** *(serial/pad number)*  
The sequential series identifier of the fiscal document booklet (talonario). In FideX: `payload.fiscal_control.machine_serial`. Often refers to the fiscal machine or authorization series.

---

## O

**Orden de Compra** *(Purchase Order)*  
The buyer-initiated document requesting goods. In FideX: `GS1_ORDER_JSON` with `doc_type: "PURCHASE_ORDER"`.

**Orden Confirmada** *(Confirmed Order)*  
The buyer's acceptance of a vendor's quote (presupuesto). In FideX: `GS1_ORDER_JSON` with `doc_type: "ORDER_CONFIRMED"`. **Requires** `related_documents` back-referencing the original `QUOTE` — enforced by `if/then` in `gs1-order.schema.json`.

---

## P

**PagoMóvil**  
Venezuelan mobile payment system operated by banks. Requires `bank_code` + `payer_phone` + `confirmation_number` in FideX `applied_payments`.

**Party** (`party`)  
A trading entity in the supply chain: laboratory, distributor, or pharmacy. Defined in `schemas/_common/party.schema.json`. Fields: `name`, `rif`, `gln`, `sicm`, `delivery_address`.

**Presupuesto** *(Quote)*  
The vendor's priced response to a Purchase Order. In FideX: `GS1_ORDER_JSON` with `doc_type: "QUOTE"`. Contains pricing, availability, and lead times. Must be referenced by the subsequent `ORDER_CONFIRMED`.

**Providencia 049 / Providencia 056**  
SENIAT administrative rulings governing IVA withholding by *Contribuyentes Especiales*. Prov. 049 applies to services; Prov. 056 to goods. Both require 75% IVA withholding. Referenced in `docs/08-tax-retention.md`.

---

## R

**Related Documents** (`related_documents`)  
Array of back-references linking a document to prior documents in the transaction chain. Required on `CREDIT_NOTE`, `DEBIT_NOTE`, and `ORDER_CONFIRMED`. Example:  
```json
[{ "doc_type": "INVOICE", "document_number": "INV-2026-00145" }]
```
Defined in `schemas/_common/related-documents.schema.json`.

**Retention** *(Retención)*  
Tax withholding — the buyer deducts a percentage of IVA or ISLR from the vendor's payment and remits it directly to SENIAT. Produces a *Comprobante de Retención* (`GS1_RETENTION_JSON`). Defined in `schemas/retention/gs1-retention.schema.json`.

**Retention Period** (`retention_period`)  
SENIAT-required YYYY-MM field indicating the fiscal month to which a withholding belongs. Pattern: `^[0-9]{4}-(0[1-9]|1[0-2])$`. Example: `"2026-03"`. Never optional on retention documents.

**RIF (Registro de Información Fiscal)**  
Venezuelan taxpayer ID number. Pattern: `^[JVEGPjvegp]-[0-9]{8}-[0-9]$`. Prefixes: `J` = empresa (company), `V` = persona natural (individual), `E` = extranjero (foreign), `G` = gobierno (government), `P` = pasaporte (passport). Required on all fiscal documents.

---

## S

**SENIAT (Servicio Nacional Integrado de Administración Aduanera y Tributaria)**  
Venezuela's national tax authority, equivalent to IRS/HMRC. Governs IVA, ISLR, IGTF, and fiscal document requirements. In FideX, the Government Observer Node provides SENIAT with fiscal visibility without exposing commercial data.

**SICM (Sistema Integral de Control de Medicamentos)**  
Venezuela's pharmaceutical distribution permit issued by MPPS. Required for all parties involved in pharmaceutical distribution. Pattern: `^S-[0-9]+$`. Example: `"S-98765"`. An expired or invalid SICM is a hard block on order processing.

**SSCC (Serial Shipping Container Code)**  
GS1 18-digit identifier for logistics units (pallets, containers). Pattern: `^[0-9]{18}$`. Required in Despatch Advice for pallet-level traceability. Example: `"175912345678901234"`.

**SUDEBAN (Superintendencia de las Instituciones del Sector Bancario)**  
Venezuela's banking regulator. Relevant to FideX through SICM permit validation and PagoMóvil/banking integration.

---

## T

**Talonario** *(fiscal booklet / sequential series)*  
The SENIAT-authorized sequential series for fiscal documents. Each series has a machine serial and a range of authorized document numbers. In FideX: captured in `payload.fiscal_control`.

**Tenant ID** (`tenant_id`)  
The sender's identifier in the FideX AS5 Hub Trading Partner Directory (TPD). Assigned during partner onboarding. Examples: `"tenant-leti-01"`, `"tenant-belo-01"`.

**Three-Way Match**  
The accounting control linking a Purchase Order, a Despatch Advice (ASN), and an Invoice via the same `correlation_id`. All three documents must reference the same `ORD-YYYY-NNNN` to enable automated reconciliation.

---

## U

**`unevaluatedProperties: false`**  
JSON Schema 2020-12 keyword that rejects any property not declared in the schema. Used on all FideX domain schemas as a strict guard against undocumented fields silently passing validation. If you see a validation error like `"unevaluatedProperties"`, you've added a field to an example without declaring it in the schema first.

---

## V

**VES (Bolívar Soberano / Bolívar Digital)**  
The Venezuelan bolívar — the local currency. All commercial calculations are in USD; VES amounts are always derived by multiplying USD amounts by `exchange_rate_applied`. This prevents rounding mismatches when BCV rates fluctuate.

---

## Z

**Zelle**  
US-based peer-to-peer payment service widely used in Venezuela for USD transactions. In FideX `applied_payments`: requires `confirmation_number` and `sender_email`.
