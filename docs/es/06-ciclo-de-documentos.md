# Ciclo de Vida de Documentos FideX

> 🇬🇧 [English version](../06-document-lifecycle.md)

Este documento describe el flujo completo de documentos B2B en la cadena de suministro farmacéutica venezolana usando el estándar FideX/AS5.

---

## Flujo Principal: Orden a Cobro

```
Comprador (Droguería / Farmacia)      Proveedor (Laboratorio)
            │                                    │
            │── PURCHASE_ORDER ────────────────►│
            │   GS1_ORDER_JSON                  │  Vendor recibe la OC
            │   doc_type: PURCHASE_ORDER         │
            │                                    │
            │◄── QUOTE ─────────────────────────│
            │   GS1_ORDER_JSON                  │  Proveedor cotiza
            │   doc_type: QUOTE                  │
            │                                    │
            │── ORDER_CONFIRMED ───────────────►│
            │   GS1_ORDER_JSON                  │  Comprador acepta
            │   doc_type: ORDER_CONFIRMED        │
            │                                    │
            │◄── DESPATCH_ADVICE ───────────────│
            │   GS1_DESPATCH_ADVICE_JSON         │  Mercancía en camino
            │   doc_type: DESPATCH_ADVICE        │
            │                                    │
            │◄── INVOICE ───────────────────────│
            │   GS1_INVOICE_JSON                │  Factura fiscal
            │   doc_type: INVOICE               │
            │                                    │
            │◄── CREDIT_NOTE (opcional) ────────│  v1.1
            │   GS1_INVOICE_JSON                │  Corrección post-factura
            │   doc_type: CREDIT_NOTE           │
            │                                    │
            │── RETENTION_IVA / RETENTION_ISLR ►│  v1.1
            │   GS1_RETENTION_JSON              │  Comprobante de retención
```

---

## Estados del Documento por Tipo

### Orden (`GS1_ORDER_JSON`)

| Estado (`status`) | Significado | `doc_type` que lo origina |
|---|---|---|
| `DRAFT` | Borrador no enviado | `PURCHASE_ORDER` / `QUOTE` |
| `PENDING` | Enviado, esperando respuesta | `PURCHASE_ORDER` |
| `QUOTED` | Presupuesto enviado por vendedor | `QUOTE` |
| `CONFIRMED` | Orden aceptada por comprador | `ORDER_CONFIRMED` |
| `PARTIALLY_FULFILLED` | Despacho parcial realizado | *(transición interna)* |
| `FULFILLED` | Totalmente despachado | *(transición interna)* |
| `CANCELLED` | Orden cancelada | *(cualquier estado anterior)* |

### Nota de Entrega (`GS1_DESPATCH_ADVICE_JSON`)

| Estado | Significado |
|---|---|
| `CREATED` | ASN creado en el sistema del proveedor |
| `IN_TRANSIT` | Mercancía en camino |
| `DELIVERED` | Recibido en destino |
| `PARTIALLY_DELIVERED` | Recepción parcial |

### Factura (`GS1_INVOICE_JSON`)

| Estado | Significado |
|---|---|
| `DRAFT` | Factura en borrador |
| `ISSUED` | Factura emitida y enviada |
| `ACKNOWLEDGED` | Recibida por el comprador (J-MDN) |
| `PARTIALLY_PAID` | Pago parcial recibido |
| `PAID` | Totalmente pagada |
| `CANCELLED` | Anulada |

---

## Documentos Relacionados y Encadenamiento

Cada documento FideX puede referenciar documentos anteriores en el campo `related_documents`:

```json
"related_documents": [
  {
    "document_type": "GS1_ORDER_JSON",
    "doc_type": "PURCHASE_ORDER",
    "document_number": "ORD-2026-9921",
    "relation_type": "FULFILLS"
  },
  {
    "document_type": "GS1_DESPATCH_ADVICE_JSON",
    "doc_type": "DESPATCH_ADVICE",
    "document_number": "ASN-2026-0041",
    "relation_type": "REFERENCES"
  }
]
```

**Tipos de relación (`relation_type`):**

| Valor | Significado |
|---|---|
| `FULFILLS` | Este documento cumple/atiende el documento referenciado |
| `CORRECTS` | Este documento corrige el documento referenciado (NC/ND) |
| `REFERENCES` | Este documento hace referencia informativa |
| `REPLACES` | Este documento reemplaza el referenciado (en caso de anulación y re-emisión) |

---

## Ciclo de Retención Fiscal

Las retenciones se emiten **siempre en dirección opuesta** al flujo de pago:

```
Laboratorio (proveedor)            Droguería (Agente de Retención)
        │                                      │
        │◄── INVOICE ──────────────────────────│
        │   Factura emitida por el laboratorio  │
        │                                       │
        │◄── RETENTION_IVA ─────────────────────│
        │   GS1_RETENTION_JSON                  │  75% del IVA retenido
        │   doc_type: RETENTION_IVA             │
        │                                       │
        │◄── RETENTION_ISLR ────────────────────│
        │   GS1_RETENTION_JSON                  │  Decreto 1808 Tabla 26
        │   doc_type: RETENTION_ISLR            │
```

El número de comprobante (`document_number`) de la retención debe ser entregado al laboratorio para que lo registre en su **Libro de Compras de IVA** como crédito fiscal.

---

## Identificadores de Correlación

Cada documento del ciclo lleva estos campos de correlación en `kontext_routing`:

| Campo | Descripción |
|---|---|
| `tenant_id` | RIF del emisor del documento (el que firma y envía) |
| `recipient_id` | RIF del receptor del documento |
| `correlation_id` | UUID único de la transacción de negocios (se mantiene en todos los documentos del mismo ciclo) |
| `message_id` | UUID único de este mensaje específico |
| `document_number` | Número de documento de negocios (número de factura, número de OC, etc.) |

El `correlation_id` es la clave para agrupar todos los documentos de un mismo ciclo de compra en el Hub FideX.
