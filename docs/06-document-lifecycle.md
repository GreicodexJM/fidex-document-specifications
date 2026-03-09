# Document Lifecycle — Venezuelan B2B Order-to-Cash Flow

## The Venezuelan Purchasing Process

Unlike standard GS1 EDI workflows where a buyer simply sends a Purchase Order and receives an Invoice, the Venezuelan pharmaceutical market follows a **Quote-Based** purchasing cycle:

```
Buyer (Droguería)              Vendor (Laboratorio)
      │                               │
      │  1. PURCHASE_ORDER            │
      │  "Orden de Compra"            │
      │──────────────────────────────►│
      │                               │  (Vendor prices the request,
      │                               │   checks inventory, confirms
      │                               │   availability and pricing)
      │  2. QUOTE                     │
      │  "Presupuesto"                │
      │◄──────────────────────────────│
      │                               │
      │  (Buyer reviews pricing,      │
      │   authorizes payment,         │
      │   confirms the quote)         │
      │                               │
      │  3. ORDER_CONFIRMED           │
      │  "Orden Confirmada"           │
      │──────────────────────────────►│
      │                               │  (Vendor prepares goods,
      │                               │   packs and stages for pickup)
      │  4. DESPATCH_ADVICE           │
      │  "Nota de Entrega / ASN"      │
      │◄──────────────────────────────│
      │                               │
      │  5. INVOICE                   │
      │  "Factura"                    │
      │◄──────────────────────────────│
      │                               │
```

---

## Document 1: `PURCHASE_ORDER` — "Orden de Compra"

**Who sends it**: Buyer (Droguería)
**Who receives it**: Vendor (Laboratorio)
**`document_type`**: `GS1_ORDER_JSON`
**`doc_type`**: `PURCHASE_ORDER`

The buyer sends a request for products they want to purchase. At this stage:
- Pricing is the buyer's **expected** or **last-known** price
- Quantities are desired quantities
- No payment has been committed yet
- `applied_payments` array is empty or absent

**Status flow**: `DRAFT` → `PENDING` → `ACKNOWLEDGED` (by vendor)

**Example**: [`examples/order/01-purchase-order.json`](../examples/order/01-purchase-order.json)

### Key Fields
```json
{
  "document_info": {
    "doc_type": "PURCHASE_ORDER",
    "status": "PENDING"
  },
  "lines": [{
    "qty": { "ordered": 50, "confirmed": null }
  }]
}
```

---

## Document 2: `QUOTE` — "Presupuesto"

**Who sends it**: Vendor (Laboratorio)
**Who receives it**: Buyer (Droguería)
**`document_type`**: `GS1_ORDER_JSON`
**`doc_type`**: `QUOTE`

The vendor responds to the Purchase Order with:
- **Confirmed pricing** (unit prices, applicable discounts)
- **Confirmed available quantities** (may differ from ordered qty if stock is limited)
- **Payment terms** (NET_15, NET_30, CONTADO)
- **Validity period** (the quote is valid until `dates.expiration`)

The `related_order` field links back to the original `PURCHASE_ORDER` document number.

**Status flow**: `PENDING` → `SENT` → `ACCEPTED` / `REJECTED` / `EXPIRED`

**Example**: [`examples/order/02-quote-presupuesto.json`](../examples/order/02-quote-presupuesto.json)

### Key Fields
```json
{
  "document_info": {
    "doc_type": "QUOTE",
    "related_order": "ORD-2026-9921",
    "status": "SENT",
    "dates": {
      "expiration": "2026-03-05T23:59:59Z"
    }
  },
  "lines": [{
    "qty": { "ordered": 50, "confirmed": 45 },
    "pricing": { "unit_price": 2.50, "currency": "USD" },
    "discounts_charges": [...]
  }]
}
```

---

## Document 3: `ORDER_CONFIRMED` — "Orden Confirmada"

**Who sends it**: Buyer (Droguería)
**Who receives it**: Vendor (Laboratorio)
**`document_type`**: `GS1_ORDER_JSON`
**`doc_type`**: `ORDER_CONFIRMED`

The buyer formally accepts the vendor's presupuesto. This document:
- References the QUOTE document number in `related_quote`
- Reflects the **agreed quantities** from the quote (confirmed qty, not originally ordered)
- May include `applied_payments` if payment was made upfront (PagoMóvil, Transferencia)
- Triggers physical order fulfillment on the vendor's side

