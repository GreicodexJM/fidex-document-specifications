# Overview — FideX AS5 Payload Architecture

## What Problem Does This Solve?

The Venezuelan pharmaceutical supply chain involves three tiers of trading partners:

```
Laboratorio (Manufacturer)
    │
    ├── Droguería 1 (Distributor)
    │       ├── Farmacia A
    │       ├── Farmacia B
    │       └── Farmacia C ...
    │
    └── Droguería 2
            └── ...
```

Each link in this chain exchanges business documents: orders, quotes, invoices, delivery notes. Historically these were sent as:
- CSV/TXT files over SFTP (manual, error-prone, no traceability)
- SOAP/XML (AS2/AS4) — complex, expensive IT integrations
- Email PDFs — legally weak, no machine readability

**FideX** replaces these with a modern, lightweight **JSON/REST** standard (AS5) where every document has a predictable, validated structure.

---

## The Two-Layer Architecture

Every FideX message is structured as exactly **two top-level objects**:

```json
{
  "kontext_routing": { ... },
  "payload": { ... }
}
```

### Layer 1: `kontext_routing` — The Envelope

Think of this like the outside of an envelope. The postal service (AS5 Hub) reads the address on the outside to know where to deliver it — it never opens the letter.

```json
{
  "kontext_routing": {
    "tenant_id": "tenant-leti-01",
    "receiver_id": "partner-drogueria-x",
    "document_type": "GS1_ORDER_JSON",
    "correlation_id": "ORD-2026-9921"
  }
}
```

- `tenant_id` — Who is sending? (the laboratory's AS5 tenant)
- `receiver_id` — Who is receiving? (the distributor's partner ID)
- `document_type` — What kind of document? (used for routing rules)
- `correlation_id` — What business thread does this belong to?

### Layer 2: `payload` — The Letter

The actual business content. Only the sender and receiver (and in certain cases, SENIAT's observer node) ever read this. The hub routes it without inspecting it.

```json
{
  "payload": {
    "document_info": { "doc_type": "PURCHASE_ORDER", "document_number": "ORD-2026-9921" },
    "parties": { "seller": {...}, "buyer": {...} },
    "lines": [...],
    "summary": {...}
  }
}
```

---

## Document Type Registry

| `document_type` | `payload.document_info.doc_type` | Description |
|---|---|---|
| `GS1_CUSTOMER_MASTER_JSON` | `CUSTOMER_MASTER` | Trading partner master data |
| `GS1_CATALOG_JSON` | `CATALOG` | Product catalog + pricing + inventory |
| `GS1_ORDER_JSON` | `PURCHASE_ORDER` | Buyer's order request ("Orden de Compra") |
| `GS1_ORDER_JSON` | `QUOTE` | Vendor's priced proposal ("Presupuesto") |
| `GS1_ORDER_JSON` | `ORDER_CONFIRMED` | Buyer confirms the quote ("Orden Confirmada") |
| `GS1_DESPATCH_ADVICE_JSON` | `DESPATCH_ADVICE` | Ship notice with lot tracking ("Nota de Entrega") |
| `GS1_INVOICE_JSON` | `INVOICE` | Fiscal invoice ("Factura") |
| `GS1_INVOICE_JSON` *(v1.1)* | `CREDIT_NOTE` | Credit note ("Nota de Crédito") |
| `GS1_INVOICE_JSON` *(v1.1)* | `DEBIT_NOTE` | Debit note ("Nota de Débito") |
| `GS1_RETENTION_JSON` *(v1.1)* | `RETENTION_IVA` | IVA withholding |
| `GS1_RETENTION_JSON` *(v1.1)* | `RETENTION_ISLR` | ISLR withholding |

---

## Standard Payload Structure

Most documents follow this internal structure within `payload`:

```
payload
├── document_info      → Version, doc_type, document number, dates, status, currency
├── parties            → seller/buyer/shipper/ship_to with RIF, GLN, SICM
├── [logistics]        → Carrier, driver, vehicle, SSCC packaging (for ASN)
├── [payment_terms]    → Method, term type, exchange rate
├── [applied_payments] → PagoMóvil, Zelle, debit card capture
├── lines[]            → Line items: product, qty, pricing, discounts, taxes
└── summary            → Totals in USD + fiscal_totals_ves block
```

---

## Integration with the FideX Protocol

This repository defines the **payload shapes**. The FideX protocol (`greicodex/fidex-protocol`) defines how these payloads are:
1. **Signed** with JWS (RS256/ES256) — proving origin
2. **Encrypted** with JWE (RSA-OAEP-256 + A256GCM) — protecting content
3. **Transmitted** via AS5 REST API — asynchronous delivery
4. **Acknowledged** with J-MDN receipts — non-repudiation

```
[Odoo/ERP] → JSON Payload (this repo)
              → JWS Sign → JWE Encrypt
                → POST /messages (AS5 Hub)
                  → Route via kontext_routing
                    → Deliver to receiver
                      → J-MDN Receipt returned
```

See [`docs/03-security-jose.md`](03-security-jose.md) for cryptographic details.
