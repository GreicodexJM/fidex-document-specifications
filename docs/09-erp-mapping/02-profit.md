# ERP Mapping: Profit Plus v12

> **ERP:** Profit Plus v12 (Windows desktop / SQL Server backend)  
> **Vendor:** Softech C.A. — https://www.miprofit.com  
> **Integration layer:** SQL Server direct write (preferred for batch) or Profit Plus SDK (COM/VB.NET DLL)  
> **Database engine:** Microsoft SQL Server 2016–2022

---

## API / Integration Reference

Profit Plus exposes data through its SQL Server database. There is no native REST API in v12; integration uses one of two mechanisms:

| Mechanism | When to use | Notes |
|---|---|---|
| **SQL Server direct** (`pyodbc`, `mssql`) | Bulk inserts, catalog sync, reporting | Use stored procedures where available; avoid raw table writes for transactional tables (`factura`, `ped_venta`) |
| **Profit Plus COM SDK** (`ProfitSDK.dll`) | Creating invoices, orders, payments in correct fiscal sequence | Required for numbering control; ensures hooks and triggers fire correctly |
| **Profit Plus API REST** *(partner-only)* | Cloud-connected deployments | Contact Softech C.A. for partner API credentials; endpoint base: `https://api.miprofit.com/v1/` |

**SQL Server connection string:**
```
Server={server},{port};Database={profit_db};
User Id={user};Password={pass};
TrustServerCertificate=True;
```

**Key database:** `profit_db` (customizable per installation).

---

## 1. Customer Master → `Clientes` table

**Primary key:** `cod_cli` (client code, alphanumeric). Upsert by `rif` field.

| FideX field | Type | Profit table.column | Notes |
|---|---|---|---|
| `customer_details.internal_id` | string | `clientes.cod_cli` | Natural key; auto-generated or mapped from FideX internal_id |
| `customer_details.name` | string | `clientes.nombre` | Max 60 chars |
| `customer_details.commercial_name` | string | `clientes.nombre_comercial` | Trading/commercial name |
| `customer_details.tax_id` | string | `clientes.rif` | Format `J-########-#` |
| `customer_details.gln` | string | `clientes.cod_barra` | Repurpose barcode field or add `x_gln` custom field |
| `customer_details.health_permit.sicm` | string | `clientes.nota` | Free-text notes field; or custom extended table |
| `customer_details.health_permit.permit_status` | enum | *(custom table `cl_ext.sicm_status`)* | Requires custom extension |
| `customer_details.health_permit.expiration_date` | date | *(custom table `cl_ext.sicm_expiry`)* | |
| `customer_details.customer_type` | enum | `clientes.tipo_cli` | Customer classification code |
| `contact_info.email` | string | `clientes.email` | |
| `contact_info.phone` | string | `clientes.telefono1` | |
| `financial_profile.credit_limit.amount` | number | `clientes.limite_credito` | In base currency (USD for dollar companies) |
| `financial_profile.credit_status` | enum | `clientes.bloqueo` | `0`=Active, `1`=Blocked |
| `financial_profile.payment_terms.net_days` | number | `clientes.dias_credito` | Net days |
| `financial_profile.payment_terms.term_type` | enum | `clientes.cond_pago` | Maps to `condpago.cod_cond` |
| `financial_profile.tax_profile.is_retention_agent_iva` | boolean | `clientes.agente_ret_iva` | `1`=Yes, `0`=No |
| `financial_profile.tax_profile.retention_percentage` | number | `clientes.porc_ret_iva` | 0–100 |
| `sales_routing.assigned_agent.employee_id` | string | `clientes.cod_vendedor` | FK to `vendedores.cod_ven` |
| `addresses[0].street` | string | `clientes.direccion1` | Primary billing address |
| `addresses[0].city` | string | `clientes.ciudad` | |
| `addresses[0].state` | string | `clientes.estado` | Venezuelan state name |
| `addresses[0].zip` | string | `clientes.zona_postal` | |
| `addresses[shipping].street` | string | `dir_entrega.direccion` | Shipping addresses in `dir_entrega` table; FK `cod_cli` |

**SQL upsert pattern:**
```sql
MERGE clientes AS target
USING (SELECT @rif AS rif) AS source ON target.rif = source.rif
WHEN MATCHED THEN
  UPDATE SET nombre = @nombre, limite_credito = @limite, agente_ret_iva = @ret
WHEN NOT MATCHED THEN
  INSERT (cod_cli, nombre, rif, limite_credito, agente_ret_iva)
  VALUES (@cod_cli, @nombre, @rif, @limite, @ret);
```

---

## 2. Catalog → `Inventario` / `articulos` table

**Primary key:** `cod_art` (article code). Upsert by `cod_barra` (barcode = GTIN).

