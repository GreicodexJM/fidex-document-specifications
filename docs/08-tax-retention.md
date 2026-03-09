# Tax Retention — Comprobante de Retención (IVA & ISLR)

## Overview

Venezuelan tax law requires **Contribuyentes Especiales** (Special Taxpayers designated by SENIAT) to act as withholding agents on behalf of the government. When a Contribuyente Especial pays a supplier, they must withhold a percentage of the taxes and remit those amounts directly to SENIAT — rather than leaving it to the supplier to declare the full tax.

The `GS1_RETENTION_JSON` document type captures this withholding event and produces the legally required **Comprobante de Retención** that the supplier uses as a fiscal credit in their own SENIAT declarations.

### Two Retention Types

| `retention_type` | Venezuelan Name | Legal Basis | Default Rate |
|---|---|---|---|
| `RETENTION_IVA` | Retención de IVA | SENIAT Providencia 049 / 056 | 75% of IVA on invoice |
| `RETENTION_ISLR` | Retención de ISLR | Decreto 1808 (Tabla 26) | Varies by concept (1%–10%) |

---

## Who Must Perform Retentions?

### Retention Agents (`withholder`)
- SENIAT-designated **Contribuyentes Especiales** (large enterprises, major distributors)
- Venezuelan government entities (`entes públicos`) — these retain **100%** of IVA
- Pharmacies and droguerías classified as Contribuyentes Especiales

### Subject to Retention (`withholdee`)
- Any Venezuelan supplier (laboratorio, service provider) regardless of their taxpayer classification
- Foreign suppliers operating in Venezuela

In the pharmaceutical B2B chain, **the droguería (distributor) retains from the laboratory**:

```
Lab Leti issues Invoice: $178.50 USD
  ├── IVA amount: $24.00 USD (16%)
  └── IVA retained by Droguería: $18.00 USD (75% of IVA)

Droguería pays Lab Leti net amount: $178.50 − $18.00 = $160.50 USD
Droguería remits $18.00 USD equivalent in VES to SENIAT by day 15 of next month
```

---

## IVA Retention (`RETENTION_IVA`)

### Calculation

```
IVA amount on invoice = taxable_base × iva_rate
IVA retained          = IVA amount × retention_rate

Example (Example 01):
  taxable_base_usd   = $24.00  (total IVA from INV-2026-00146)
  retention_rate     = 75%
  amount_retained    = $24.00 × 75% = $18.00 USD = $810.00 VES
```

**Special cases:**
- Government entities (`entes públicos`) retain **100%** of IVA
- IVA-exempt line items (e.g., essential medicines under Decreto 3.111) generate **no IVA retention**

### SENIAT Compliance

| Requirement | Value |
|---|---|
| Regulatory basis | Providencia 049 / Providencia 056 |
| Form type | AR-C (Comprobante de Retención de IVA) |
| SENIAT portal | ISENIAT (`iseniat.seniat.gob.ve`) |
| Filing deadline | 15th of the following month |
| Certificate field | `certificate_number` (populated after ISENIAT portal registration) |
| Retention period | `retention_period` (YYYY-MM format) |

### Document Flow

```
Lab Leti                       Droguería Distribuidora X
      │                               │
      │◄── Invoice (INV-00146) ────────│  $178.50 USD (inc. $24 IVA)
      │                               │  [Droguería is Contribuyente Especial]
      │                               │
      │    Droguería calculates:      │
      │    IVA retained = $18.00 USD  │
      │    Net payment  = $160.50 USD │
      │                               │
      │◄── RETENTION_IVA (RET-IVA-12) │  Comprobante sent to Lab
      │    Payment $160.50 ───────────►│
      │                               │
      │                    Droguería ─►│  Remits $18 USD eq. to SENIAT
      │                               │  via ISENIAT portal by April 15
```

---

## ISLR Retention (`RETENTION_ISLR`)

ISLR (Impuesto Sobre la Renta) withholding applies to **income payments** according to the concept codes defined in **Decreto 1808, Tabla 26** (Retención de ISLR).

### Common Concept Codes (Tabla 26 extract)

| Code | Description | Typical Rate |
|---|---|---|
| `1` | Compra de bienes muebles y prestación de servicios | 1% |
| `29` | Servicios de publicidad y propaganda | 1% |
| `31` | Comisiones y demás remuneraciones | 1% |
| `42` | Honorarios profesionales y asimilados | 3% |

> **Note**: Rates vary by supplier type (natural person vs. legal entity) and annual income thresholds. Always confirm with the current SENIAT Tabla 26 before implementation.

### Calculation

```
ISLR retained = gross_payment × concept_rate

Example (Example 02):
  taxable_base_usd   = $157.50  (gross invoice amount)
  islr_concept_code  = "1"      (compra de bienes muebles)
  retention_rate     = 1%
  amount_retained    = $157.50 × 1% = $1.575 ≈ $1.58 USD = $71.10 VES
```

### Document Flow

