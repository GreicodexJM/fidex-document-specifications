# ERP Mapping: Galac Software v5+

> **ERP:** Galac Software v5 (Windows desktop — accounting and fiscal focus)  
> **Vendor:** Galac Software C.A. — https://galac.com.ve  
> **Integration layer:** Galac Import XML/TXT wizard; Galac API DLL (`GalacSDK.dll`) for v5 programmatic access  
> **Database engine:** Firebird SQL (embedded) or SQL Server (enterprise edition)

---

## Overview

Galac is primarily an **accounting and Venezuelan fiscal compliance** platform, not a full ERP. Its strength is in:

- Libros de Ventas / Compras (SENIAT IVA reporting books)  
- Comprobantes de Retención IVA (Providencia 049/056) and ISLR (Decreto 1808)  
- Declaraciones de IVA (forma 30) and ISLR  

Galac does **not** natively manage inventory, purchase orders, or dispatch advice. The FideX adapter for Galac focuses on the **fiscal document layer only**: invoices, credit/debit notes, and retentions.

---

## API / Integration Reference

| Mechanism | When to use | Endpoint / Method |
|---|---|---|
| **Galac Import XML** | Importing invoices and retentions in bulk | File upload via Galac → Importar → Facturas/Retenciones |
| **Galac Import TXT/CSV** | Legacy bulk import for older versions | Galac → Herramientas → Importar Datos |
| **Galac SDK DLL** (`GalacSDK.dll`) | Programmatic creation of documents from v5 | COM interop; call `GalacSDK.Factura.Crear(...)` |
| **Galac API REST** *(v5.4+, cloud edition)* | Cloud-hosted Galac deployments | Base: `https://{galac-server}/api/v1/` |

**Galac Import XML format** (for invoices) must conform to the Galac XML schema. The FideX adapter generates this XML from the canonical GS1 JSON.

**Galac Import REST (v5.4+ cloud):**
```
POST /api/v1/auth/token
{ "username": "fidex_adapter", "password": "••••••", "company_id": "LETI-01" }
→ { "token": "eyJ..." }

POST /api/v1/facturas
Authorization: Bearer {token}
Content-Type: application/json
```

---

## 1. Customer Master → `Clientes` / `Proveedores`

Galac manages customers (for invoice recipients) and suppliers (for retention subjects) separately.

| FideX field | Type | Galac field | Notes |
|---|---|---|---|
| `customer_details.internal_id` | string | `CodCliente` | Alphanumeric; max 12 chars |
| `customer_details.name` | string | `RazonSocial` | Legal name; max 100 chars |
| `customer_details.commercial_name` | string | `NombreComercial` | |
| `customer_details.tax_id` | string | `RIF` | Format `J-########-#`; validated by Galac |
| `customer_details.health_permit.sicm` | string | `NotasCliente` | Free-text notes field |
| `contact_info.email` | string | `Email` | |
| `contact_info.phone` | string | `Telefono` | |
| `financial_profile.payment_terms.net_days` | number | `DiasCredito` | |
| `financial_profile.tax_profile.is_retention_agent_iva` | boolean | `AgenteRetencion` | Marks client as IVA retention agent |
| `financial_profile.tax_profile.retention_percentage` | number | `PorcentajeRetencion` | Default 75.00 |
| `addresses[0].street` | string | `Direccion` | |
| `addresses[0].city` | string | `Ciudad` | |
| `addresses[0].state` | string | `Estado` | |

> **Note:** Galac does not have a SICM / GLN concept natively. Store these in `NotasCliente` (free text) for reference only; Tier 3 validation is handled upstream by the FideX Hub, not by Galac.

---

## 2. Catalog → Not applicable

Galac does not manage a product catalog or inventory. Product details (GTIN, description, UoM) are embedded within each invoice line. No upsert step is needed; product data flows directly into invoice line items.

---

## 3. Order → Not applicable

Galac does not process purchase orders. Orders remain in the upstream ERP (Profit, Saint, or Odoo). Galac receives only the resulting **invoice** after the order is fulfilled.

---

## 4. Despatch Advice → Not applicable

No warehouse management in Galac.

---

## 5. Invoice / Credit Note / Debit Note → `FacturasVentas` / `NotasCredito` / `NotasDebito`

This is the **primary integration point** for Galac. The FideX adapter converts `GS1_INVOICE_JSON` into Galac's import format.

