# Integración FideX con ERP — Índice

> **Versión:** v1.3  
> **Alcance:** Tablas de mapeo de campos y referencias de endpoints API para integrar los seis tipos de documentos FideX/GS1 en cada ERP objetivo de la cadena de suministro farmacéutica venezolana.

> 🇬🇧 [English version](../../09-erp-mapping/00-index.md)

---

## ERPs Soportados

| Guía | ERP | Proveedor | Capa de Integración |
|---|---|---|---|
| [01-odoo-17-18.md](./01-odoo-17-18.md) | Odoo 17 / 18 | Odoo S.A. | JSON-RPC External API / REST |
| [02-profit.md](./02-profit.md) | Profit Plus v12 | Softech C.A. (miprofit.com) | SQL Server directo / COM SDK |
| [03-saint.md](./03-saint.md) | Saint Enterprise v6+ | Business Technology (saintve.com) | API REST / SQL Server |
| [04-galac.md](./04-galac.md) | Galac Software v5+ | Galac Software C.A. | Importación XML/CSV / DLL API |
| [05-sap-business-one.md](./05-sap-business-one.md) | SAP Business One 10.0 | SAP SE | Service Layer REST (puerto 50000) |

---

## Matriz de Tipos de Documentos

Cada tipo de documento FideX se mapea a un objeto nativo en cada ERP soportado:

| `document_type` FideX | Valores `doc_type` | Odoo | Profit | Saint | Galac | SAP B1 |
|---|---|---|---|---|---|---|
| `GS1_CUSTOMER_MASTER_JSON` | `CUSTOMER_MASTER` | `res.partner` | `Clientes` | `ClCliente` | `Clientes` | `OCRD` (C) |
| `GS1_CATALOG_JSON` | `CATALOG_DELTA`, `CATALOG_FULL_SYNC` | `product.template` | `Inventario` | `Inventario` | *No aplica* | `OITM` |
| `GS1_ORDER_JSON` | `PURCHASE_ORDER`, `QUOTE`, `ORDER_CONFIRMED` | `sale.order` / `purchase.order` | `PedidoVentas` | `VePedido` | *Solo importación* | `ORDR` / `OPOR` |
| `GS1_DESPATCH_ADVICE_JSON` | `DESPATCH_ADVICE` | `stock.picking` | `GuiaDespacho` | `VeDespacho` | *No aplica* | `ODLN` |
| `GS1_INVOICE_JSON` | `INVOICE`, `CREDIT_NOTE`, `DEBIT_NOTE` | `account.move` | `Factura` / `NotaCredDeb` | `VeFactura` / Notas | `FactVentas` / `NotasCred` | `OINV` / `ORIN` |
| `GS1_RETENTION_JSON` | `RETENTION_IVA`, `RETENTION_ISLR` | `account.move` (retención) | `ComprobantesRet` | `VeRetencion` | `ComprobantesRet` *(módulo principal)* | UDO `U_RETENCION` / `OWHT` |

---

## Arquitectura de Integración

```
┌──────────────────────────────────────────────────────────────┐
│                    Hub FideX / AS5 (Kontext)                  │
│  ┌─────────────┐    ┌──────────────┐    ┌──────────────────┐  │
│  │  Nivel 1    │ →  │  Nivel 2     │ →  │  Nivel 3         │  │
│  │  Estructural│    │  JSON Schema │    │  Lógica Negocio  │  │
│  │  (formato)  │    │  (AJV)       │    │  (Adaptador ERP) │  │
│  └─────────────┘    └──────────────┘    └──────────────────┘  │
└──────────────────────────────┬───────────────────────────────┘
                               │  Payload GS1 JSON canónico
           ┌───────────────────┼─────────────────────┐
           ▼                   ▼                      ▼
    ┌─────────────┐    ┌──────────────┐    ┌──────────────────┐
    │  Odoo 17/18 │    │ Profit Plus  │    │  SAP B. One 10   │
    │  JSON-RPC   │    │  SQL / COM   │    │  Service Layer   │
    └─────────────┘    └──────────────┘    └──────────────────┘
    ┌─────────────┐    ┌──────────────┐
    │   Saint     │    │    Galac     │
    │  REST / SQL │    │ XML / Import │
    └─────────────┘    └──────────────┘
```

**Responsabilidades del adaptador:**
1. Recibir el JSON FideX canónico del Hub.
2. Extraer y transformar campos al formato nativo del ERP (JSONata o mapeo personalizado).
3. Llamar a la API del ERP para insertar/actualizar el objeto destino.
4. Retornar un ACK de correlación (`document_number` + ID interno del ERP) al Hub.

---

## Campos Fiscales Venezolanos (todos los ERPs)

Estos campos aparecen en múltiples tipos de documentos y requieren tratamiento especial en cada ERP:

| Concepto FideX | Ruta en el payload | Requerimiento en el ERP |
|---|---|---|
| **RIF** (ID fiscal) | `parties.*.rif` | Formato `{J\|V\|G\|E}-########-#`. Validar con dígito verificador SENIAT. |
| **Permiso SICM** | `customer_details.health_permit.sicm` | Bloqueo duro: rechazar órdenes si `permit_status ≠ VALID` o si `expiration_date` venció. |
| **Tasa BCV** | `payment_terms.exchange_rate_pegged` | Almacenar separado del precio base; usada para calcular montos en Bs en el Nivel 3. |
| **IGTF** (3% divisas) | `taxes[].type = "IGTF"` | Código de impuesto separado; no mezclar con IVA. |
| **Retención IVA** | `GS1_RETENTION_JSON` / `RETENTION_IVA` | 75% del monto IVA por defecto para Contribuyentes Especiales (*Agentes de Retención*). |
| **Retención ISLR** | `GS1_RETENTION_JSON` / `RETENTION_ISLR` | Decreto 1808 Tabla 26; la alícuota depende del código de concepto (`retention_code`). |
| **Nro. Comprobante** | `document_info.document_number` | Número secuencial único; transmitido al proveedor para sus libros fiscales. |
