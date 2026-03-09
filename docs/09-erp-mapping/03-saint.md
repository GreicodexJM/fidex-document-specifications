# ERP Mapping: Saint Enterprise v6+

> **ERP:** Saint Enterprise v6 (Windows / SQL Server backend)  
> **Vendor:** Business Technology C.A. — https://saintve.com  
> **Integration layer:** Saint REST API v1 (`/api/v1/`) — available from Saint Enterprise v6; SQL Server direct for older versions  
> **Database engine:** Microsoft SQL Server 2016–2022

---

## API / Integration Reference

Saint Enterprise v6+ exposes a REST API for external integrations. Prior versions (v5 and earlier) require SQL Server direct access.

| Operation | Protocol | Endpoint | Notes |
|---|---|---|---|
| Authenticate | REST | `POST /api/v1/auth/login` | Returns `access_token` (JWT); validity 8 h |
| Refresh token | REST | `POST /api/v1/auth/refresh` | |
| Client upsert | REST | `POST /api/v1/clientes` | |
| Client update | REST | `PUT /api/v1/clientes/{cod_cli}` | |
| Item upsert | REST | `POST /api/v1/inventario` | |
| Create order | REST | `POST /api/v1/pedidos` | |
| Create invoice | REST | `POST /api/v1/facturas` | |
| Create credit note | REST | `POST /api/v1/notas/credito` | |
| Create debit note | REST | `POST /api/v1/notas/debito` | |
| Create retention | REST | `POST /api/v1/retenciones` | |

**Authentication:**
```
POST /api/v1/auth/login
Content-Type: application/json

{ "usuario": "fidex_adapter", "clave": "••••••", "empresa": "LETI-01" }

→ 200 OK
{ "access_token": "eyJ...", "expires_in": 28800 }
```

**Base URL:** `https://{saint-server}/api/v1/`  
All subsequent requests: `Authorization: Bearer {access_token}`

---

## 1. Customer Master → `ClCliente`

**Upsert strategy:** search by `rif`; use `PUT` if exists, `POST` if new.

| FideX field | Type | Saint field | Table / Object | Notes |
|---|---|---|---|---|
| `customer_details.internal_id` | string | `CodCliente` | `ClCliente` | Max 15 chars |
| `customer_details.name` | string | `NomCliente` | `ClCliente` | Legal name |
| `customer_details.commercial_name` | string | `NomComercial` | `ClCliente` | |
| `customer_details.tax_id` | string | `Rif` | `ClCliente` | Format `J-########-#` |
| `customer_details.gln` | string | `CodBarra` | `ClCliente` | GLN stored as barcode; or `CampoLibre1` |
| `customer_details.health_permit.sicm` | string | `CampoLibre1` | `ClCliente` | Free field; or custom extension |
| `customer_details.health_permit.permit_status` | enum | `CampoLibre2` | `ClCliente` | `VALID`/`EXPIRED` |
| `customer_details.health_permit.expiration_date` | date | `CampoFecha1` | `ClCliente` | Custom date field |
| `customer_details.customer_type` | enum | `TipoCliente` | `ClCliente` | `F`=Pharmacy, `D`=Droguería, etc. |
| `contact_info.email` | string | `Email` | `ClCliente` | |
| `contact_info.phone` | string | `Telefono1` | `ClCliente` | |
| `financial_profile.credit_limit.amount` | number | `LimiteCredito` | `ClCliente` | In base currency |
| `financial_profile.credit_status` | enum | `Bloqueado` | `ClCliente` | `S`=Blocked, `N`=Active |
| `financial_profile.payment_terms.net_days` | number | `DiasCredito` | `ClCliente` | |
| `financial_profile.payment_terms.term_type` | enum | `CondPago` | `ClCliente` | FK to `ClCondPago` |
| `financial_profile.tax_profile.is_retention_agent_iva` | boolean | `AgenteRetIVA` | `ClCliente` | `S`/`N` |
| `financial_profile.tax_profile.retention_percentage` | number | `PorcRetIVA` | `ClCliente` | Default 75.00 |
| `sales_routing.assigned_agent.employee_id` | string | `CodVendedor` | `ClCliente` | FK to `VeVendedor` |
| `addresses[0].street` | string | `Direccion1` | `ClCliente` | Primary billing |
| `addresses[0].city` | string | `Ciudad` | `ClCliente` | |
| `addresses[0].state` | string | `Estado` | `ClCliente` | Venezuelan state |
| `addresses[0].zip` | string | `ZonaPostal` | `ClCliente` | |
| `addresses[shipping].*` | object | `ClDirEntrega.*` | `ClDirEntrega` | Shipping addresses; FK `CodCliente` |

