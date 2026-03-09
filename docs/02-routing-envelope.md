# The Routing Envelope — `kontext_routing`

## Purpose

The `kontext_routing` object is the **transport metadata layer** of every FideX document. It is always present at the top level and is the **only** part of the message that the AS5 Hub reads to make routing decisions.

This implements the **Separation of Concerns** principle: the hub knows *where* to deliver the message without ever knowing *what* is inside it.

---

## Schema Reference

See [`schemas/_common/kontext-routing.schema.json`](../schemas/_common/kontext-routing.schema.json)

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

---

## Fields

### `tenant_id`
**Type**: `string` | **Required**: Yes

The sender's tenant identifier registered in the FideX AS5 Hub. This is assigned during the 4-phase partner onboarding handshake and maps to the sender's JWKS public key endpoint.

**Format**: `tenant-{company-slug}-{sequence}`
**Example**: `tenant-leti-01`, `tenant-belo-01`

---

### `receiver_id`
**Type**: `string` | **Required**: Yes

The receiver's partner identifier in the Trading Partner Directory (TPD). The hub uses this to look up the receiver's `message_endpoint` and encryption keys (from their JWKS URI).

**Format**: `partner-{company-slug}`
**Example**: `partner-drogueria-x`, `partner-belo-distribuciones`

---

### `document_type`
**Type**: `enum` | **Required**: Yes

Machine-readable document type. The hub uses this to apply routing rules, JSONata translation maps, and compliance hooks (e.g., triggering the SENIAT observer for invoices).

| Value | Triggers |
|---|---|
| `GS1_CUSTOMER_MASTER_JSON` | ERP `res.partner` upsert adapter |
| `GS1_CATALOG_JSON` | Catalog sync engine + Merkle validation |
| `GS1_ORDER_JSON` | Order lifecycle state machine |
| `GS1_DESPATCH_ADVICE_JSON` | Logistics event + warehouse receiving |
| `GS1_INVOICE_JSON` | Fiscal compliance + SENIAT observer |
| `GS1_RETENTION_JSON` *(v1.1)* | Withholding agent processing |

---

### `correlation_id`
**Type**: `string` | **Required**: Yes

The business correlation key. All documents that belong to the same business transaction share the same `correlation_id`. This enables the hub to link the Order → ASN → Invoice triangle and perform Three-Way Match validation.

**Convention**: Use the original order/transaction number as the anchor:
```
correlation_id = "ORD-2026-9921"   (for the Order)
correlation_id = "ORD-2026-9921"   (for the ASN referencing that order)
correlation_id = "ORD-2026-9921"   (for the Invoice referencing that order)
```

For master data (customer, catalog), use the document's own ID:
```
correlation_id = "CUST-J222222223"
correlation_id = "CAT-2026-03-VE"
```

---

## How the Hub Processes the Routing Envelope

```
Incoming message (JWE encrypted)
    │
    ▼
Hub decrypts outer JWE envelope
    │
    ▼
Hub reads kontext_routing (plaintext layer, before payload decryption)
    │
    ├─ Looks up receiver_id in Trading Partner Directory
    ├─ Selects JSONata translation map for document_type
    ├─ Applies compliance hooks (SENIAT observer for GS1_INVOICE_JSON)
    └─ Forwards encrypted payload to receiver's message_endpoint
         │
         ▼
    Receiver decrypts with their private key
    Receiver validates payload against this repo's schemas
    Receiver returns J-MDN receipt
```

Note: The hub **never decrypts the payload**. It only reads `kontext_routing`. Commercial content (line items, prices, margins) is only ever visible to the sender and receiver.
