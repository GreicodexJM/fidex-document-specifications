# 12 — JSONata Transformation Maps

> **v1.5 — FideX AS5 Specification**

JSONata transformation maps define how the AS5 Hub translates FideX canonical payloads to/from ERP-native data models and government schemas. They are the "wiring layer" between the universal FideX format and each integration target.

---

## 12.1 Purpose and Scope

| Map Direction | Source → Target | Use Case |
|---|---|---|
| **ERP → FideX** | Odoo/Profit/SAP record → GS1 JSON payload | Outbound: ERP generates order, invoice, retention |
| **FideX → ERP** | GS1 JSON payload → ERP-specific API call | Inbound: Hub delivers payload to receiving ERP |
| **FideX → SENIAT** | Invoice payload → Tax Manifest | Observer Node extraction (see `docs/10`) |
| **FideX → Legacy** | GS1 JSON → CSV/EDI/AS2 | Gateway translation for legacy partners |

---

## 12.2 Directory Convention

```
maps/
├── erp/
│   ├── odoo/
│   │   ├── invoice-to-fidex.jsonata       # Odoo account.move → GS1_INVOICE_JSON
│   │   ├── fidex-to-invoice.jsonata       # GS1_INVOICE_JSON → Odoo account.move
│   │   ├── order-to-fidex.jsonata         # Odoo purchase.order → GS1_ORDER_JSON
│   │   └── fidex-to-order.jsonata         # GS1_ORDER_JSON → Odoo purchase.order
│   ├── profit/
│   │   ├── invoice-to-fidex.jsonata
│   │   └── fidex-to-invoice.jsonata
│   ├── saint/
│   │   └── ...
│   ├── galac/
│   │   └── ...
│   └── sap-b1/
│       └── ...
├── observer/
│   └── invoice-to-tax-manifest.jsonata    # Targeted Tax Manifest (see docs/10)
└── legacy/
    └── fidex-to-csv-orden.jsonata         # FideX order → legacy CSV format
```

---

## 12.3 JSONata Map Conventions

### File Header (Required Comment Block)

Every map file must begin with a metadata comment:

```jsonata
/**
 * @map invoice-to-fidex
 * @source Odoo 17/18 account.move (type: out_invoice)
 * @target GS1_INVOICE_JSON v1.1
 * @direction erp-to-fidex
 * @version 1.0.0
 * @updated 2026-03-09
 */
```

### Transformation Structure

Maps must be pure JSONata expressions that take a single `$` input and produce the target schema root:

```jsonata
{
  "kontext_routing": {
    "tenant_id":      $env.TENANT_ID,
    "sender_gln":     move.company_id.l10n_ve_gln,
    "receiver_gln":   move.partner_id.l10n_ve_gln,
    "document_type":  "GS1_INVOICE_JSON",
    "correlation_id": move.name,
    "priority":       "NORMAL",
    "trace_flags":    []
  },
  "payload": {
    "document_info": {
      "version":         "1.1",
      "doc_type":        "INVOICE",
      "document_number": move.name,
      "status":          move.payment_state = "paid" ? "PAID" : "ISSUED",
      "currency_base":   move.currency_id.name,
      "dates": {
        "issued_at":   move.invoice_date & "T00:00:00Z",
        "due_date":    move.invoice_date_due & "T23:59:59Z"
      }
    },
    "parties": {
      "seller": {
        "name":    move.company_id.name,
        "tax_id":  move.company_id.vat,
        "gln":     move.company_id.l10n_ve_gln
      },
      "buyer": {
        "name":    move.partner_id.name,
        "tax_id":  move.partner_id.vat,
        "gln":     move.partner_id.l10n_ve_gln
      }
    },
    "lines": move.invoice_line_ids.{
      "line_id":   $index + 1,
      "product": {
        "gtin":        product_id.barcode,
        "description": name,
        "vendor_part": product_id.default_code
      },
      "qty": {
        "uom":     product_uom_id.name,
        "ordered": quantity
      },
      "pricing": {
        "unit_price": price_unit,
        "currency":   $$.move.currency_id.name
      },
      "taxes": tax_ids.{
        "tax_type":   $contains(name, "IVA") ? "IVA" : "IGTF",
        "percentage": amount,
        "is_exempt":  amount = 0
      }
    }
  }
}
```