**REST create:**
```
POST /api/v1/clientes
Authorization: Bearer {token}

{
  "CodCliente": "C-10045",
  "NomCliente": "Farmacia El Pueblo C.A.",
  "Rif": "J-22222222-3",
  "LimiteCredito": 5000.00,
  "AgenteRetIVA": "S",
  "PorcRetIVA": 75.00,
  "CampoLibre1": "S-98765"
}
```

---

## 2. Catalog → `InArticulo` / `InInventario`

**Upsert strategy:** search by `CodBarra` (GTIN); `PUT` to update, `POST` to create.

| FideX field | Type | Saint field | Table | Notes |
|---|---|---|---|---|
| `item.gtin` | string | `CodBarra` | `InArticulo` | GS1 GTIN-14 |
| `item.vendor_part` | string | `CodArticulo` | `InArticulo` | Internal code |
| `item.description` | string | `Descripcion` | `InArticulo` | |
| `item.uom` | string | `Unidad` | `InArticulo` | FK to `InUnidad` |
| `item.pharma.active_ingredient` | string | `CampoLibre1` | `InArticulo` | Custom free field |
| `item.pharma.concentration` | string | `CampoLibre2` | `InArticulo` | |
| `item.pharma.lot_tracking` | boolean | `ManejaLote` | `InArticulo` | `S`/`N` |
| `item.pharma.requires_refrigeration` | boolean | `CampoLibre3` | `InArticulo` | Or custom `CadenaFrio` field |
| `item.pricing.unit_price` | number | `PrecioVenta1` | `InArticulo` | Price list 1 (USD) |
| `item.pricing.currency` | string | `Moneda` | `InArticulo` | `USD`/`VES` |
| `item.tax_info.is_exempt` | boolean | `Exento` | `InArticulo` | `S`/`N` |
| `item.tax_info.iva_rate` | number | `PorcIVA` | `InArticulo` | |
| `item.inventory.quantity_on_hand` | number | `ExistenciaActual` | `InInventario` | Read-only; adjust via `InMovimiento` |
| `item.inventory.merkle_root` | string | `CampoLibre5` | `InArticulo` | Custom field for delta tracking |

---

## 3. Order → `VePedido` / `CoPedido`

**`PURCHASE_ORDER`** (seller receives) → `VePedido`  
**`PURCHASE_ORDER`** (buyer sends) → `CoPedido` (compras)  
**`QUOTE`** → `VePedido` with `Status = 'PRE'`  
**`ORDER_CONFIRMED`** → `PUT /api/v1/pedidos/{nroPedido}` with `Status = 'CON'`

| FideX field | Type | Saint field | Table | Notes |
|---|---|---|---|---|
| `document_info.document_number` | string | `NroPedido` | `VePedido` | |
| `document_info.status` | enum | `Status` | `VePedido` | `PRE`=Draft, `CON`=Confirmed, `ANU`=Cancelled |
| `document_info.dates.created_at` | datetime | `Fecha` | `VePedido` | |
| `document_info.dates.delivery_requested` | datetime | `FechaEntrega` | `VePedido` | |
| `document_info.dates.expiration` | datetime | `FechaVence` | `VePedido` | |
| `parties.buyer.rif` | string | `CodCliente` | `VePedido` | Resolve via `ClCliente.Rif` |
| `parties.ship_to.rif` | string | `DirEntrega` | `VePedido` | FK to `ClDirEntrega` |
| `payment_terms.term_type` | enum | `CondPago` | `VePedido` | |
| `payment_terms.exchange_rate_pegged` | number | `TasaCambio` | `VePedido` | BCV rate |
| `lines[].product.gtin` | string | `CodArticulo` | `VePedidoDet` | Resolve via `InArticulo.CodBarra` |
| `lines[].qty.ordered` | number | `Cantidad` | `VePedidoDet` | |
| `lines[].pricing.unit_price` | number | `Precio` | `VePedidoDet` | |
| `lines[].discounts_charges[].percentage` | number | `PorcDescuento` | `VePedidoDet` | |
| `lines[].taxes[].type = "IVA"` | — | `PorcIVA` | `VePedidoDet` | |
| `applied_payments[].method` | string | `FormaPago` | `VePedido` | |
| `applied_payments[].reference_data.confirmation_number` | string | `Referencia` | `VePedido` | PagoMóvil ref |