```
Lab Leti                       Droguería Distribuidora X
      │                               │
      │◄── Invoice (INV-00145) ────────│  $157.50 USD (all IVA-exempt)
      │                               │  [Droguería is Contribuyente Especial]
      │                               │
      │    ISLR (Código 1, 1%):       │
      │    retained = $1.58 USD       │
      │    Net paid = $155.92 USD     │
      │                               │
      │◄── RETENTION_ISLR (RET-ISLR-3)│  Comprobante sent to Lab
      │    Payment $155.92 ───────────►│
      │                               │
      │                    Droguería ─►│  Declares ISLR in ARC portal
      │                               │  (monthly ISLR declaration)
```

---

## The Comprobante de Retención as a Tax Credit

The `withholdee` (Lab Leti) receives the comprobante and uses it to:

1. **Offset IVA payable** — The retained IVA ($18.00) reduces what the lab owes SENIAT in its monthly IVA declaration
2. **Offset ISLR** — The retained ISLR ($1.58) reduces the lab's annual income tax liability

```
Lab's monthly IVA declaration:
  IVA collected from all invoices:  $2,500.00 VES equivalent
  IVA credits (inputs):            ($1,200.00 VES equivalent)
  IVA already retained by buyers:  ($810.00 VES — from RET-IVA-00012)
  Net IVA payable to SENIAT:       $490.00 VES equivalent
```

---

## Schema Structure (`GS1_RETENTION_JSON`)

```
GS1_RETENTION_JSON
├── kontext_routing
│   └── document_type: "GS1_RETENTION_JSON"
│   └── correlation_id: links to the originating order chain
│
└── payload
    ├── document_info
    │   ├── retention_type: "RETENTION_IVA" | "RETENTION_ISLR"
    │   ├── document_number: "RET-IVA-2026-00012"
    │   ├── retention_period: "2026-03"   ← YYYY-MM fiscal period
    │   ├── certificate_number            ← assigned by ISENIAT portal
    │   └── dates: issued_at, payment_date, seniat_submission_date
    │
    ├── parties
    │   ├── withholder  ← Agente de Retención (Contribuyente Especial)
    │   └── withholdee  ← Proveedor retenido
    │
    ├── retention_lines[]  ← one per affected invoice
    │   ├── line_id
    │   ├── related_invoice: { document_number, emission_date, invoice_total_usd }
    │   ├── islr_concept_code      ← only for RETENTION_ISLR
    │   ├── islr_concept_description
    │   ├── taxable_base_usd
    │   ├── retention_rate
    │   ├── amount_retained_usd
    │   ├── exchange_rate_applied
    │   └── amount_retained_ves
    │
    └── summary
        ├── total_taxable_base_usd
        ├── total_retained_usd
        ├── exchange_rate_applied
        └── total_retained_ves
```

---

## Consolidation: Multiple Invoices in One Comprobante

Multiple invoices from the same fiscal period can be settled in a **single comprobante**:

```json
{
  "retention_lines": [
    {
      "line_id": 1,
      "related_invoice": { "document_number": "INV-2026-00145", ... },
      "taxable_base_usd": 24.00,
      "amount_retained_usd": 18.00
    },
    {
      "line_id": 2,
      "related_invoice": { "document_number": "INV-2026-00147", ... },
      "taxable_base_usd": 36.00,
      "amount_retained_usd": 27.00
    }
  ],
  "summary": {
    "total_taxable_base_usd": 60.00,
    "total_retained_usd": 45.00,
    "total_retained_ves": 2025.00
  }
}
```

**Rule**: All `retention_lines` in a single comprobante must belong to the same `retention_period` (YYYY-MM).

---

## Routing Direction

Notice that the `kontext_routing` direction is **reversed** compared to invoices. The **droguería is the sender** (`tenant_id`) and the **laboratory is the receiver** (`receiver_id`):

```json
{
  "kontext_routing": {
    "tenant_id": "tenant-drogueria-x-01",
    "receiver_id": "partner-leti",
    "document_type": "GS1_RETENTION_JSON"
  }
}
```

This reflects the real-world flow: the droguería (withholding agent) produces and delivers the comprobante to the lab (withholdee).

---

## Examples

- [`examples/retention/01-retention-iva.json`](../examples/retention/01-retention-iva.json) — IVA retention (75%) by Droguería X on invoice INV-2026-00146
- [`examples/retention/02-retention-islr.json`](../examples/retention/02-retention-islr.json) — ISLR retention (1%, Código 1) by Droguería X on invoice INV-2026-00145

---

## Related Documents

- [`docs/05-venezuelan-fiscal.md`](05-venezuelan-fiscal.md) — IVA, IGTF, and Venezuelan tax fundamentals
- [`docs/06-document-lifecycle.md`](06-document-lifecycle.md) — Where retention fits in the Order-to-Cash cycle
- [`schemas/retention/gs1-retention.schema.json`](../schemas/retention/gs1-retention.schema.json) — Full JSON Schema definition
- [`schemas/_common/retention-detail.schema.json`](../schemas/_common/retention-detail.schema.json) — Retention line item schema
