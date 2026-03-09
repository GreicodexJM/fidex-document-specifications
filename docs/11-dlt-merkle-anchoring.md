# 11 — DLT / Merkle Root Anchoring Protocol

> **v1.5 — FideX AS5 Specification**

The DLT anchoring layer provides **Continuous Transaction Controls (CTC)** — an immutable, cryptographically verifiable record of all FideX transactions. It prevents double-invoicing and retrospective tampering while maintaining B2B transmission speeds of < 1.4 seconds.

---

## 11.1 Architecture Overview

```
B2B Transaction                   Background Worker            Blockchain (EVM)
      │                                   │                          │
      │─ invoice transmitted ──────►      │                          │
      │◄─ Technical J-MDN (< 2s) ─        │                          │
      │                                   │                          │
      │         (hourly batch)            │                          │
      │                          ┌──────────────────┐               │
      │                          │  Aggregate hashes │               │
      │                          │  Build Merkle Tree│               │
      │                          │  Compute Root Hash│               │
      │                          └──────────────────┘               │
      │                                   │── anchorHourlyRollup() ─►│
      │                                   │◄─ block confirmation ────│
      │                                   │                          │
      │◄─ Fiscal J-MDN (with Merkle Proof)│                          │
      │                                   │                          │
```

---

## 11.2 Two-Stage Receipt State Machine

Every FideX transaction produces two receipts:

### Stage 1 — Technical J-MDN (`NETWORK_DELIVERED`)

Issued immediately (target **< 2 seconds**) upon successful payload receipt and decryption. Allows logistics/warehouse operations to proceed without waiting for fiscal clearance.

```json
{
  "jmdn_version": "1.0",
  "status": "NETWORK_DELIVERED",
  "message_id": "MSG-20260309-001234",
  "document_ref": "FAC-2026-000123",
  "received_at": "2026-03-09T14:30:00.847Z",
  "payload_hash_sha256": "a3f1b9c8d2e4f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1",
  "receiver_gln": "7599876500001",
  "jws_signature": "<JWS of this receipt using receiver's signing key>"
}
```

### Stage 2 — Fiscal J-MDN (`FISCAL_CLEARED`)

Issued **after** the transaction's Merkle Proof is anchored on the DLT. The sender cannot demand payment without this receipt. Contains the Merkle Proof path enabling independent verification.

```json
{
  "jmdn_version": "1.0",
  "status": "FISCAL_CLEARED",
  "message_id": "MSG-20260309-001234",
  "document_ref": "FAC-2026-000123",
  "cleared_at": "2026-03-09T15:00:03Z",
  "payload_hash_sha256": "a3f1b9c8d2e4f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1",
  "merkle_proof": {
    "leaf_hash": "a3f1b9c8d2e4f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1",
    "tree_root": "m5n6o7p8q9r0s1t2u3v4w5x6y7z8a9b0c1d2e3f4",
    "proof_path": [
      { "position": "right", "hash": "c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0" },
      { "position": "left",  "hash": "e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4" }
    ],
    "anchored_at_block": 9871234,
    "anchor_tx_hash": "0xabc123def456...",
    "anchor_timestamp": "2026-03-09T15:00:01Z"
  },
  "observer_registration_id": "SENIAT-2026-789456",
  "jws_signature": "<JWS of this receipt using Hub's signing key>"
}
```

The receiver uses `proof_path` + `leaf_hash` to independently compute `tree_root` and verify it matches the on-chain `anchorHourlyRollup` record.

---

## 11.3 Merkle Tree Batching (L2-Style Hourly Rollup)

To maintain B2B transmission speeds while avoiding per-transaction blockchain costs:

1. **Hourly batch**: A background worker collects all `payload_hash_sha256` values from the preceding hour
2. **Merkle Tree construction**: Standard binary Merkle Tree with SHA-256 leaf hashes
3. **Root anchoring**: Only the `merkleRoot` (32 bytes) is pushed to the blockchain per hour
4. **Proof generation**: For each transaction, a Merkle Proof (path from leaf to root) is computed and included in the Fiscal J-MDN

```
Hour N transactions:
  [hash_0] [hash_1] [hash_2] [hash_3]
       \    /             \    /
      [h_01]             [h_23]
           \             /
           [merkle_root]  ← anchored on-chain
```

