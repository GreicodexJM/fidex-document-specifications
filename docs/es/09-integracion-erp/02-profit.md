# Integración ERP: Profit Plus v12

> **ERP:** Profit Plus v12 (escritorio Windows / backend SQL Server)  
> **Proveedor:** Softech C.A. — https://www.miprofit.com  
> **Capa de integración:** SQL Server directo (recomendado para lotes) o Profit Plus SDK (COM/VB.NET DLL)

> 🇬🇧 [English version](../../09-erp-mapping/02-profit.md)

---

## Referencia de API / Integración

| Mecanismo | Cuándo usar | Notas |
|---|---|---|
| **SQL Server directo** (`pyodbc`, `mssql`) | Inserciones masivas, sincronización de catálogo | Usar procedimientos almacenados; evitar escrituras directas en tablas transaccionales (`factura`, `ped_venta`) |
| **Profit Plus COM SDK** (`ProfitSDK.dll`) | Creación de facturas, pedidos, pagos en secuencia fiscal correcta | **Obligatorio** para control de numeración; asegura que hooks y triggers se ejecuten |
| **API REST** *(solo socios)* | Despliegues en nube | Contactar Softech C.A.; base: `https://api.miprofit.com/v1/` |

**Cadena de conexión SQL Server:**
```
Server={servidor},{puerto};Database={bd_profit};
User Id={usuario};Password={clave};TrustServerCertificate=True;
```

---

## 1. Ficha de Cliente → tabla `clientes`

**Clave primaria:** `cod_cli`. Insertar/actualizar por campo `rif`.

| Campo FideX | Tipo | Columna Profit | Notas |
|---|---|---|---|
| `customer_details.internal_id` | texto | `clientes.cod_cli` | Clave natural |
| `customer_details.name` | texto | `clientes.nombre` | Máx. 60 caracteres |
| `customer_details.commercial_name` | texto | `clientes.nombre_comercial` | |
| `customer_details.tax_id` | texto | `clientes.rif` | Formato `J-########-#` |
| `customer_details.gln` | texto | `clientes.cod_barra` | Reutilizar campo de código de barras o agregar `x_gln` |
| `customer_details.health_permit.sicm` | texto | `clientes.nota` | Campo de notas libres; o tabla extendida personalizada |
| `customer_details.health_permit.permit_status` | enum | *(tabla `cl_ext.sicm_status`)* | Requiere extensión personalizada |
| `customer_details.health_permit.expiration_date` | fecha | *(tabla `cl_ext.sicm_expiry`)* | |
| `contact_info.email` | texto | `clientes.email` | |
| `contact_info.phone` | texto | `clientes.telefono1` | |
| `financial_profile.credit_limit.amount` | número | `clientes.limite_credito` | En moneda base (USD para empresas dolarizadas) |
| `financial_profile.credit_status` | enum | `clientes.bloqueo` | `0`=Activo, `1`=Bloqueado |
| `financial_profile.payment_terms.net_days` | número | `clientes.dias_credito` | Días netos |
| `financial_profile.tax_profile.is_retention_agent_iva` | booleano | `clientes.agente_ret_iva` | `1`=Sí, `0`=No |
| `financial_profile.tax_profile.retention_percentage` | número | `clientes.porc_ret_iva` | 0–100 |
| `sales_routing.assigned_agent.employee_id` | texto | `clientes.cod_vendedor` | FK a `vendedores.cod_ven` |
| `addresses[0].street` | texto | `clientes.direccion1` | Dirección de facturación principal |
| `addresses[shipping].street` | texto | `dir_entrega.direccion` | Direcciones de entrega en tabla `dir_entrega` |

**Patrón SQL MERGE:**
```sql
MERGE clientes AS destino
USING (SELECT @rif AS rif) AS fuente ON destino.rif = fuente.rif
WHEN MATCHED THEN
  UPDATE SET nombre = @nombre, limite_credito = @limite, agente_ret_iva = @ret
WHEN NOT MATCHED THEN
  INSERT (cod_cli, nombre, rif, limite_credito, agente_ret_iva)
  VALUES (@cod_cli, @nombre, @rif, @limite, @ret);
```

---

## 2. Catálogo → tabla `articulos`

| Campo FideX | Tipo | Columna Profit | Notas |
|---|---|---|---|
| `item.gtin` | texto | `articulos.cod_barra` | GTIN-14 GS1 como código de barras |
| `item.vendor_part` | texto | `articulos.cod_art` | Código interno |
| `item.description` | texto | `articulos.descripcion` | Máx. 80 caracteres |
| `item.pharma.lot_tracking` | booleano | `articulos.maneja_lote` | `1`=Sí |
| `item.pricing.unit_price` | número | `articulos.precio1` | Lista de precios 1 (principal) |
| `item.tax_info.is_exempt` | booleano | `articulos.exento` | `1`=Exento de IVA |
| `item.tax_info.iva_rate` | número | `articulos.porc_iva` | p.ej. 16.00 |
| `item.inventory.merkle_root` | texto | *(columna `art_ext.merkle_root`)* | Agregar columna personalizada |

