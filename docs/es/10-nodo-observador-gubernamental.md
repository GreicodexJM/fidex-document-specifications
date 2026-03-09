# 10 — Nodo Observador Gubernamental (Privacy Gateway SENIAT)

> 🇬🇧 [English version](../10-government-observer-node.md)

---

## 10.1 El Problema: La Paradoja de Privacidad

El Hub AS5 de FideX requiere transmitir documentos **cifrados de extremo a extremo** entre las partes. Esto plantea un desafío: ¿cómo puede el SENIAT inspeccionar los totales fiscales sin romper la confidencialidad del canal B2B?

La respuesta es el **Nodo Observador Gubernamental**: un componente del Hub que extrae *únicamente* los datos fiscales obligatorios y los reencripta con la clave pública del SENIAT, sin exponer el contenido comercial del documento.

---

## 10.2 Arquitectura de Dos Opciones

### Opción A — Solo Metadatos (Fase Inicial)

En la fase inicial, el Hub envía únicamente los metadatos del sobre `kontext_routing` al Observador:

```
Laboratorio ──► Hub ──► Droguería
                │
                ▼ (sin descifrar el payload)
         Nodo Observador
                │
                ▼
     SENIAT recibe: message_id, document_type,
     tenant_id, receiver_id, correlation_id, timestamp
```

**Ventaja**: No requiere acceso al payload cifrado.  
**Limitación**: Sin totales fiscales reales (IVA, IGTF, base imponible).

---

### Opción B — Tax Manifest Dirigido (Fase de Producción)

En producción, el Hub descifra el payload (tiene acceso a la clave privada como intermediario de confianza), extrae el bloque `fiscal_totals_ves` y lo **reencripta con la clave pública del SENIAT**:

```
Laboratorio ──[JWE]──► Hub ──[JWE]──► Droguería
                        │
                        ▼ (descifra payload, extrae fiscal_totals_ves)
                 Nodo Observador
                        │
                        ▼ (reencripta con pubkey SENIAT)
                     SENIAT
```

El SENIAT solo puede descifrar el **Tax Manifest** (bloque `fiscal_totals_ves`), nunca el payload comercial completo.

---

## 10.3 Mapa de Extracción JSONata

El Observador usa esta transformación JSONata para extraer los datos fiscales:

```jsonata
{
  "observer_version": "1.0",
  "extracted_at": $now(),
  "routing": {
    "message_id":      kontext_routing.message_id,
    "document_type":   kontext_routing.document_type,
    "correlation_id":  kontext_routing.correlation_id,
    "tenant_id":       kontext_routing.tenant_id,
    "receiver_id":     kontext_routing.receiver_id,
    "timestamp":       kontext_routing.timestamp
  },
  "fiscal_totals":     payload.fiscal_totals_ves,
  "document_ref":      payload.document_info.document_number,
  "doc_type":          payload.document_info.doc_type
}
```

Si `fiscal_totals_ves` es `null` o no existe (documento internacional sin extensión venezolana), el campo `fiscal_totals` se omite del Tax Manifest.

---

## 10.4 Flujo de Reencriptación

```
1. Hub descifra JWE del laboratorio con clave privada del Hub
   └─► Obtiene payload en texto claro

2. Nodo Observador aplica transformación JSONata
   └─► Produce Tax Manifest (solo campos fiscales)

3. Nodo Observador cifra el Tax Manifest con:
   - Algoritmo: ECDH-ES+A256KW (RFC 7518)
   - Clave: Clave pública SECP256R1 del SENIAT (publicada en JWKS del gobierno)

4. Tax Manifest cifrado se transmite al endpoint SENIAT:
   POST https://api.seniat.gob.ve/fidex/manifests
   Authorization: Bearer <token_hub>
   Content-Type: application/jose+json
```

---

## 10.5 Formato del ACK del Observador

Tras recibir el Tax Manifest, el SENIAT emite un **Observer ACK**:

```json
{
  "observer_ack_version": "1.0",
  "status": "RECEIVED",
  "registration_id": "SENIAT-2026-789456",
  "message_id": "MSG-20260309-001234",
  "received_at": "2026-03-09T14:30:05Z",
  "jws_signature": "<JWS con clave privada SENIAT>"
}
```

El `registration_id` del ACK se incluye en el Fiscal J-MDN enviado al emisor original como campo `observer_registration_id`.

---

## 10.6 Requisitos Criptográficos

| Elemento | Especificación |
|---|---|
| Cifrado del Tax Manifest | ECDH-ES+A256KW + A256GCM |
| Clave del SENIAT | SECP256R1 (P-256), obtenida del JWKS gubernamental |
| Firma del Observer ACK | ES256 (SECP256R1) con clave privada SENIAT |
| Rotación de claves SENIAT | Según calendario SENIAT (mínimo anual) |
| Verificación del JWKS | Hub valida `kid` y `exp` en cada transmisión |

---

## 10.7 Garantías de Privacidad

| Dato | ¿Accede el SENIAT? |
|---|---|
| Precios unitarios de línea | ❌ No |
| Condiciones de pago / descuentos | ❌ No |
| Datos de cliente (GLN, SICM, etc.) | ❌ No |
| Total IVA (16%) | ✅ Sí |
| Total IGTF (3%) | ✅ Sí |
| Total ISLR retenido | ✅ Sí |
| Base imponible en VES y USD | ✅ Sí |
| Tasa BCV aplicada | ✅ Sí |
| Número de documento | ✅ Sí |

---

*Ver también: [`docs/es/03-seguridad-jose.md`](03-seguridad-jose.md) (pila JOSE y formato J-MDN), [`docs/es/11-anclaje-dlt-merkle.md`](11-anclaje-dlt-merkle.md) (protocolo de anclaje DLT)*
