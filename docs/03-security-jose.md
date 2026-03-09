# Security — JOSE Framework (JWS + JWE)

> **Note**: This document describes the security layer applied to FideX messages during transmission. This is implemented in `greicodex/fidex-protocol`, not in this payload specs repository. It is included here as context for understanding the full message lifecycle.

---

## The Sign-then-Encrypt Pattern

FideX uses the **JOSE** (JSON Object Signing and Encryption) framework with the pattern:

```
JWE( JWS( payload ) )
```

1. The **sender signs** the payload with their private key → produces a JWS token (proves authorship)
2. The signed JWS is then **encrypted** with the receiver's public key → produces a JWE token (ensures only the receiver can read it)

This guarantees:
- **Integrity** — The payload cannot be altered in transit
- **Non-Repudiation of Origin (NRO)** — The sender cannot deny having sent it
- **Confidentiality** — Only the intended receiver can decrypt it

---

## Cryptographic Standards

| Layer | Algorithm | Notes |
|---|---|---|
| JWS Signature (standard) | `RS256` — RSA + SHA-256 | Broad compatibility |
| JWS Signature (high-perf) | `ES256` — ECDSA + SHA-256 | Preferred for modern integrations |
| JWE Key Encryption | `RSA-OAEP-256` | Asymmetric key wrapping |
| JWE Content Encryption | `A256GCM` | Authenticated encryption (AEAD) |
| JWE Forward Secrecy | `ECDH-ES+A256KW` | Recommended for ephemeral key agreement |

---

## Key Management (JWKS)

Partners expose their **public keys** at a standard endpoint:

```
GET /.well-known/jwks.json
```

The FideX Hub performs **Zero-Downtime Key Rotation**: when a partner rotates their keypair, the new public key is added to the JWKS with a new `kid` (key ID) while the old key remains valid for a rotation window. No manual certificate exchange is required.

---

## The J-MDN Receipt — Two-Stage Acknowledgment

After receiving a message, the receiver must issue a **J-MDN (JSON Message Disposition Notification)** — a cryptographically signed receipt.

FideX uses a **two-stage** acknowledgment to avoid blocking physical logistics:

### Stage 1 — Technical J-MDN (Target: < 2 seconds)
Issued immediately upon:
- Successful decryption of the JWE payload
- Valid JWS signature verification
- Payload structure conforms to JSON Schema (Tier 1+2 validation)

This receipt allows the **truck/delivery to proceed** immediately.

```json
{
  "status": "NETWORK_DELIVERED",
  "received_at": "2026-02-28T10:00:01Z",
  "payload_hash_sha256": "abc123...",
  "jmdn_signature": "eyJhbGciOiJFUzI1NiJ9..."
}
```

### Stage 2 — Fiscal J-MDN (Target: < 1 hour)
Issued after the document's Merkle Proof is anchored on the FideX DLT (distributed ledger). This confirms:
- The invoice/order hash is immutably recorded
- No retroactive tampering is possible

```json
{
  "status": "FISCAL_CLEARED",
  "merkle_proof": "m3n4o5p6...",
  "anchored_at_block": "0x4a7f3...",
  "ledger_timestamp": "2026-02-28T10:45:00Z"
}
```

---

## Privacy: The Targeted Tax Manifest

For `GS1_INVOICE_JSON` documents, the Government Observer Node extracts **only** the `fiscal_totals_ves` block and encrypts it separately using SENIAT's public key.

```
Full Invoice (JWE encrypted for receiver)
    │
    ├── Commercial line items → stays encrypted for receiver ONLY
    └── fiscal_totals_ves → re-encrypted with SENIAT's public key
                              → sent to Government Observer Node
```

SENIAT can audit total tax amounts without ever seeing unit prices, product margins, or supplier identities. This resolves the **Privacy Paradox** — government visibility without exposing trade secrets.

---

## Partner Onboarding — 4-Phase QR Handshake

New trading partners can be onboarded in **seconds** with a QR code:

1. **Discovery**: Receiver scans sender's QR code → resolves `/.well-known/as5-configuration` JSON
2. **Key Fetch**: Discovery document contains `jwks_uri` → fetch public keys automatically
3. **Registration**: Sender POSTs a registration request with a short-lived Invite Token
4. **Confirmation**: Both sides exchange signed test messages to verify the channel

No manual PGP key exchange, no IT meetings, no weeks of setup.
