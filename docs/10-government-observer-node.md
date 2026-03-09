# 10 — Government Observer Node

> **v1.5 — FideX AS5 Specification**

The Government Observer Node is the privacy-preserving bridge between private B2B transactions and government fiscal oversight (SENIAT). It solves the **Privacy Paradox**: allowing the tax authority to verify fiscal liability without accessing commercially sensitive line-item data.

---

## 10.1 Architecture Overview

```
Sender (Lab)          AS5 Hub              Observer Node           SENIAT Gateway
    │                    │                       │                       │
    │── JWE(JWS(invoice))──►│                       │                       │
    │                    │── forward to Receiver ──►│ (copy)               │
    │                    │                       │                       │
    │                    │               extract fiscal_totals_ves       │
    │                    │               re-encrypt with SENIAT pubkey   │
    │                    │                       │── Tax Manifest JWE ──►│
    │                    │                       │                       │
    │                    │                       │◄── Observer ACK ───────│
    │                    │                       │                       │
```

The Observer Node operates as a **passive tap** on the AS5 Hub. It receives a copy of every `GS1_INVOICE_JSON` message (post-decryption within the Hub's KMS boundary), extracts fiscal metadata, and forwards a **Targeted Tax Manifest** to the government endpoint.

---

## 10.2 Implementation Modes

### Option A — Lightweight Metadata Notification

Minimal footprint for compliance environments where SENIAT only requires transaction registration (no fiscal amounts):

```json
{
  "observer_version": "1.0",
  "notification_type": "METADATA_ONLY",
  "transaction": {
    "message_id": "MSG-20260309-001234",
    "sender_gln": "7591234500001",
    "receiver_gln": "7599876500001",
    "document_type": "GS1_INVOICE_JSON",
    "payload_hash_sha256": "a3f1b9c8d2e4f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1",
    "issued_at": "2026-03-09T14:30:00Z",
    "merkle_proof": {
      "leaf_hash": "a3f1b9c8d2e4f6...",
      "tree_root": "m5n6o7p8q9r0s1t2..."
    }
  }
}
```

### Option B — High-Value Targeted Tax Manifest (Recommended)

Full fiscal extraction encrypted with SENIAT's public key. Only SENIAT holds the private key to decrypt:

```json
{
  "observer_version": "1.0",
  "notification_type": "TARGETED_TAX_MANIFEST",
  "manifest_jwe": "<JWE encrypted with SENIAT RSA-OAEP-256 pubkey>",
  "manifest_hash_sha256": "b4d7e9f2a5c8...",
  "merkle_proof": {
    "leaf_hash": "a3f1b9c8d2e4...",
    "tree_root": "m5n6o7p8q9r0...",
    "proof_path": ["c1d2e3f4...", "e5f6a7b8..."]
  }
}
```

The `manifest_jwe` decrypts (at SENIAT) to a **Targeted Tax Manifest** (see §10.4).

---

## 10.3 Extraction Logic (JSONata)

The Observer Node uses a JSONata transformation map to extract fiscal fields from the invoice payload. Line-item descriptions, unit prices, and proprietary SKU data are **excluded**.

Reference map: `maps/observer/invoice-to-tax-manifest.jsonata`

```jsonata
{
  "document_ref": payload.document_info.document_number,
  "document_type": kontext_routing.document_type,
  "doc_type": payload.document_info.doc_type,
  "issued_at": payload.document_info.dates.issued_at,
  "fiscal_period": $substring(payload.document_info.dates.issued_at, 0, 7),
  "sender": {
    "rif": payload.parties.seller.tax_id,
    "gln": payload.parties.seller.gln,
    "name": payload.parties.seller.name
  },
  "receiver": {
    "rif": payload.parties.buyer.tax_id,
    "gln": payload.parties.buyer.gln
  },
  "fiscal_totals": payload.fiscal_totals_ves ? {
    "tax_base_ves": payload.fiscal_totals_ves.tax_base_ves,
    "iva_amount_ves": payload.fiscal_totals_ves.iva_amount_ves,
    "igtf_amount_ves": payload.fiscal_totals_ves.igtf_amount_ves,
    "exempt_amount_ves": payload.fiscal_totals_ves.exempt_amount_ves,
    "grand_total_ves": payload.fiscal_totals_ves.grand_total_ves,
    "bcv_exchange_rate": payload.fiscal_totals_ves.bcv_exchange_rate,
    "rate_date": payload.fiscal_totals_ves.rate_date
  } : null,
  "fiscal_control": payload.fiscal_control ? {
    "series": payload.fiscal_control.series,
    "control_number": payload.fiscal_control.control_number
  } : null,
  "third_party_totals": payload.fiscal_totals_ves.third_party ? {
    "exempt_third_ves": payload.fiscal_totals_ves.third_party.exempt_amount_third_ves,
    "tax_base_third_ves": payload.fiscal_totals_ves.third_party.tax_base_third_ves,
    "iva_third_ves": payload.fiscal_totals_ves.third_party.iva_amount_third_ves
  } : null
}
```

**What is excluded** (never sent to SENIAT):
- `payload.lines` — product descriptions, quantities, unit prices
- `payload.parties.seller.internal_code` — internal ERP identifiers
- `payload.applied_payments` — bank account details
- Any `vendor_part` or `brand_name` SKU data

---

## 10.4 Targeted Tax Manifest Schema

The plaintext structure of the manifest encrypted in `manifest_jwe`:

```json
{
  "manifest_version": "1.0",
  "document_ref": "FAC-2026-000123",
  "document_type": "GS1_INVOICE_JSON",
  "doc_type": "INVOICE",
  "issued_at": "2026-03-09T14:30:00Z",
  "fiscal_period": "2026-03",
  "sender": {
    "rif": "J-30000000-1",
    "gln": "7591234500001",
    "name": "Laboratorios LETI S.A.C.A."
  },
  "receiver": {
    "rif": "J-22222222-3",
    "gln": "7599876500001"
  },
  "fiscal_totals": {
    "tax_base_ves": 450000.00,
    "iva_amount_ves": 67500.00,
    "igtf_amount_ves": 0.00,
    "exempt_amount_ves": 0.00,
    "grand_total_ves": 517500.00,
    "bcv_exchange_rate": 45.0,
    "rate_date": "2026-03-09"
  },
  "fiscal_control": {
    "series": "A",
    "control_number": "00-00000123"
  },
  "third_party_totals": null
}
```

---

## 10.5 Observer ACK Format

After the government gateway registers the manifest, it returns a signed Observer ACK:

```json
{
  "ack_type": "OBSERVER_ACK",
  "status": "FISCAL_REGISTERED",
  "document_ref": "FAC-2026-000123",
  "registered_at": "2026-03-09T14:30:02Z",
  "registration_id": "SENIAT-2026-789456",
  "merkle_anchor": {
    "tree_root": "m5n6o7p8q9r0s1t2...",
    "anchored_at_block": 9871234,
    "anchor_tx_hash": "0xabc123..."
  }
}
```

`status` values:
| Value | Meaning |
|---|---|
| `FISCAL_REGISTERED` | Document hash recorded by SENIAT |
| `FISCAL_DUPLICATE` | Hash already registered — possible replay attack |
| `FISCAL_REJECTED` | Manifest failed SENIAT validation (missing `fiscal_control` on taxable invoice) |
| `GATEWAY_UNAVAILABLE` | SENIAT gateway offline — retry with exponential backoff |

---

## 10.6 Privacy Guarantees

| Data | Sent to SENIAT? | Notes |
|---|---|---|
| Fiscal totals (VES) | ✅ Yes | Aggregated totals only, not per-line |
| Exchange rate (BCV) | ✅ Yes | Required for VES→USD reconciliation |
| Sender/Receiver RIF + GLN | ✅ Yes | Required for fiscal identity |
| Fiscal control (series/number) | ✅ Yes | Required for SENIAT audit trail |
| Line-item descriptions | ❌ No | Trade secret protection |
| Unit prices | ❌ No | Trade secret protection |
| Quantity per SKU | ❌ No | Commercial intelligence |
| Payment method/bank details | ❌ No | PII / financial privacy |

---

## 10.7 Re-encryption Flow

```
1. Hub KMS decrypts incoming JWE(JWS(invoice)) using tenant private key
2. Observer module receives cleartext invoice payload (within KMS boundary)
3. JSONata map extracts Targeted Tax Manifest (§10.3)
4. Observer signs manifest: JWS(manifest) using FideX Hub signing key
5. Observer encrypts: JWE(JWS(manifest)) using SENIAT's public key (RSA-OAEP-256)
6. Encrypted manifest posted to SENIAT gateway endpoint
7. Observer ACK received and stored — triggers Fiscal J-MDN to original sender
```

The **Fiscal J-MDN** (stage 2 of the two-stage receipt state machine) is issued only after step 7 succeeds. See `docs/11-dlt-merkle-anchoring.md` for the full two-stage ACK protocol.

---

## 10.8 Cryptographic Requirements

| Operation | Algorithm | Notes |
|---|---|---|
| Manifest signing (FideX) | JWS RS256 or ES256 | Proves manifest originated from Hub |
| Manifest encryption (SENIAT pubkey) | JWE RSA-OAEP-256 + A256GCM | Only SENIAT can decrypt |
| SENIAT JWKS discovery | `GET /.well-known/jwks.json` | Hub must cache with TTL 24h |
| Forward secrecy (recommended) | ECDH-ES+A256KW | For SENIAT environments supporting ECDH |

---

*See also: `docs/03-security-jose.md` (JOSE stack), `docs/11-dlt-merkle-anchoring.md` (Merkle batching and Fiscal J-MDN)*