---

## 3. Orden → `ped_venta` / `ped_compra`

| Campo FideX | Tipo | Columna Profit | Notas |
|---|---|---|---|
| `document_info.document_number` | texto | `ped_venta.nro_ped` | |
| `document_info.status` | enum | `ped_venta.status` | `P`=Pendiente, `A`=Aprobado, `C`=Cancelado |
| `document_info.dates.created_at` | fecha/hora | `ped_venta.fecha` | |
| `parties.buyer.rif` | texto | `ped_venta.cod_cli` | Resolver `clientes.rif` → `cod_cli` |
| `payment_terms.exchange_rate_pegged` | número | `ped_venta.tasa_cambio` | Tasa BCV al momento del pedido |
| `lines[].product.gtin` | texto | `ped_det.cod_art` | Resolver via `articulos.cod_barra` |
| `lines[].qty.ordered` | número | `ped_det.cantidad` | |
| `lines[].pricing.unit_price` | número | `ped_det.precio` | |
| `applied_payments[].reference_data.confirmation_number` | texto | `ped_venta.referencia` | Confirmación PagoMóvil |

---

## 4. Nota de Entrega → `guia_despacho`

| Campo FideX | Tipo | Columna Profit | Notas |
|---|---|---|---|
| `document_info.document_number` | texto | `guia_despacho.nro_guia` | |
| `document_info.related_order` | texto | `guia_despacho.nro_ped` | FK a `ped_venta` |
| `logistics.packaging.sscc` | texto | `guia_despacho.sscc` | Columna personalizada; SSCC GS1 |
| `lines[].pharma_tracking.lot_number` | texto | `guia_det.lote` | |
| `lines[].pharma_tracking.expiry_date` | fecha | `guia_det.fecha_venc` | |

---

## 5. Factura / Nota de Crédito / Nota de Débito → `factura` / `nota_cred_deb`

⚠️ **Usar siempre `ProfitSDK.dll`** para crear facturas — nunca inserciones SQL directas en la tabla `factura`.

| Campo FideX | Tipo | Columna Profit | Notas |
|---|---|---|---|
| `document_info.document_number` | texto | `factura.nro_fac` | Auto-generado por Profit; guardar ref. FideX en `factura.ref_externa` |
| `document_info.doc_type` | enum | `factura.tipo_doc` | `F`=Factura, `N`=Nota Crédito, `D`=Nota Débito |
| `parties.payer.rif` | texto | `factura.cod_cli` | Resolver via `clientes.rif` |
| `payment_terms.exchange_rate_pegged` | número | `factura.tasa_cambio` | |
| `lines[].taxes[].type = "IVA"` | — | `fac_det.porc_iva` | |
| `lines[].taxes[].type = "IGTF"` | — | `fac_det.porc_igtf` | Columna separada o extensión personalizada |
| `summary.fiscal_totals_ves.base_imponible_ves` | número | `factura.monto_bruto_bs` | |
| `summary.fiscal_totals_ves.total_iva_ves` | número | `factura.monto_iva_bs` | |
| `fiscal_control.control_number` | texto | `factura.nro_control` | Número de control SENIAT |
| `related_documents[].document_number` | texto | `nota_cred_deb.nro_fac_afectada` | Para NC/ND |

---

## 6. Retención → `comp_ret_iva` / `comp_ret_islr`

| Campo FideX | Tipo | Columna Profit | Notas |
|---|---|---|---|
| `document_info.document_number` | texto | `comp_ret.nro_comprobante` | Número de comprobante SENIAT |
| `document_info.doc_type` | enum | `comp_ret.tipo` | `IVA` o `ISLR` |
| `retention_header.withholder.rif` | texto | `comp_ret.rif_agente` | RIF del agente de retención |
| `retention_header.withheld_party.rif` | texto | `comp_ret.rif_proveedor` | |
| `retention_header.related_invoice` | texto | `comp_ret.nro_factura` | |
| `retention_lines[].taxable_base_usd` | número | `comp_ret_det.base_imponible` | |
| `retention_lines[].retention_rate` | número | `comp_ret_det.porc_retencion` | |
| `retention_lines[].amount_retained_ves` | número | `comp_ret_det.monto_retenido_bs` | |

---

## Notas Importantes

- **Sin API REST nativa en Profit Plus v12**: Toda integración DEBE pasar por el COM SDK o SQL Server. Contactar Softech (soporte@miprofit.com) para acceso al SDK bajo acuerdo de socio.
- **Control de secuencia fiscal**: Nunca insertar directamente en `factura` via SQL. Usar siempre `SDK.Factura.Crear()` para garantizar que `nro_fac` y `nro_control` se emitan en secuencia legal.
- **Columnas personalizadas**: Profit permite agregar columnas a tablas estándar via "Campos adicionales" en el módulo Admin. Usar para `sscc`, `merkle_root`, `x_gln`, etc.
- **Multi-moneda**: Mapear `payment_terms.exchange_rate_pegged` a `tasa_cambio` en todos los encabezados transaccionales.
