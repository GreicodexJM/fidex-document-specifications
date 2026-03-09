# Integración ERP: Saint Enterprise v6+

> **ERP:** Saint Enterprise v6 (Windows / SQL Server)  
> **Proveedor:** Business Technology C.A. — https://saintve.com  
> **Capa de integración:** API REST v1 (`/api/v1/`) disponible desde Saint Enterprise v6; SQL Server directo para versiones anteriores

> 🇬🇧 [English version](../../09-erp-mapping/03-saint.md)

---

## Referencia de API

| Operación | Endpoint | Notas |
|---|---|---|
| Autenticación | `POST /api/v1/auth/login` | Devuelve `access_token` (JWT); válido 8 h |
| Clientes | `POST /api/v1/clientes` | |
| Actualizar cliente | `PUT /api/v1/clientes/{cod_cli}` | |
| Inventario | `POST /api/v1/inventario` | |
| Pedidos | `POST /api/v1/pedidos` | |
| Facturas | `POST /api/v1/facturas` | |
| Notas crédito | `POST /api/v1/notas/credito` | |
| Notas débito | `POST /api/v1/notas/debito` | |
| Retenciones | `POST /api/v1/retenciones` | |

**Autenticación:**
```
POST /api/v1/auth/login
{ "usuario": "fidex_adapter", "clave": "••••••", "empresa": "LETI-01" }
→ { "access_token": "eyJ...", "expires_in": 28800 }
```

Todas las peticiones posteriores: `Authorization: Bearer {access_token}`

---

## 1. Ficha de Cliente → `ClCliente`

**Estrategia:** buscar por `Rif`; `PUT` si existe, `POST` si no.

| Campo FideX | Tipo | Campo Saint | Notas |
|---|---|---|---|
| `customer_details.internal_id` | texto | `CodCliente` | Máx. 15 caracteres |
| `customer_details.name` | texto | `NomCliente` | Nombre legal |
| `customer_details.commercial_name` | texto | `NomComercial` | |
| `customer_details.tax_id` | texto | `Rif` | Formato `J-########-#` |
| `customer_details.gln` | texto | `CodBarra` | GLN como código de barras; o `CampoLibre1` |
| `customer_details.health_permit.sicm` | texto | `CampoLibre1` | Campo libre; o extensión personalizada |
| `customer_details.health_permit.permit_status` | enum | `CampoLibre2` | `VALID`/`EXPIRED` |
| `customer_details.health_permit.expiration_date` | fecha | `CampoFecha1` | Campo fecha disponible en Saint |
| `financial_profile.credit_limit.amount` | número | `LimiteCredito` | |
| `financial_profile.credit_status` | enum | `Bloqueado` | `S`=Bloqueado, `N`=Activo |
| `financial_profile.tax_profile.is_retention_agent_iva` | booleano | `AgenteRetIVA` | `S`/`N` |
| `financial_profile.tax_profile.retention_percentage` | número | `PorcRetIVA` | Por defecto 75.00 |
| `sales_routing.assigned_agent.employee_id` | texto | `CodVendedor` | FK a `VeVendedor` |

---

## 2. Catálogo → `InArticulo`

**Estrategia:** buscar por `CodBarra` (GTIN); `PUT` si existe, `POST` si no.

| Campo FideX | Tipo | Campo Saint | Notas |
|---|---|---|---|
| `item.gtin` | texto | `CodBarra` | GTIN-14 GS1 |
| `item.vendor_part` | texto | `CodArticulo` | Código interno |
| `item.description` | texto | `Descripcion` | |
| `item.pharma.lot_tracking` | booleano | `ManejaLote` | `S`/`N` |
| `item.pharma.active_ingredient` | texto | `CampoLibre1` | Campo libre para principio activo |
| `item.pricing.unit_price` | número | `PrecioVenta1` | Precio en USD |
| `item.tax_info.is_exempt` | booleano | `Exento` | `S`/`N` |
| `item.inventory.merkle_root` | texto | `CampoLibre5` | Para trazabilidad de sincronización delta |

---

## 3. Orden → `VePedido` / `CoPedido`