---

## 4. Despatch Advice → `VeDespacho`

| FideX field | Type | Saint field | Table | Notes |
|---|---|---|---|---|
| `document_info.document_number` | string | `NroDespacho` | `VeDespacho` | |
| `document_info.related_order` | string | `NroPedido` | `VeDespacho` | FK to `VePedido` |
| `document_info.dates.issued_at` | datetime | `Fecha` | `VeDespacho` | |
| `document_info.dates.estimated_delivery` | datetime | `FechaEntrega` | `VeDespacho` | |
| `parties.ship_to.rif` | string | `CodCliente` | `VeDespacho` | |
| `logistics.carrier.name` | string | `Transportista` | `VeDespacho` | |
| `logistics.driver.name` | string | `NomChofer` | `VeDespacho` | |
| `logistics.driver.vehicle_plate` | string | `Placa` | `VeDespacho` | |
| `logistics.packaging.sscc` | string | `CampoLibre1` | `VeDespacho` | Store SSCC-18; custom field |
| `lines[].product.gtin` | string | `CodArticulo` | `VeDespachoDet` | |
| `lines[].qty.shipped` | number | `Cantidad` | `VeDespachoDet` | |
| `lines[].pharma_tracking.lot_number` | string | `Lote` | `VeDespachoDet` | |
| `lines[].pharma_tracking.expiry_date` | date | `FechaVencLote` | `VeDespachoDet` | |

**REST:**
```
POST /api/v1/despachos
Authorization: Bearer {token}

{
  "NroPedido": "ORD-2026-9921",
  "CodCliente": "C-10045",
  "Fecha": "2026-02-28T09:00:00",
  "Detalles": [
    { "CodArticulo": "LETI-AMOX-500", "Cantidad": 50,
      "Lote": "L-202509A", "FechaVencLote": "2028-09-01" }
  ]
}
```

---

## 5. Invoice / Credit Note / Debit Note → `VeFactura` / `VeNotaCred` / `VeNotaDeb`

| FideX field | Type | Saint field | Table | Notes |
|---|---|---|---|---|
| `document_info.document_number` | string | `NroFactura` | `VeFactura` | |
| `document_info.doc_type` | enum | *(endpoint selection)* | — | `INVOICE`→`/facturas`, `CREDIT_NOTE`→`/notas/credito`, `DEBIT_NOTE`→`/notas/debito` |
| `document_info.status` | enum | `Status` | `VeFactura` | `EMI`=Issued, `ANU`=Void |
| `document_info.dates.issued_at` | datetime | `Fecha` | `VeFactura` | |
| `document_info.dates.due_date` | date | `FechaVence` | `VeFactura` | |
| `document_info.related_order` | string | `NroPedido` | `VeFactura` | |
| `document_info.related_asn` | string | `NroDespacho` | `VeFactura` | |
| `parties.payer.rif` | string | `CodCliente` | `VeFactura` | Resolve via `Rif` |
| `payment_terms.exchange_rate_pegged` | number | `TasaCambio` | `VeFactura` | |
| `lines[].product.gtin` | string | `CodArticulo` | `VeFacturaDet` | |
| `lines[].qty.invoiced` | number | `Cantidad` | `VeFacturaDet` | |
| `lines[].pricing.unit_price` | number | `Precio` | `VeFacturaDet` | |
| `lines[].taxes[].type = "IVA"` | — | `PorcIVA` | `VeFacturaDet` | |
| `lines[].taxes[].type = "IGTF"` | — | `PorcIGTF` | `VeFacturaDet` | Separate field |
| `summary.total_net_usd` | number | `MontoNeto` | `VeFactura` | |
| `summary.total_taxes_usd` | number | `MontoIVA` | `VeFactura` | |
| `summary.total_gross_usd` | number | `MontoTotal` | `VeFactura` | |
| `summary.fiscal_totals_ves.exchange_rate_applied` | number | `TasaCambio` | `VeFactura` | |
| `summary.fiscal_totals_ves.base_imponible_ves` | number | `BaseImponibleBs` | `VeFactura` | |
| `summary.fiscal_totals_ves.total_iva_ves` | number | `MontoIVABs` | `VeFactura` | |
| `fiscal_control.control_number` | string | `NroControl` | `VeFactura` | SENIAT control number |
| `related_documents[].document_number` | string | `NroFacturaAfectada` | `VeNotaCred` | For credit/debit note backlink |