| FideX field | Type | Profit table.column | Notes |
|---|---|---|---|
| `item.gtin` | string | `articulos.cod_barra` | GS1 GTIN-14 stored as barcode |
| `item.vendor_part` | string | `articulos.cod_art` | Also used as internal code |
| `item.description` | string | `articulos.descripcion` | Max 80 chars |
| `item.uom` | string | `articulos.unidad` | FK to `unidad.cod_uni` |
| `item.pharma.active_ingredient` | string | `articulos.modelo` | Repurpose or use `art_ext` custom table |
| `item.pharma.requires_refrigeration` | boolean | *(custom `art_ext.cadena_frio`)* | |
| `item.pharma.lot_tracking` | boolean | `articulos.maneja_lote` | `1`=Yes |
| `item.pricing.unit_price` | number | `articulos.precio1` | Price list 1 (primary) |
| `item.pricing.currency` | string | `articulos.moneda` | `USD` or `VES` |
| `item.tax_info.is_exempt` | boolean | `articulos.exento` | `1`=Exempt from IVA |
| `item.tax_info.iva_rate` | number | `articulos.porc_iva` | e.g. 16.00 |
| `item.inventory.quantity_on_hand` | number | `inventario.exist_act` | Do NOT write directly; use inventory movements |
| `item.inventory.merkle_root` | string | *(custom `art_ext.merkle_root`)* | Add custom column |

---

## 3. Order → `ped_venta` / `ped_compra`

**QUOTE / PURCHASE_ORDER → `ped_venta`** (sales side) or `ped_compra` (purchase side).  
**ORDER_CONFIRMED:** Update `ped_venta.status` = `'A'` (approved/confirmed).

| FideX field | Type | Profit table.column | Notes |
|---|---|---|---|
| `document_info.document_number` | string | `ped_venta.nro_ped` | Pedido number |
| `document_info.status` | enum | `ped_venta.status` | `P`=Pending, `A`=Approved, `C`=Cancelled |
| `document_info.dates.created_at` | datetime | `ped_venta.fecha` | |
| `document_info.dates.delivery_requested` | datetime | `ped_venta.fecha_entrega` | |
| `document_info.dates.expiration` | datetime | `ped_venta.fecha_vence` | |
| `parties.seller.rif` | string | *(company config)* | Validated against `empresa.rif` |
| `parties.buyer.rif` | string | `ped_venta.cod_cli` | Resolve `clientes.rif` → `cod_cli` |
| `parties.ship_to.rif` | string | `ped_venta.dir_entrega` | FK to `dir_entrega` |
| `payment_terms.term_type` | enum | `ped_venta.cond_pago` | |
| `payment_terms.exchange_rate_pegged` | number | `ped_venta.tasa_cambio` | BCV rate at time of order |
| `logistics.carrier` | string | `ped_venta.transportista` | Free text |
| `lines[].product.gtin` | string | `ped_det.cod_art` | Resolve via `articulos.cod_barra` |
| `lines[].qty.ordered` | number | `ped_det.cantidad` | |
| `lines[].pricing.unit_price` | number | `ped_det.precio` | |
| `lines[].discounts_charges[].percentage` | number | `ped_det.porc_desc` | First discount only |
| `lines[].taxes[].type = "IVA"` | — | `ped_det.porc_iva` | |
| `applied_payments[].method` | string | `ped_venta.forma_pago` | Payment method code |
| `applied_payments[].reference_data.confirmation_number` | string | `ped_venta.referencia` | PagoMóvil confirmation |

---

## 4. Despatch Advice → `guia_despacho`

**Strategy:** The ASN triggers creation of a `guia_despacho` linked to the originating `ped_venta`.

| FideX field | Type | Profit table.column | Notes |
|---|---|---|---|
| `document_info.document_number` | string | `guia_despacho.nro_guia` | |
| `document_info.related_order` | string | `guia_despacho.nro_ped` | FK to `ped_venta` |
| `document_info.dates.issued_at` | datetime | `guia_despacho.fecha` | |
| `document_info.dates.estimated_delivery` | datetime | `guia_despacho.fecha_entrega` | |
| `parties.ship_to.rif` | string | `guia_despacho.cod_cli` | |
| `logistics.carrier.name` | string | `guia_despacho.transportista` | |
| `logistics.driver.vehicle_plate` | string | `guia_despacho.placa` | |
| `logistics.packaging.sscc` | string | `guia_despacho.sscc` | Custom column; store GS1 SSCC |
| `lines[].product.gtin` | string | `guia_det.cod_art` | |
| `lines[].qty.shipped` | number | `guia_det.cantidad` | |
| `lines[].pharma_tracking.lot_number` | string | `guia_det.lote` | |
| `lines[].pharma_tracking.expiry_date` | date | `guia_det.fecha_venc` | |