**`doc_type` → Galac document type:**

| FideX `doc_type` | Galac document | Galac endpoint / import type |
|---|---|---|
| `INVOICE` | `FacturaVenta` | `POST /api/v1/facturas` or XML import |
| `CREDIT_NOTE` | `NotaCredito` | `POST /api/v1/notas/credito` |
| `DEBIT_NOTE` | `NotaDebito` | `POST /api/v1/notas/debito` |

**Header fields:**

| FideX field | Type | Galac field | Notes |
|---|---|---|---|
| `document_info.document_number` | string | `NroFactura` | Legal invoice number |
| `document_info.doc_type` | enum | `TipoDocumento` | `F`=Factura, `NC`=Nota Crédito, `ND`=Nota Débito |
| `document_info.dates.issued_at` | date | `FechaFactura` | ISO date; Galac rejects datetime format — strip time portion |
| `document_info.dates.due_date` | date | `FechaVencimiento` | |
| `parties.biller.rif` | string | `RIFEmisor` | Must match `Empresa.RIF` in Galac configuration |
| `parties.payer.rif` | string | `RIFCliente` | FK to `Clientes.RIF` |
| `parties.payer.name` | string | `NombreCliente` | Fallback if client not in master |
| `payment_terms.exchange_rate_pegged` | number | `TasaCambio` | BCV rate for Bs conversion |
| `fiscal_control.control_number` | string | `NroControl` | SENIAT control number |
| `fiscal_control.fiscal_series_letter` | string | `Serie` | e.g. `A`, `B` |
| `summary.fiscal_totals_ves.base_imponible_ves` | number | `BaseImponible` | In Bs (VES) |
| `summary.fiscal_totals_ves.total_iva_ves` | number | `MontoIVA` | In Bs |
| `summary.fiscal_totals_ves.total_igtf_ves` | number | `MontoIGTF` | In Bs; separate tax field |
| `summary.fiscal_totals_ves.total_exempt_ves` | number | `MontoExento` | In Bs |
| `summary.fiscal_totals_ves.total_gross_ves` | number | `MontoTotal` | In Bs |
| `related_documents[].document_number` | string | `FacturaAfectada` | For NC/ND: original invoice number |

**Line fields:**

| FideX field | Type | Galac field | Notes |
|---|---|---|---|
| `lines[].product.gtin` | string | `CodigoProducto` | Optional in Galac; stored for reference |
| `lines[].product.description` | string | `Descripcion` | Max 100 chars |
| `lines[].qty.invoiced` | number | `Cantidad` | |
| `lines[].pricing.unit_price` | number | `PrecioUnitario` | In base currency (USD) |
| `lines[].taxes[].is_exempt` | boolean | `Exento` | `true`/`false` |
| `lines[].taxes[].type = "IVA"` | — | `PorcentajeIVA` | |
| `lines[].taxes[].amount_ves` | number | `MontoIVALinea` | In Bs |
| `lines[].line_total_net` | number | `SubTotal` | Net line total in USD |

**Galac XML import format (alternative to REST):**
```xml
<GalacFacturas>
  <Factura>
    <NroFactura>INV-2026-00145</NroFactura>
    <FechaFactura>2026-02-28</FechaFactura>
    <RIFCliente>J-11111111-2</RIFCliente>
    <NombreCliente>Drogueria Distribuidora X</NombreCliente>
    <TasaCambio>45.00</TasaCambio>
    <NroControl>00000145</NroControl>
    <BaseImponible>5062.50</BaseImponible>
    <MontoIVA>810.00</MontoIVA>
    <MontoExento>0.00</MontoExento>
    <MontoTotal>5872.50</MontoTotal>
  </Factura>
</GalacFacturas>
```

---

## 6. Tax Retention → `ComprobantesRetencion` *(core Galac feature)*

Galac's **primary differentiator** is its retention module. It generates and manages SENIAT comprobantes for both IVA (Providencia 049/056) and ISLR (Decreto 1808).

**IVA Retention (Galac → Libro de Compras / Comprobante):**