| Campo FideX | Tipo | Campo Saint | Notas |
|---|---|---|---|
| `document_info.document_number` | texto | `NroPedido` | |
| `document_info.status` | enum | `Status` | `PRE`=Borrador, `CON`=Confirmado, `ANU`=Cancelado |
| `parties.buyer.rif` | texto | `CodCliente` | Resolver via `ClCliente.Rif` |
| `payment_terms.exchange_rate_pegged` | número | `TasaCambio` | Tasa BCV |
| `lines[].product.gtin` | texto | `CodArticulo` | Resolver via `InArticulo.CodBarra` |
| `lines[].qty.ordered` | número | `Cantidad` | |
| `lines[].pricing.unit_price` | número | `Precio` | |
| `applied_payments[].reference_data.confirmation_number` | texto | `Referencia` | Confirmación PagoMóvil |

---

## 4. Nota de Entrega → `VeDespacho`

| Campo FideX | Tipo | Campo Saint | Notas |
|---|---|---|---|
| `document_info.document_number` | texto | `NroDespacho` | |
| `document_info.related_order` | texto | `NroPedido` | FK a `VePedido` |
| `logistics.packaging.sscc` | texto | `CampoLibre1` | SSCC-18 en campo libre |
| `lines[].pharma_tracking.lot_number` | texto | `Lote` | |
| `lines[].pharma_tracking.expiry_date` | fecha | `FechaVencLote` | |

---

## 5. Factura / Nota de Crédito / Nota de Débito → `VeFactura`

| Campo FideX | Tipo | Campo Saint | Notas |
|---|---|---|---|
| `document_info.document_number` | texto | `NroFactura` | |
| `document_info.doc_type` | enum | *(selección de endpoint)* | `INVOICE`→`/facturas`, `CREDIT_NOTE`→`/notas/credito`, `DEBIT_NOTE`→`/notas/debito` |
| `parties.payer.rif` | texto | `CodCliente` | Resolver via `Rif` |
| `payment_terms.exchange_rate_pegged` | número | `TasaCambio` | |
| `lines[].taxes[].type = "IVA"` | — | `PorcIVA` | |
| `lines[].taxes[].type = "IGTF"` | — | `PorcIGTF` | Requiere Saint v6.2+ |
| `summary.fiscal_totals_ves.base_imponible_ves` | número | `BaseImponibleBs` | |
| `summary.fiscal_totals_ves.total_iva_ves` | número | `MontoIVABs` | |
| `fiscal_control.control_number` | texto | `NroControl` | Número de control SENIAT |
| `related_documents[].document_number` | texto | `NroFacturaAfectada` | Para NC/ND |

---

## 6. Retención → `VeRetencion`

| Campo FideX | Tipo | Campo Saint | Notas |
|---|---|---|---|
| `document_info.document_number` | texto | `NroComprobante` | Comprobante SENIAT |
| `document_info.doc_type` | enum | `TipoRetencion` | `IVA` / `ISLR` |
| `retention_header.withholder.rif` | texto | `RifAgente` | |
| `retention_header.withheld_party.rif` | texto | `RifProveedor` | |
| `retention_header.related_invoice` | texto | `NroFactura` | |
| `retention_lines[].taxable_base_usd` | número | `BaseImponible` | |
| `retention_lines[].retention_rate` | número | `PorcRetencion` | |
| `retention_lines[].amount_retained_ves` | número | `MontoRetenidoBs` | |

---

## Notas Importantes

- **Disponibilidad de API**: La REST API (`/api/v1/`) está disponible desde Saint Enterprise v6+. Para v5 o anterior, usar SQL Server directo con los mismos nombres de columna (convención PascalCase).
- **Campos `CampoLibre`**: Saint provee hasta 5 campos texto (`CampoLibre1–5`) y 3 fechas (`CampoFecha1–3`) en la mayoría de tablas maestras. Usar para SICM, GLN, Merkle Root y SSCC antes de crear tablas personalizadas.
- **Secuencia fiscal**: Usar la API (no SQL directo) para crear facturas y retenciones; garantiza que `NroControl` sea emitido por el contador fiscal interno de Saint.
- **IGTF**: Requiere Saint v6.2+ para el campo nativo `PorcIGTF`. En versiones anteriores, agregar como línea de impuesto adicional con código de impuesto personalizado.
