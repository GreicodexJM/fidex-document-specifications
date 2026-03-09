# Credit Notes & Debit Notes — Nota de Crédito / Nota de Débito

## Overview

Credit Notes and Debit Notes are **post-invoice correction documents** that adjust the value of a previously issued `INVOICE`. They use the **same `GS1_INVOICE_JSON` schema** as regular invoices but with a different `doc_type` value and a mandatory `related_documents` back-link to the original invoice.

| `doc_type` | Venezuelan Name | Direction | Purpose |
|---|---|---|---|
| `INVOICE` | Factura | Lab → Droguería | Original fiscal document |
| `CREDIT_NOTE` | Nota de Crédito | Lab → Droguería | **Reduces** a prior invoice amount |
| `DEBIT_NOTE` | Nota de Débito | Lab → Droguería | **Increases** a prior invoice amount |

---

## When to Use Each Document

### Credit Note (`CREDIT_NOTE`)

Issue a Credit Note when:

- **Goods returned** — the buyer returns damaged, expired, or incorrect goods
- **Price adjustment downward** — a negotiated discount was missed on the original invoice
- **Billing error** — an overcharge in quantity or unit price must be corrected
- **Partial cancellation** — the buyer rejects part of the shipment during receiving

### Debit Note (`DEBIT_NOTE`)

Issue a Debit Note when:

- **Missed charges** — freight, cold chain, or handling costs were omitted from the original invoice
- **Price adjustment upward** — the original invoice applied an incorrect (lower) price
- **Additional quantity** — units were shipped per the ASN but not captured in the invoice
- **Currency adjustment** — the BCV rate changed between invoice date and payment processing date

---

## Schema Constraint: `related_documents` is Required

Starting in v1.1, the invoice schema enforces via JSON Schema `if/then` that **any CREDIT_NOTE or DEBIT_NOTE must include the `related_documents` array** in `document_info`. Omitting it will produce a validation error.

```json
{
  "document_info": {
    "doc_type": "CREDIT_NOTE",
    "related_documents": [
      {
        "doc_type": "INVOICE",
        "document_number": "INV-2026-00145",
        "emission_date": "2026-03-11T10:00:00Z",
        "currency_base": "USD",
        "total_amount": 157.50
      }
    ]
  }
}
```

Each entry in `related_documents` references the affected invoice:

| Field | Required | Description |
|---|---|---|
| `doc_type` | ✅ | Always `"INVOICE"` for Credit/Debit Notes |
| `document_number` | ✅ | The original invoice number |
| `emission_date` | ✅ | ISO 8601 emission date of the original invoice |
| `total_amount` | ✅ | Total gross amount of the original invoice |
| `fiscal_series` | Optional | Series letter from `fiscal_control` (required by Unidigital when original has talonario digital) |
| `currency_base` | Optional | Base currency of the original invoice |

---

## Routing & Correlation

Credit and Debit Notes are still routed as `GS1_INVOICE_JSON` — no new `document_type` is needed because the hub routing is identical to an invoice:

```json
{
  "kontext_routing": {
    "document_type": "GS1_INVOICE_JSON",
    "correlation_id": "ORD-2026-9921"
  }
}
```

The `correlation_id` **must remain the same** as the original order chain. This keeps the Three-Way Match triangle intact and allows ERPs to automatically associate the note with the original purchase cycle.

---

## Full Transaction Flow with Credit Note

```
Buyer (Droguería)              Vendor (Laboratorio)
      │                               │
      │── PURCHASE_ORDER ────────────►│
      │◄── QUOTE ─────────────────────│
      │── ORDER_CONFIRMED ───────────►│
      │◄── DESPATCH_ADVICE (ASN) ─────│
      │◄── INVOICE (INV-2026-00145) ──│  $157.50 USD
      │                               │
      │  [5 boxes arrive damaged]     │
      │                               │
      │── Return notification ────────►│
      │                               │
      │◄── CREDIT_NOTE (CN-2026-23) ──│  -$11.25 USD
      │                               │
      │  Net payable: $146.25 USD     │
```

---

## Fiscal Totals in Credit/Debit Notes

The `fiscal_totals_ves` block is **required** in the summary (same as a regular invoice). The Government Observer Node uses it to record the VES-denominated correction in the SENIAT Targeted Tax Manifest. A Credit Note produces a **negative adjustment** to the government's ledger for that fiscal period.

### Credit Note fiscal math (Example 03):

```
line_total_net = 5 units × ($2.50 − 10% discount) = $11.25 USD

fiscal_totals_ves:
  base_imponible_ves = $11.25 × 45.00 = $506.25 VES
  total_iva_ves      = $0.00  (IVA-exempt medicines)
  total_gross_ves    = $506.25 VES
```

### Debit Note fiscal math (Example 04):

```
line_total_net = 10 units × $1.50 = $15.00 USD

IVA (16%) = $15.00 × 0.16 = $2.40 USD
IGTF (3%) = $15.00 × 0.03 = $0.45 USD
total_gross_usd = $15.00 + $2.40 + $0.45 = $17.85 USD

fiscal_totals_ves:
  base_imponible_ves = $15.00 × 45.00 = $675.00 VES
  total_iva_ves      = $2.40  × 45.00 = $108.00 VES
  total_igtf_ves     = $0.45  × 45.00 = $20.25  VES
  total_gross_ves                      = $803.25 VES
```

---

## Document Numbering Convention

| Document | Prefix | Example |
|---|---|---|
| Standard Invoice | `INV-` | `INV-2026-00145` |
| Credit Note | `CN-` | `CN-2026-00023` |
| Debit Note | `DN-` | `DN-2026-00005` |

The numbering sequence is independent per type. A Credit Note does **not** consume an invoice sequence number.

---

## ERP Integration Notes

### Odoo
- Credit Notes map to `account.move` with `move_type = 'out_refund'`
- Debit Notes map to `account.move` with `move_type = 'out_invoice'` (linked to original via `reversed_entry_id`)
- Use `ref` field for `related_documents[0].document_number`

### Profit / Saint
- Both map to "Nota de Crédito/Débito al cliente" documents
- The `related_documents` array provides the "Factura Afectada" reference required for SENIAT reporting

---

## Examples

- [`examples/invoice/03-credit-note.json`](../examples/invoice/03-credit-note.json) — Credit Note for 5 returned boxes of Amoxicilina (IVA-exempt)
- [`examples/invoice/04-debit-note.json`](../examples/invoice/04-debit-note.json) — Debit Note for 10 additional Alcohol Antiséptico units (IVA + IGTF taxable)