| FideX field | Type | Galac field | Notes |
|---|---|---|---|
| `document_info.document_number` | string | `NroComprobante` | Sequential SENIAT comprobante; Galac auto-assigns |
| `document_info.doc_type` | enum | `TipoRetencion` | `IVA` / `ISLR` |
| `document_info.dates.issued_at` | date | `FechaComprobante` | |
| `retention_header.period` | string | `Periodo` | `YYYY-MM` format; for fiscal period grouping |
| `retention_header.withholder.rif` | string | `RIFAgente` | Must match `Empresa.RIF` |
| `retention_header.withholder.name` | string | `NombreAgente` | |
| `retention_header.withheld_party.rif` | string | `RIFProveedor` | Supplier being withheld from |
| `retention_header.withheld_party.name` | string | `NombreProveedor` | |
| `retention_header.related_invoice` | string | `NroFactura` | Original invoice number |
| `retention_header.invoice_date` | date | `FechaFactura` | Date of retained invoice |
| `retention_lines[].tax_type` | enum | `TipoImpuesto` | `IVA` / `ISLR` |
| `retention_lines[].taxable_base_usd` | number | `BaseImponibleUSD` | In USD |
| `retention_lines[].taxable_base_ves` | number | `BaseImponible` | In Bs (primary for Galac books) |
| `retention_lines[].retention_rate` | number | `PorcentajeRetencion` | e.g. 75.00 |
| `retention_lines[].amount_retained_usd` | number | `MontoRetenidoUSD` | |
| `retention_lines[].amount_retained_ves` | number | `MontoRetenido` | In Bs; posted to Libro de Compras |
| `retention_header.totals.total_retained_ves` | number | `TotalRetenido` | In Bs |

**ISLR-specific fields:**

| FideX field | Type | Galac field | Notes |
|---|---|---|---|
| `retention_lines[].retention_code` | string | `CodigoConcepto` | Decreto 1808 Tabla 26 code (e.g. `01`) |
| `retention_lines[].activity_description` | string | `DescripcionConcepto` | Activity description |
| `retention_lines[].islr_rate` | number | `AlicuotaISLR` | Rate from Decreto 1808 table |

**REST create (v5.4+ cloud):**
```
POST /api/v1/retenciones
Authorization: Bearer {token}
Content-Type: application/json

{
  "NroComprobante": "RET-IVA-2026-00089",
  "TipoRetencion": "IVA",
  "FechaComprobante": "2026-03-11",
  "Periodo": "2026-03",
  "RIFAgente": "J-11111111-2",
  "RIFProveedor": "J-00000000-1",
  "NroFactura": "INV-2026-00146",
  "FechaFactura": "2026-03-11",
  "BaseImponible": 1080.00,
  "PorcentajeRetencion": 75.00,
  "MontoRetenido": 810.00
}
```

**Galac XML import format for retentions:**
```xml
<GalacRetenciones>
  <Retencion>
    <TipoRetencion>IVA</TipoRetencion>
    <NroComprobante>RET-IVA-2026-00089</NroComprobante>
    <FechaComprobante>2026-03-11</FechaComprobante>
    <RIFAgente>J-11111111-2</RIFAgente>
    <RIFProveedor>J-00000000-1</RIFProveedor>
    <NroFactura>INV-2026-00146</NroFactura>
    <BaseImponible>1080.00</BaseImponible>
    <PorcentajeRetencion>75.00</PorcentajeRetencion>
    <MontoRetenido>810.00</MontoRetenido>
  </Retencion>
</GalacRetenciones>
```

---

## Key Notes

- **Galac scope**: Only the invoice and retention layers of FideX map to Galac. Customer master, catalog, orders, and despatch advice are handled exclusively in the operational ERP (Profit, Saint, or Odoo) before the fiscal documents reach Galac.
- **Date format**: Galac's import wizard expects `YYYY-MM-DD` (no time component). Strip the time from all FideX `issued_at` and `due_date` fields before sending to Galac.
- **Bs-centric amounts**: Galac's fiscal books are always in Bolívares (VES). Always pass `fiscal_totals_ves.*` values — never USD amounts — to Galac's `BaseImponible`, `MontoIVA`, `MontoTotal` fields.
- **SENIAT comprobante auto-numbering**: For IVA retentions, Galac can auto-assign the SENIAT sequential comprobante number if `NroComprobante` is omitted. For ISLR, the number is always manually assigned by the withholding agent per SENIAT instructions.
- **Libro de Ventas/Compras**: All invoices and retentions posted in Galac automatically update the IVA books. No additional action is required by the FideX adapter.
- **SDK**: The `GalacSDK.dll` COM interface is available to licensed partners. Contact Galac C.A. at soporte@galac.com.ve for SDK documentation.
