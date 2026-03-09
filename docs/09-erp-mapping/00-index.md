# FideX ERP Integration Mapping — Index

> **Version:** v1.2  
> **Scope:** Field-level mapping tables and API endpoint references for integrating the six FideX/GS1 document types into each target ERP used in the Venezuelan pharmaceutical supply chain.

---

## Supported ERPs

| Guide | ERP | Vendor | Integration Layer |
|---|---|---|---|
| [01-odoo-17-18.md](./01-odoo-17-18.md) | Odoo 17 / 18 | Odoo S.A. | JSON-RPC External API / REST |
| [02-profit.md](./02-profit.md) | Profit Plus v12 | Softech C.A. (miprofit.com) | SQL Server direct / COM SDK |
| [03-saint.md](./03-saint.md) | Saint Enterprise v6+ | Business Technology (saintve.com) | REST API / SQL Server |
| [04-galac.md](./04-galac.md) | Galac Software v5+ | Galac Software C.A. | Import XML/CSV / DLL API |
| [05-sap-business-one.md](./05-sap-business-one.md) | SAP Business One 10.0 | SAP SE | Service Layer REST (port 50000) |

---

## Document Family Matrix

Every FideX document type maps to a native ERP object in each supported system:

| FideX `document_type` | `doc_type` values | Odoo | Profit | Saint | Galac | SAP B1 |
|---|---|---|---|---|---|---|
| `GS1_CUSTOMER_MASTER_JSON` | `CUSTOMER_MASTER` | `res.partner` | `Clientes` | `ClCliente` | `Clientes` | `OCRD` (C) |
| `GS1_CATALOG_JSON` | `CATALOG_DELTA`, `CATALOG_FULL_SYNC` | `product.template` | `Inventario` | `Inventario` | `Artículos` | `OITM` |
| `GS1_ORDER_JSON` | `PURCHASE_ORDER`, `QUOTE`, `ORDER_CONFIRMED` | `sale.order` / `purchase.order` | `PedidoVentas` | `PedVentas` | *(import only)* | `ORDR` / `OPOR` |
| `GS1_DESPATCH_ADVICE_JSON` | `DESPATCH_ADVICE` | `stock.picking` | `GuiaDespacho` | `DespachoVentas` | *(not applicable)* | `ODLN` |
| `GS1_INVOICE_JSON` | `INVOICE`, `CREDIT_NOTE`, `DEBIT_NOTE` | `account.move` | `Factura` / `NotaCredDeb` | `Facturas` / `Notas` | `FactVentas` / `NotasCred` | `OINV` / `ORIN` |
| `GS1_RETENTION_JSON` | `RETENTION_IVA`, `RETENTION_ISLR` | `account.move` (retención) | `ComprobantesRet` | `Retenciones` | `ComprobantesRet` *(core)* | Custom `OFPR` / UDT |

---

## Integration Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   FideX / AS5 Hub (Kontext)                  │
│  ┌─────────────┐    ┌─────────────┐    ┌──────────────────┐  │
│  │  Tier 1     │ →  │  Tier 2     │ →  │  Tier 3          │  │
│  │  Structural │    │  JSON Schema│    │  Business Logic  │  │
│  │  (JSON fmt) │    │  (AJV)      │    │  (ERP Adapter)   │  │
│  └─────────────┘    └─────────────┘    └──────────────────┘  │
└──────────────────────────────┬──────────────────────────────┘
                               │  Canonical GS1 JSON payload
           ┌───────────────────┼─────────────────────┐
           ▼                   ▼                      ▼
    ┌─────────────┐    ┌──────────────┐    ┌─────────────────┐
    │  Odoo 17/18 │    │  Profit Plus │    │  SAP Bus. One   │
    │  JSON-RPC   │    │  SQL / COM   │    │  Service Layer  │
    └─────────────┘    └──────────────┘    └─────────────────┘
           ▼
    ┌─────────────┐    ┌──────────────┐
    │   Saint     │    │    Galac     │
    │  REST / SQL │    │  Import API  │
    └─────────────┘    └──────────────┘
```

**Adapter responsibilities:**
1. Receive canonical FideX JSON from the Hub.
2. Extract and transform fields to native ERP format (JSONata or custom mapping).
3. Call the ERP API to upsert/create the target object.
4. Return a correlation ACK (document_number + ERP internal ID) to the Hub.

---

## Venezuelan Fiscal Fields (all ERPs)

These fields appear across multiple document types and require special handling in every ERP:

| FideX concept | Field path | ERP handling requirement |
|---|---|---|
| **RIF** (tax ID) | `parties.*.rif` | Format `{J\|V\|G\|E}-########-#`. Validate using SENIAT check-digit. |
| **SICM permit** | `customer_details.health_permit.sicm` | Hard-block: reject orders if `permit_status ≠ VALID` or past `expiration_date`. |
| **BCV exchange rate** | `payment_terms.exchange_rate_pegged` | Store separately from base price; used to compute Bs amounts at Tier 3. |
| **IGTF** (3% FX tax) | `taxes[].type = "IGTF"` | Separate tax code required; not merged with IVA. |
| **IVA retention** | `GS1_RETENTION_JSON` / `RETENTION_IVA` | 75% of IVA amount by default for special taxpayers (*Agente de Retención*). |
| **ISLR retention** | `GS1_RETENTION_JSON` / `RETENTION_ISLR` | Decree 1808 Tabla 26; rate depends on activity code (`retention_code`). |
| **Comprobante number** | `document_info.document_number` | Must be unique sequential number; transmitted to payee for their fiscal books. |