---

## 12.4 Hub → ERP Routing Architecture

When the Hub receives an inbound FideX payload, it:

1. Reads `kontext_routing.document_type` to identify the document class
2. Reads `kontext_routing.receiver_gln` to resolve the receiving ERP adapter
3. Loads the corresponding `fidex-to-{domain}.jsonata` map for that ERP
4. Executes the JSONata transformation
5. Calls the ERP API with the transformed payload

```
Inbound Payload
    │
    ├── document_type: "GS1_INVOICE_JSON"
    ├── receiver_gln: "7599876500001"
    │
    ▼
Hub Adapter Registry
    │
    ├── GLN 7599876500001 → ERP: "odoo_v18"
    │
    ▼
Load: maps/erp/odoo/fidex-to-invoice.jsonata
    │
    ▼
Execute transformation → Odoo API payload
    │
    ▼
POST /api/account.move (Odoo REST API)
    │
    ▼
Technical J-MDN (NETWORK_DELIVERED)
```

---

## 12.5 Standard Map Inputs

All maps receive the same root input object:

```jsonata
/* Input $:
{
  "kontext_routing": { ... },   // Full routing envelope
  "payload": { ... },           // Document payload
  "$env": {                     // Runtime context injected by Hub
    "TENANT_ID": "leti-001",
    "SENDER_GLN": "7591234500001",
    "RECEIVER_GLN": "7599876500001",
    "RECEIVED_AT": "2026-03-09T14:30:00Z",
    "MESSAGE_ID": "MSG-20260309-001234",
    "BCV_RATE": 45.0,           // BCV exchange rate at time of processing
    "BCV_RATE_DATE": "2026-03-09"
  }
}
*/
```

The `$env` object is injected by the Hub at runtime and provides access to BCV exchange rates, tenant configuration, and message metadata without embedding these in the payload itself.

---

## 12.6 Tax Manifest Map Reference

The Observer Node map (`maps/observer/invoice-to-tax-manifest.jsonata`) is documented in `docs/10-government-observer-node.md §10.3`.

Key extraction rules:
- **Include**: `fiscal_totals_ves`, `fiscal_control`, sender/receiver RIF+GLN, document timestamps
- **Exclude**: All `payload.lines` data (descriptions, prices, quantities, GTINs)
- **Conditional**: `third_party_totals` only when `fiscal_totals_ves.third_party` is present

---

## 12.7 Error Handling in Maps

Maps must handle missing optional fields gracefully using JSONata's `?` safe navigation:

```jsonata
/* Good — handles missing field */
"fiscal_control_number": payload.fiscal_control.control_number ? payload.fiscal_control.control_number : null

/* Bad — throws if fiscal_control is absent */
"fiscal_control_number": payload.fiscal_control.control_number
```

When a required field is absent (e.g., `payload.document_info.document_number` = `""`), the map should return `null` for the entire document. The Hub intercepts `null` output and generates an error J-MDN back to the sender.

---

## 12.8 Testing Maps

Each map should have a corresponding test fixture in `maps/{dir}/{name}.test.json`:

```json
{
  "description": "Odoo invoice to FideX — standard taxable invoice",
  "input": {
    "move": { "...": "odoo raw record" },
    "$env": { "TENANT_ID": "test-tenant", "BCV_RATE": 45.0 }
  },
  "expected": {
    "kontext_routing.document_type": "GS1_INVOICE_JSON",
    "payload.document_info.doc_type": "INVOICE",
    "payload.lines[0].product.gtin": "7591234567890"
  }
}
```

Run map tests with:

```bash
make test-maps
```

(Target to be implemented in `greicodex/fidex-hub` — not in this specification repository)

---

*See also: `docs/09-erp-mapping/` (ERP field-level mappings), `docs/10-government-observer-node.md` (Observer tax extraction map)*