This is the **binding commercial commitment** — once confirmed, the vendor is authorized to dispatch.

**Status flow**: `CONFIRMED` → `IN_FULFILLMENT`

**Example**: [`examples/order/03-order-confirmed.json`](../examples/order/03-order-confirmed.json)

### Key Fields
```json
{
  "document_info": {
    "doc_type": "ORDER_CONFIRMED",
    "related_order": "ORD-2026-9921",
    "related_quote": "QUO-2026-0155",
    "status": "CONFIRMED"
  },
  "applied_payments": [
    {
      "method": "PAGO_MOVIL",
      "status": "COMPLETED",
      "amounts": { "paid_currency": "VES", "amount_paid": 4500.00 }
    }
  ]
}
```

---

## Document 4: `DESPATCH_ADVICE` — "Nota de Entrega / ASN"

**Who sends it**: Vendor (Laboratorio)
**Who receives it**: Buyer (Droguería)
**`document_type`**: `GS1_DESPATCH_ADVICE_JSON`
**`doc_type`**: `DESPATCH_ADVICE`

When goods leave the vendor's warehouse, this Advance Ship Notice is sent. It provides:
- **Carrier and driver details** (name, national ID, vehicle plate)
- **SSCC** — the pallet barcode for one-scan receiving
- **Lot numbers and expiry dates** per line — mandatory for pharmaceutical traceability
- **Estimated delivery time**

The `related_order` links back to the `ORDER_CONFIRMED` number.

**Status flow**: `PREPARED` → `SHIPPED` → `DELIVERED`

**Example**: [`examples/despatch-advice/01-asn-standard.json`](../examples/despatch-advice/01-asn-standard.json)

---

## Document 5: `INVOICE` — "Factura"

**Who sends it**: Vendor (Laboratorio)
**Who receives it**: Buyer (Droguería)
**`document_type`**: `GS1_INVOICE_JSON`
**`doc_type`**: `INVOICE`

The legal fiscal document. Typically issued simultaneously with or shortly after the ASN. Contains:
- **`related_order`** → links to ORDER_CONFIRMED
- **`related_asn`** → links to DESPATCH_ADVICE
- **Line items** with final invoiced quantities, prices, and taxes
- **`summary.fiscal_totals_ves`** — VES amounts extracted by SENIAT Government Observer
- **`fiscal_control`** (optional) — SENIAT talonario digital fields

**Status flow**: `ISSUED` → `DELIVERED` → `PAID` / `OVERDUE`

**Example**: [`examples/invoice/01-invoice-standard.json`](../examples/invoice/01-invoice-standard.json)

---

## The Correlation Triangle (Three-Way Match)

FideX enforces the **Three-Way Match** through the `correlation_id` and `related_*` fields:

```
kontext_routing.correlation_id = "ORD-2026-9921" (in all 5 documents)

PURCHASE_ORDER:    document_number = "ORD-2026-9921"
QUOTE:             related_order   = "ORD-2026-9921"
ORDER_CONFIRMED:   related_order   = "ORD-2026-9921", related_quote = "QUO-2026-0155"
DESPATCH_ADVICE:   related_order   = "ORD-2026-9921"
INVOICE:           related_order   = "ORD-2026-9921", related_asn = "ASN-88421"
```

When the buyer's ERP receives the Invoice, it can:
1. Find the ORDER_CONFIRMED for `ORD-2026-9921` — confirms quantities were agreed
2. Find the DESPATCH_ADVICE `ASN-88421` — confirms goods were actually shipped
3. Match the invoice amounts against both → **Three-Way Match achieved**

Only when all three match does the ERP authorize payment.

---

## Master Data Prerequisites (Before Any Transaction)

Before transactions can flow, the buyer's master data must be synchronized:

```
[Phase 0: Master Data Setup]
  │
  ├── GS1_CUSTOMER_MASTER_JSON  → Buyer profile in vendor's ERP
  │   (SICM health permit, credit limit, payment terms)
  │
  └── GS1_CATALOG_JSON          → Product catalog in buyer's ERP
      (GTINs, pricing tiers, IVA exemptions, inventory status)
```

If a buyer's `health_permit.permit_status` is not `VALID`, the system **blocks** any PURCHASE_ORDER from being processed. This is enforced at Tier 3 (Business Logic) validation.
