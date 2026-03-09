# 11 — Protocolo de Anclaje DLT / Raíz Merkle

> 🇬🇧 [English version](../11-dlt-merkle-anchoring.md)

---

## 11.1 ¿Por qué DLT + Merkle?

El protocolo FideX garantiza la **inmutabilidad retroactiva** de cada transacción B2B: una vez que una factura, orden o retención está "anclada" en la cadena, no puede ser repudiada. Esto es crítico para la fiscalización SENIAT y las auditorías contables.

El mecanismo usa un **rollup por lotes estilo L2**: en vez de anclar cada transacción individualmente (costoso en gas), el Hub agrupa las transacciones de cada hora en un **árbol Merkle** y ancla solo la raíz, reduciendo los costos de gas en un **99,8%**.

---

## 11.2 Máquina de Estados J-MDN de Dos Etapas

Cada documento transmitido por FideX pasa por dos etapas de acuse de recibo:

```
Emisor                    Hub                      Receptor
  │                        │                          │
  │──── Documento JWE ─────►│                          │
  │                        │──── Reenvío JWE ─────────►│
  │                        │                          │
  │◄─ J-MDN Técnico (< 2s)─│◄─ Acuse técnico ─────────│
  │  status: NETWORK_DELIVERED                         │
  │                        │                          │
  │    [Hub espera rollup horario]                     │
  │                        │                          │
  │◄─ J-MDN Fiscal (< 61min│                          │
  │  status: FISCAL_CLEARED│                          │
  │  merkle_proof: {...}   │                          │
```

### Etapa 1 — J-MDN Técnico (`NETWORK_DELIVERED`)

Emitido en menos de **2 segundos** tras la recepción y validación del payload. Permite continuar operaciones logísticas (el camión puede seguir ruta) sin esperar la confirmación fiscal.

```json
{
  "jmdn_version": "1.0",
  "status": "NETWORK_DELIVERED",
  "message_id": "MSG-20260309-001234",
  "document_ref": "FAC-2026-000123",
  "received_at": "2026-03-09T14:30:00.847Z",
  "payload_hash_sha256": "a3f1b9c8d2e4f6a7...",
  "receiver_gln": "7599876500001",
  "jws_signature": "<JWS con clave ES256 del Hub>"
}
```

### Etapa 2 — J-MDN Fiscal (`FISCAL_CLEARED`)

Emitido tras el rollup horario Merkle y el anclaje on-chain. El emisor **no puede exigir el pago** hasta recibir este J-MDN, ya que es la prueba de inmutabilidad fiscal.

```json
{
  "jmdn_version": "1.0",
  "status": "FISCAL_CLEARED",
  "message_id": "MSG-20260309-001234",
  "document_ref": "FAC-2026-000123",
  "cleared_at": "2026-03-09T15:00:03Z",
  "payload_hash_sha256": "a3f1b9c8d2e4f6a7...",
  "merkle_proof": {
    "leaf_hash": "a3f1b9c8d2e4f6a7...",
    "tree_root": "m5n6o7p8q9r0s1t2...",
    "proof_path": [
      { "position": "right", "hash": "c1d2e3f4..." },
      { "position": "left",  "hash": "e5f6a7b8..." }
    ],
    "anchored_at_block": 9871234,
    "anchor_tx_hash": "0xabc123def456...",
    "anchor_timestamp": "2026-03-09T15:00:01Z"
  },
  "observer_registration_id": "SENIAT-2026-789456",
  "receiver_gln": "7599876500001",
  "jws_signature": "<JWS con clave ES256 del Hub>"
}
```

---

## 11.3 Rollup Horario Merkle (Estilo L2)

Para mantener la velocidad B2B evitando costos por transacción en blockchain:

1. **Lote horario**: Un proceso background recolecta todos los `payload_hash_sha256` del intervalo anterior
2. **Construcción del árbol**: Árbol Merkle binario estándar con hojas SHA-256
3. **Anclaje**: Una sola transacción `anchorHourlyRollup(root, hour_iso)` en el contrato `IFideXAnchor`
4. **Generación de pruebas**: Para cada transacción se computa una Merkle Proof (camino de hoja a raíz) que se incluye en el J-MDN Fiscal

### Comparación de Costos

| Estrategia | Transacciones on-chain / hora | Gas estimado / hora |
|---|---|---|
| Por transacción (sin rollup) | 1,000 | ~50,000,000 gas |
| Rollup horario FideX | 1 | ~100,000 gas |
| **Ahorro** | **-99,9%** | **-99,8%** |

---

## 11.4 Interfaz Solidity `IFideXAnchor`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IFideXAnchor — Interfaz de anclaje Merkle para FideX
/// @notice Almacena raíces Merkle horarias de transacciones B2B farmacéuticas.
interface IFideXAnchor {

    /// @notice Emitido cuando se ancla una nueva raíz Merkle.
    event HourlyRollupAnchored(
        bytes32 indexed merkleRoot,
        string  hourIso,
        uint256 txCount,
        uint256 timestamp
    );

    /// @notice Ancla la raíz Merkle del lote horario.
    /// @param merkleRoot Raíz SHA-256 del árbol Merkle del lote.
    /// @param hourIso    Hora ISO 8601 del lote (ej. "2026-03-09T14:00:00Z").
    /// @param txCount    Número de transacciones incluidas en el lote.
    function anchorHourlyRollup(
        bytes32 merkleRoot,
        string calldata hourIso,
        uint256 txCount
    ) external;

    /// @notice Verifica si una raíz Merkle está registrada.
    /// @return true si la raíz existe on-chain.
    function isAnchored(bytes32 merkleRoot) external view returns (bool);

    /// @notice Obtiene los metadatos de un anclaje.
    function getAnchor(bytes32 merkleRoot)
        external
        view
        returns (string memory hourIso, uint256 txCount, uint256 anchoredAt);
}
```

---

## 11.5 Máquina de Estados del Catálogo (`sync_state`)

Los documentos `GS1_CATALOG_JSON` usan `sync_state` para sincronización estilo Rsync. El campo `sync_state` en el receptor progresa así:

```
UNKNOWN ──► DELTA_PENDING ──► IN_SYNC ──► DRIFT_DETECTED ──► FULL_SYNC_REQUIRED
                │                              │
                └────── FULL_SYNC ─────────────┘
```

| Estado | Significado |
|---|---|
| `UNKNOWN` | Estado inicial — sin baseline establecido |
| `DELTA_PENDING` | Delta recibido, aún procesando |
| `IN_SYNC` | Raíz Merkle confirmada — catálogo alineado |
| `DRIFT_DETECTED` | `current_merkle_root` no coincide — delta faltante |
| `FULL_SYNC_REQUIRED` | Deriva acumulada — se requiere baseline completo |

---

## 11.6 Latencias Objetivo

| Evento | Latencia Objetivo |
|---|---|
| J-MDN Técnico (`NETWORK_DELIVERED`) | < 2 segundos |
| Rollup Merkle horario | < 5 minutos tras la hora |
| J-MDN Fiscal (`FISCAL_CLEARED`) | < 61 minutos desde la recepción |
| Observer ACK del SENIAT | < 30 minutos tras el Tax Manifest |

---

*Ver también: [`docs/es/03-seguridad-jose.md`](03-seguridad-jose.md) (pila JOSE y cadena de confianza), [`docs/es/10-nodo-observador-gubernamental.md`](10-nodo-observador-gubernamental.md) (extracción de datos fiscales)*