**Gas cost optimization**: Instead of N transactions per hour (~100-500 invoices in a busy droguería), only 1 transaction is pushed to the blockchain. At Polygon Edge block costs, this reduces gas expenditure by 99.8%.

---

## 11.4 Smart Contract Interface

Deployed on an EVM-compatible network (Polygon Edge or Hyperledger Besu):

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFideXAnchor {

    event HourlyRollupAnchored(
        bytes32 indexed merkleRoot,
        string manifestURI,
        uint256 timestamp,
        address anchoredBy
    );

    event DocumentRegistered(
        bytes32 indexed documentHash,
        uint256 blockTimestamp
    );

    /**
     * @notice Anchor an hourly Merkle Root rollup.
     * @param merkleRoot  SHA-256 Merkle Root of all transactions in the hour.
     * @param manifestURI URI pointing to encrypted Tax Manifest archive (S3/Vault).
     */
    function anchorHourlyRollup(
        bytes32 merkleRoot,
        string calldata manifestURI
    ) external;

    /**
     * @notice Verify a document hash is registered (anti-replay).
     * @param documentHash SHA-256 hash of the payload.
     * @return blockTimestamp Block timestamp when hash was registered, 0 if not found.
     */
    function getDocumentTimestamp(bytes32 documentHash)
        external view returns (uint256 blockTimestamp);

    /**
     * @notice Check if a FideX node address is authorized to anchor.
     * @param nodeAddress The node's Ethereum address.
     */
    function isAuthorized(address nodeAddress)
        external view returns (bool);
}
```

**Authorization**: Only FideX Hub node addresses whitelisted by the contract admin can call `anchorHourlyRollup`. This prevents unauthorized anchoring.

**Anti-replay**: The `documentHash → blockTimestamp` mapping prevents the same invoice from being submitted twice. Any attempt to re-anchor a known hash is rejected at the smart contract level.

---

## 11.5 Catalog `sync_state` Merkle Protocol

The `GS1_CATALOG_JSON` schema uses Merkle Roots for inventory synchronization (separate from the DLT anchoring above):

```json
"sync_state": {
  "sequence_id": 1044,
  "previous_merkle_root": "a1b2c3d4e5f6...",
  "current_merkle_root": "m5n6o7p8q9r0...",
  "total_active_skus": 1450
}
```

**Receiver state machine**:

```
Receive DELTA_UPDATE
    │
    ├── receiver_local_root == previous_merkle_root?
    │       │
    │       ├── YES → Apply delta, update local root to current_merkle_root ✅
    │       │
    │       └── NO  → State drift detected
    │               │
    │               └── Request FULL_SYNC (sequence_id sent as context)
    │
Receive FULL_SYNC
    │
    └── Apply all items (UPSERT), set local root = current_merkle_root ✅
```

The `sequence_id` is monotonically increasing. If `sequence_id` jumps by more than 1, the receiver knows it missed delta(s) and triggers a FULL_SYNC proactively.

---

## 11.6 Latency Targets

| Operation | Target | Notes |
|---|---|---|
| Technical J-MDN | < 2 seconds | Required for logistics/forklift operations |
| Merkle Proof batch cycle | 60 minutes | Background worker, does not block B2B flow |
| Fiscal J-MDN | < 61 minutes | Issued after next hourly rollup |
| Blockchain finality | < 2 seconds | Polygon Edge IBFT2 / Besu QBFT consensus |
| SENIAT Observer ACK | < 5 seconds | Government gateway SLA (to be negotiated) |

---

## 11.7 `manifestURI` — Encrypted Manifest Archive

The `manifestURI` stored on-chain points to an encrypted archive of all Tax Manifests from the rollup hour. This enables SENIAT auditors to reconstruct all transactions from the hourly anchor:

```
s3://fidex-compliance-vault/manifests/2026-03-09/rollup-14h.tar.gz.enc
```

The archive is encrypted with AES-256-GCM using a key stored in AWS KMS. The KMS key policy grants access only to SENIAT-authorized IAM principals, providing a compliant long-term audit trail.

---

*See also: `docs/10-government-observer-node.md` (Observer Node extraction), `docs/03-security-jose.md` (JOSE stack and J-MDN format)*
