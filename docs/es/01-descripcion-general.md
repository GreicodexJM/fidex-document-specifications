# Descripción General — Arquitectura de Payloads FideX AS5

> 🇬🇧 [English version](../01-overview.md)

---

## ¿Qué problema resuelve esto?

La cadena de suministro farmacéutica venezolana involucra tres niveles de socios comerciales:

```
Laboratorio (Fabricante)
    │
    ├── Droguería 1 (Distribuidor)
    │       ├── Farmacia A
    │       ├── Farmacia B
    │       └── Farmacia C ...
    │
    └── Droguería 2
            └── ...
```

Cada eslabón de esta cadena intercambia documentos comerciales: órdenes, presupuestos, facturas, notas de entrega. Históricamente se enviaban como:
- Archivos CSV/TXT por SFTP (manual, propenso a errores, sin trazabilidad)
- SOAP/XML (AS2/AS4) — integraciones complejas y costosas
- PDFs por correo — legalmente débiles, sin legibilidad por máquina

**FideX** reemplaza todo esto con un estándar moderno y ligero **JSON/REST** (AS5) donde cada documento tiene una estructura predecible y validable.

---

## La Arquitectura de Dos Capas

Cada mensaje FideX está estructurado con exactamente **dos objetos de nivel superior**:

```json
{
  "kontext_routing": { ... },
  "payload": { ... }
}
```

### Capa 1: `kontext_routing` — El Sobre

Piensa en esto como el exterior de un sobre. El servicio postal (Hub AS5) lee la dirección en el exterior para saber dónde entregarlo — nunca abre la carta.

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

- `tenant_id` — ¿Quién envía? (el tenant AS5 del laboratorio)
- `receiver_id` — ¿Quién recibe? (el ID de socio del distribuidor)
- `document_type` — ¿Qué tipo de documento? (usado para reglas de enrutamiento)
- `correlation_id` — ¿A qué hilo de negocio pertenece?

### Capa 2: `payload` — La Carta

El contenido comercial real. Solo el emisor y el receptor (y en ciertos casos, el nodo observador del SENIAT) leen esto. El hub lo enruta sin inspeccionarlo.

```json
{
  "payload": {
    "document_info": { "doc_type": "PURCHASE_ORDER", "document_number": "ORD-2026-9921" },
    "parties": { "seller": {...}, "buyer": {...} },
    "lines": [...],
    "summary": {...}
  }
}
```

---

## Registro de Tipos de Documento

| `document_type` | `payload.document_info.doc_type` | Descripción |
|---|---|---|
| `GS1_CUSTOMER_MASTER_JSON` | `CUSTOMER_MASTER` | Datos maestros del socio comercial |
| `GS1_CATALOG_JSON` | `CATALOG` | Catálogo de productos + precios + inventario |
| `GS1_ORDER_JSON` | `PURCHASE_ORDER` | Solicitud de orden del comprador ("Orden de Compra") |
| `GS1_ORDER_JSON` | `QUOTE` | Propuesta con precio del proveedor ("Presupuesto") |
| `GS1_ORDER_JSON` | `ORDER_CONFIRMED` | El comprador confirma el presupuesto ("Orden Confirmada") |
| `GS1_DESPATCH_ADVICE_JSON` | `DESPATCH_ADVICE` | Aviso de envío con trazabilidad de lotes ("Nota de Entrega") |
| `GS1_INVOICE_JSON` | `INVOICE` | Factura fiscal |
| `GS1_INVOICE_JSON` *(v1.1)* | `CREDIT_NOTE` | Nota de Crédito |
| `GS1_INVOICE_JSON` *(v1.1)* | `DEBIT_NOTE` | Nota de Débito |
| `GS1_RETENTION_JSON` *(v1.1)* | `RETENTION_IVA` | Comprobante de Retención de IVA |
| `GS1_RETENTION_JSON` *(v1.1)* | `RETENTION_ISLR` | Comprobante de Retención de ISLR |

---

## Estructura Estándar del Payload

La mayoría de los documentos siguen esta estructura interna dentro de `payload`:

```
payload
├── document_info      → Versión, doc_type, número de documento, fechas, estado, moneda
├── parties            → vendedor/comprador/despachador/destinatario con RIF, GLN, SICM
├── [logistics]        → Transportista, conductor, vehículo, empaquetado SSCC (para ASN)
├── [payment_terms]    → Método, tipo de plazo, tasa de cambio
├── [applied_payments] → PagoMóvil, Zelle, tarjeta de débito
├── lines[]            → Líneas: producto, cantidad, precio, descuentos, impuestos
└── summary            → Totales en USD + bloque fiscal_totals_ves
```

---

## Integración con el Protocolo FideX

Este repositorio define las **estructuras del payload**. El protocolo FideX (`greicodex/fidex-protocol`) define cómo estos payloads son:
1. **Firmados** con JWS (RS256/ES256) — demostrando el origen
2. **Cifrados** con JWE (RSA-OAEP-256 + A256GCM) — protegiendo el contenido
3. **Transmitidos** vía API REST AS5 — entrega asíncrona
4. **Reconocidos** con recibos J-MDN — no repudio

```
[Odoo/ERP] → Payload JSON (este repositorio)
              → Firma JWS → Cifrado JWE
                → POST /messages (Hub AS5)
                  → Enrutar vía kontext_routing
                    → Entregar al receptor
                      → Recibo J-MDN devuelto
```

Ver [`docs/es/03-seguridad-jose.md`](03-seguridad-jose.md) para detalles criptográficos.