---

## 5. Invoice / Credit Note / Debit Note → `factura` / `nota_cred_deb`

**Use Profit Plus SDK (`ProfitSDK.dll`)** for all invoice creation to ensure sequential control numbering and correct fiscal hooks.

| FideX field | Type | Profit table.column | Notes |
|---|---|---|---|
| `document_info.document_number` | string | `factura.nro_fac` | Auto-generated by Profit; store FideX ref in `factura.ref_externa` |
| `document_info.doc_type` | enum | `factura.tipo_doc` | `F`=Factura, `N`=Nota Crédito, `D`=Nota Débito |
| `document_info.status` | enum | `factura.status` | `E`=Emitida, `A`=Anulada |
| `document_info.dates.issued_at` | datetime | `factura.fecha` | |
| `document_info.dates.due_date` | date | `factura.fecha_vence` | |
| `document_info.related_order` | string | `factura.nro_ped` | |
| `document_info.related_asn` | string | `factura.nro_guia` | |
| `parties.payer.rif` | string | `factura.cod_cli` | Resolve via `clientes.rif` |
| `payment_terms.term_type` | enum | `factura.cond_pago` | |
| `payment_terms.exchange_rate_pegged` | number | `factura.tasa_cambio` | |
| `lines[].product.gtin` | string | `fac_det.cod_art` | |
| `lines[].qty.invoiced` | number | `fac_det.cantidad` | |
| `lines[].pricing.unit_price` | number | `fac_det.precio` | |
| `lines[].taxes[].type = "IVA"` | — | `fac_det.porc_iva` | |
| `lines[].taxes[].type = "IGTF"` | — | `fac_det.porc_igtf` | Separate column or custom extension |
| `summary.total_net_usd` | number | `factura.monto_bruto` | Before tax |
| `summary.total_taxes_usd` | number | `factura.monto_iva` | |
| `summary.total_gross_usd` | number | `factura.monto_total` | |
| `summary.fiscal_totals_ves.exchange_rate_applied` | number | `factura.tasa_cambio` | |
| `summary.fiscal_totals_ves.base_imponible_ves` | number | `factura.monto_bruto_bs` | |
| `summary.fiscal_totals_ves.total_iva_ves` | number | `factura.monto_iva_bs` | |
| `fiscal_control.control_number` | string | `factura.nro_control` | SENIAT control number |
| `related_documents[].document_number` | string | `nota_cred_deb.nro_fac_afectada` | For credit/debit note |

---

## 6. Tax Retention → `comp_ret_iva` / `comp_ret_islr`

| FideX field | Type | Profit table.column | Notes |
|---|---|---|---|
| `document_info.document_number` | string | `comp_ret.nro_comprobante` | SENIAT comprobante number |
| `document_info.doc_type` | enum | `comp_ret.tipo` | `IVA` or `ISLR` |
| `document_info.dates.issued_at` | datetime | `comp_ret.fecha` | |
| `retention_header.withholder.rif` | string | `comp_ret.rif_agente` | Withholding agent RIF |
| `retention_header.withheld_party.rif` | string | `comp_ret.rif_proveedor` | |
| `retention_header.related_invoice` | string | `comp_ret.nro_factura` | |
| `retention_lines[].taxable_base_usd` | number | `comp_ret_det.base_imponible` | |
| `retention_lines[].retention_rate` | number | `comp_ret_det.porc_retencion` | |
| `retention_lines[].amount_retained_usd` | number | `comp_ret_det.monto_retenido` | |
| `retention_lines[].amount_retained_ves` | number | `comp_ret_det.monto_retenido_bs` | |
| `retention_header.totals.total_retained_usd` | number | `comp_ret.total_retenido` | |

---

## Key Notes

- **No native REST API in Profit Plus v12**: All integrations MUST go through the COM SDK or direct SQL. Contact Softech (soporte@miprofit.com) for SDK access under a partner agreement.
- **Fiscal sequence control**: Never insert directly into `factura` via raw SQL. Always use `SDK.Factura.Crear()` to ensure `nro_fac` and `nro_control` are issued in legal sequence.
- **Custom columns**: Profit allows adding columns to standard tables via its "Campos adicionales" feature in the Admin module. Use this for `sscc`, `merkle_root`, `x_gln`, etc.
- **Multi-currency**: Profit supports USD/VES dual-currency natively. Map `payment_terms.exchange_rate_pegged` to `tasa_cambio` on every transactional header.
- **Partner API**: Softech C.A. offers a partner-level REST API (`https://api.miprofit.com/v1/`) for certified integrators. Endpoint documentation available upon signing an integration partner agreement.
