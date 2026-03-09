# Seguridad — Marco JOSE (JWS + JWE)

> 🇬🇧 [English version](../03-security-jose.md)

> **Nota**: Este documento describe la capa de seguridad aplicada a los mensajes FideX durante la transmisión. Está implementada en `greicodex/fidex-protocol`, no en este repositorio de especificaciones de payload. Se incluye aquí como contexto para entender el ciclo de vida completo del mensaje.

---

## El Patrón Firma-luego-Cifrado

FideX usa el marco **JOSE** (JSON Object Signing and Encryption) con el patrón:

```
JWE( JWS( payload ) )
```

1. El **emisor firma** el payload con su clave privada → produce un token JWS (prueba de autoría)
2. El JWS firmado se **cifra** con la clave pública del receptor → produce un token JWE (garantiza que solo el receptor puede leerlo)

Esto garantiza:
- **Integridad** — El payload no puede ser alterado en tránsito
- **No Repudio de Origen (NRO)** — El emisor no puede negar haberlo enviado
- **Confidencialidad** — Solo el receptor previsto puede descifrarlo

---

## Estándares Criptográficos

| Capa | Algoritmo | Notas |
|---|---|---|
| Firma JWS (estándar) | `RS256` — RSA + SHA-256 | Amplia compatibilidad |
| Firma JWS (alto rendimiento) | `ES256` — ECDSA + SHA-256 | Preferido para integraciones modernas |
| Cifrado de Clave JWE | `RSA-OAEP-256` | Envoltura asimétrica de clave |
| Cifrado de Contenido JWE | `A256GCM` | Cifrado autenticado (AEAD) |
| Secreto Hacia Adelante JWE | `ECDH-ES+A256KW` | Recomendado para acuerdo de clave efímera |

---

## Gestión de Claves (JWKS)

Los socios exponen sus **claves públicas** en un endpoint estándar:

```
GET /.well-known/jwks.json
```

El Hub FideX realiza **Rotación de Claves sin Tiempo de Inactividad**: cuando un socio rota su par de claves, la nueva clave pública se agrega al JWKS con un nuevo `kid` (ID de clave) mientras la clave antigua permanece válida durante un período de transición. No se requiere intercambio manual de certificados.

---

## El Recibo J-MDN — Reconocimiento en Dos Etapas

Después de recibir un mensaje, el receptor debe emitir un **J-MDN (JSON Message Disposition Notification)** — un recibo firmado criptográficamente.

FideX usa un reconocimiento en **dos etapas** para evitar bloquear la logística física:

### Etapa 1 — J-MDN Técnico (Objetivo: < 2 segundos)
Emitido inmediatamente al:
- Descifrar exitosamente el payload JWE
- Verificar la firma JWS válida
- Confirmar que la estructura del payload cumple con JSON Schema (validación Nivel 1+2)

Este recibo permite que el **camión/entrega proceda inmediatamente**.

```json
{
  "status": "NETWORK_DELIVERED",
  "received_at": "2026-02-28T10:00:01Z",
  "payload_hash_sha256": "abc123...",
  "jmdn_signature": "eyJhbGciOiJFUzI1NiJ9..."
}
```

### Etapa 2 — J-MDN Fiscal (Objetivo: < 1 hora)
Emitido después de que la Prueba Merkle del documento sea anclada en el DLT (libro mayor distribuido) de FideX. Esto confirma:
- El hash de la factura/orden está registrado de forma inmutable
- No es posible ninguna manipulación retroactiva

```json
{
  "status": "FISCAL_CLEARED",
  "merkle_proof": "m3n4o5p6...",
  "anchored_at_block": "0x4a7f3...",
  "ledger_timestamp": "2026-02-28T10:45:00Z"
}
```

---

## Privacidad: El Manifiesto Fiscal Objetivo

Para documentos `GS1_INVOICE_JSON`, el Nodo Observador Gubernamental extrae **únicamente** el bloque `fiscal_totals_ves` y lo cifra por separado usando la clave pública del SENIAT.

```
Factura completa (cifrada JWE para receptor)
    │
    ├── Líneas de detalle comercial → permanece cifrado SOLO para el receptor
    └── fiscal_totals_ves → re-cifrado con la clave pública del SENIAT
                              → enviado al Nodo Observador Gubernamental
```

El SENIAT puede auditar los montos totales de impuestos sin ver precios unitarios, márgenes de productos ni identidades de proveedores. Esto resuelve la **Paradoja de Privacidad** — visibilidad gubernamental sin exponer secretos comerciales.

---

## Incorporación de Socios — Apretón de Manos QR en 4 Fases

Los nuevos socios comerciales pueden ser incorporados en **segundos** con un código QR:

1. **Descubrimiento**: El receptor escanea el QR del emisor → resuelve el JSON `/.well-known/as5-configuration`
2. **Obtención de Claves**: El documento de descubrimiento contiene `jwks_uri` → obtiene las claves públicas automáticamente
3. **Registro**: El emisor hace un POST de una solicitud de registro con un Token de Invitación de corta duración
4. **Confirmación**: Ambas partes intercambian mensajes de prueba firmados para verificar el canal

Sin intercambio manual de claves PGP, sin reuniones de TI, sin semanas de configuración.
