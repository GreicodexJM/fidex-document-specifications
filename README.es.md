# Especificaciones de Documentos FideX (`fidex-document-specs`)

> **Estándar AS5/FideX para Intercambio B2B Farmacéutico — Edición Venezolana y LATAM**

[![Versión del Esquema](https://img.shields.io/badge/versión--esquema-v1.3.0-blue)](CHANGELOG.md)
[![JSON Schema](https://img.shields.io/badge/JSON%20Schema-2020--12-green)](https://json-schema.org/draft/2020-12/schema)
[![Cumplimiento GS1](https://img.shields.io/badge/GS1-LATAM%20Compliant-orange)](docs/es/05-fiscal-venezolano.md)

> 🇬🇧 [English version](README.md)

---

## ¿Qué es este repositorio?

Este repositorio es la **fuente canónica de verdad** para todos los formatos de payload de documentos de negocios intercambiados a través del [protocolo FideX AS5](https://github.com/greicodex/fidex-protocol). Define, valida y documenta la estructura JSON de cada tipo de documento B2B en la cadena de suministro farmacéutica venezolana.

El estándar FideX une el EDI empresarial B2B (GS1/AS5) con los requisitos fiscales venezolanos (SENIAT/SUDEBAN), permitiendo el intercambio de documentos seguro, trazable y legalmente conforme entre laboratorios, distribuidores (droguerías) y farmacias.

---

## 📋 Tipos de Documentos (v1.1 — Ciclo Fiscal Completo)

| Documento | Enum `document_type` | `doc_type` / `retention_type` | Nombre Venezolano | Descripción |
|---|---|---|---|---|
| Ficha de Cliente | `GS1_CUSTOMER_MASTER_JSON` | — | Ficha de Cliente | Datos maestros de farmacias/droguerías con permisos SICM |
| Catálogo de Productos | `GS1_CATALOG_JSON` | `DELTA_UPDATE` / `FULL_SYNC` | Catálogo / Lista de Precios | SKUs, precios multi-nivel, inventario en tiempo real |
| Orden de Compra | `GS1_ORDER_JSON` | `PURCHASE_ORDER` | Orden de Compra | Solicitud iniciada por el comprador |
| Presupuesto | `GS1_ORDER_JSON` | `QUOTE` | Presupuesto | Respuesta cotizada del proveedor |
| Orden Confirmada | `GS1_ORDER_JSON` | `ORDER_CONFIRMED` | Orden Confirmada | Comprador confirma el presupuesto del proveedor |
| Nota de Entrega | `GS1_DESPATCH_ADVICE_JSON` | `DESPATCH_ADVICE` | Nota de Entrega / ASN | Aviso de despacho con trazabilidad de lotes SSCC |
| Factura | `GS1_INVOICE_JSON` | `INVOICE` | Factura | Documento fiscal con cumplimiento multi-moneda SENIAT |
| **Nota de Crédito** | `GS1_INVOICE_JSON` | **`CREDIT_NOTE`** | **Nota de Crédito** | **Reduce una factura previa (devoluciones, ajustes de precio)** |
| **Nota de Débito** | `GS1_INVOICE_JSON` | **`DEBIT_NOTE`** | **Nota de Débito** | **Incrementa una factura previa (cargos omitidos, correcciones)** |
| **Retención IVA** | `GS1_RETENTION_JSON` | **`RETENTION_IVA`** | **Comp. Retención IVA** | **75% retención IVA por Contribuyentes Especiales (Prov. 049/056)** |
| **Retención ISLR** | `GS1_RETENTION_JSON` | **`RETENTION_ISLR`** | **Comp. Retención ISLR** | **Retención ISLR según Decreto 1808 Tabla 26** |

---

## 🗂 Estructura del Repositorio

```
fidex-document-specs/
├── README.md                          # Versión en inglés
├── README.es.md                       # Este archivo (español)
├── CHANGELOG.md                       # Historial de versiones
├── Makefile                           # Comandos para desarrolladores
├── package.json                       # ajv-cli + prettier
│
├── memory-bank/                       # Contexto del proyecto (estándar GOS)
│
├── docs/                              # Documentación en inglés
│   ├── 01-overview.md
│   ├── 02-routing-envelope.md
│   ├── 03-security-jose.md
│   ├── 04-gs1-identifiers.md
│   ├── 05-venezuelan-fiscal.md
│   ├── 06-document-lifecycle.md
│   ├── 07-credit-debit-notes.md
│   ├── 08-tax-retention.md
│   └── 09-erp-mapping/               # Guías de integración ERP (inglés)
│
├── docs/es/                           # Documentación en español (v1.3–1.4)
│   ├── 01-descripcion-general.md      # Arquitectura de dos capas, tipos de documento
│   ├── 02-sobre-de-enrutamiento.md    # kontext_routing campo por campo
│   ├── 03-seguridad-jose.md           # JWS/JWE, JWKS, J-MDN, Manifiesto Fiscal
│   ├── 04-identificadores-gs1.md      # GTIN, GLN, SSCC, SICM, RIF
│   ├── 05-fiscal-venezolano.md        # IVA, IGTF, SENIAT, tasas BCV
│   ├── 06-ciclo-de-documentos.md      # Flujo Orden→Factura→Retención
│   ├── 07-notas-credito-debito.md     # Mecánica fiscal de NC/ND
│   ├── 08-retenciones-fiscales.md     # IVA e ISLR — quién retiene y cómo
│   └── 09-integracion-erp/
│       ├── 00-indice.md               # Matriz ERP × tipo de documento
│       ├── 01-odoo-17-18.md           # Odoo 17/18 — mapeo de campos
│       ├── 02-profit.md               # Profit Plus v12 — SQL/COM SDK
│       ├── 03-saint.md                # Saint Enterprise v6+ — API REST
│       ├── 04-galac.md                # Galac Software v5+ — capa fiscal
│       └── 05-sap-business-one.md     # SAP B1 10.0 — Service Layer REST
│
├── schemas/                           # Esquemas JSON Schema 2020-12
└── examples/                          # Payloads de ejemplo válidos
```

---

## 🚀 Inicio Rápido

### Validar todos los ejemplos contra sus esquemas

```bash
# Instalar dependencias
npm install

# Validar todo
make validate

# Validar un ejemplo específico
make validate-one FILE=examples/invoice/01-invoice-standard.json
```

### Explorar el ciclo de documentos

Consulta [`docs/es/06-ciclo-de-documentos.md`](docs/es/06-ciclo-de-documentos.md) para entender el flujo B2B venezolano completo de orden a cobro:

```
Comprador (Droguería)            Proveedor (Laboratorio)
     │                                    │
     │── PURCHASE_ORDER ────────────────►│  "Orden de Compra"
     │                                    │
     │◄── QUOTE (Presupuesto) ───────────│  Proveedor cotiza
     │                                    │
     │── ORDER_CONFIRMED ───────────────►│  Comprador acepta
     │                                    │
     │◄── DESPATCH_ADVICE (ASN) ─────────│  Mercancía despachada
     │                                    │
     │◄── INVOICE (Factura) ─────────────│  Documento fiscal emitido
     │                                    │
     │◄── NOTA DE CRÉDITO/DÉBITO ────────│  Corrección post-factura (v1.1)
     │                                    │
     │◄── COMPROBANTE DE RETENCIÓN ──────│  Recibo de retención fiscal (v1.1)
     │                                    │
```

---

## 🔌 Integración con ERP (v1.2–1.3)

Ver guías completas en [`docs/es/09-integracion-erp/`](docs/es/09-integracion-erp/):

| ERP | Proveedor | Capa de Integración | Guía |
|---|---|---|---|
| **Odoo 17 / 18** | Odoo S.A. | JSON-RPC + REST (`/web/dataset/call_kw`, `/api/`) | [01-odoo-17-18.md](docs/es/09-integracion-erp/01-odoo-17-18.md) |
| **Profit Plus v12** | Softech C.A. (miprofit.com) | SQL Server directo + `ProfitSDK.dll` COM | [02-profit.md](docs/es/09-integracion-erp/02-profit.md) |
| **Saint Enterprise v6+** | Business Technology (saintve.com) | API REST `/api/v1/` | [03-saint.md](docs/es/09-integracion-erp/03-saint.md) |
| **Galac Software v5+** | Galac Software C.A. | Importación XML + REST *(solo fiscal)* | [04-galac.md](docs/es/09-integracion-erp/04-galac.md) |
| **SAP Business One 10.0** | SAP SE | Service Layer REST (`https://{server}:50000/b1s/v1/`) | [05-sap-business-one.md](docs/es/09-integracion-erp/05-sap-business-one.md) |

---

## 🏗 Principios de Diseño

1. **Separación de Responsabilidades** — El envelope `kontext_routing` transporta metadatos de enrutamiento; `payload` contiene la lógica de negocio. El Hub AS5 enruta sin inspeccionar el contenido sensible.

2. **Enumeraciones en Inglés, Documentación Bilingüe** — Todos los valores legibles por máquina están en inglés (`PENDING`, `SHIPPED`, `PURCHASE_ORDER`). La documentación y los campos `description` son bilingües (EN/ES).

3. **Cumplimiento GS1** — Uso mandatorio de `gtin` (Número Global de Artículo Comercial) y `gln` (Número Global de Localización) para la trazabilidad farmacéutica y el cumplimiento regulatorio LATAM.

4. **Aislamiento Fiscal Venezolano** — Los datos específicos del SENIAT (`fiscal_totals_ves`, `fiscal_control`) están aislados en objetos anidados dedicados, manteniendo el formato viable internacionalmente.

5. **Sincronización por Merkle Root** — Los documentos de catálogo/inventario usan `sync_state` con `previous_merkle_root` / `current_merkle_root` para sincronización auto-correctiva estilo "Rsync".

---

## 📜 Licencia

MIT © Greicodex — Estándar abierto para la cadena de suministro farmacéutica venezolana.