---

## 6. Tax Retention → `VeRetencion`

| FideX field | Type | Saint field | Table | Notes |
|---|---|---|---|---|
| `document_info.document_number` | string | `NroComprobante` | `VeRetencion` | SENIAT comprobante |
| `document_info.doc_type` | enum | `TipoRetencion` | `VeRetencion` | `IVA` / `ISLR` |
| `document_info.dates.issued_at` | datetime | `Fecha` | `VeRetencion` | |
| `retention_header.withholder.rif` | string | `RifAgente` | `VeRetencion` | |
| `retention_header.withheld_party.rif` | string | `RifProveedor` | `VeRetencion` | |
| `retention_header.related_invoice` | string | `NroFactura` | `VeRetencion` | |
| `retention_lines[].taxable_base_usd` | number | `BaseImponible` | `VeRetencionDet` | |
| `retention_lines[].retention_rate` | number | `PorcRetencion` | `VeRetencionDet` | |
| `retention_lines[].amount_retained_usd` | number | `MontoRetenido` | `VeRetencionDet` | |
| `retention_lines[].amount_retained_ves` | number | `MontoRetenidoBs` | `VeRetencionDet` | |
| `retention_header.totals.total_retained_usd` | number | `TotalRetenido` | `VeRetencion` | |

**REST:**
```
POST /api/v1/retenciones
Authorization: Bearer {token}

{
  "NroComprobante": "RET-IVA-2026-00089",
  "TipoRetencion": "IVA",
  "Fecha": "2026-03-11",
  "RifAgente": "J-00000000-1",
  "RifProveedor": "J-11111111-2",
  "NroFactura": "INV-2026-00146",
  "Detalles": [
    { "BaseImponible": 24.00, "PorcRetencion": 75.00,
      "MontoRetenido": 18.00, "MontoRetenidoBs": 810.00 }
  ]
}
```

---

## Key Notes

- **API availability**: The REST API (`/api/v1/`) is available from Saint Enterprise v6+. For v5 or earlier, use SQL Server direct access with the same column names (PascalCase convention).
- **CampoLibre fields**: Saint provides up to 5 free-text (`CampoLibre1–5`) and 3 date (`CampoFecha1–3`) fields on most master tables. Use these for SICM, GLN, Merkle Root, and SSCC before creating custom tables.
- **Fiscal sequence**: Use the API endpoint (not direct SQL) to create invoices and retentions; this ensures `NroControl` is issued by Saint's internal fiscal counter.
- **Multi-currency**: Saint natively supports `TasaCambio` on all transactional documents. Always pass `payment_terms.exchange_rate_pegged` as `TasaCambio`.
- **IGTF handling**: Requires Saint v6.2+ for native `PorcIGTF` field. On earlier versions, add as an additional tax line in `VeFacturaDet` with a custom tax code.
- **Documentation**: Official Saint developer docs at https://saintve.com/desarrolladores (partner login required).
