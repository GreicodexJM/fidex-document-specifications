# Integración ERP: Galac Software v5+

> **ERP:** Galac Software v5 (escritorio Windows — enfoque contable y fiscal)  
> **Proveedor:** Galac Software C.A. — https://galac.com.ve  
> **Capa de integración:** Asistente de importación XML/TXT de Galac; DLL de API Galac (`GalacSDK.dll`) para acceso programático en v5

> 🇬🇧 [English version](../../09-erp-mapping/04-galac.md)

---

## Descripción General

Galac es principalmente una plataforma de **contabilidad y cumplimiento fiscal venezolano**, no un ERP completo. Sus fortalezas son:

- **Libros de Ventas / Compras** (reportes IVA SENIAT)
- **Comprobantes de Retención IVA** (Providencia 049/056) e ISLR (Decreto 1808)
- **Declaraciones de IVA** (forma 30) e ISLR

Galac **no** gestiona inventarios, órdenes de compra ni despachos. El adaptador FideX para Galac se enfoca **exclusivamente en la capa fiscal**: facturas, notas de crédito/débito y retenciones.

---

## Referencia de API / Integración

| Mecanismo | Cuándo usar | Endpoint / Método |
|---|---|---|
| **Importación XML de Galac** | Importar facturas y retenciones masivamente | Archivo via Galac → Importar → Facturas/Retenciones |
| **Importación TXT/CSV** | Importación masiva en versiones anteriores | Galac → Herramientas → Importar Datos |
| **Galac SDK DLL** (`GalacSDK.dll`) | Creación programática de documentos en v5 | Interop COM; llamar `GalacSDK.Factura.Crear(...)` |
| **API REST Galac** *(v5.4+, edición cloud)* | Despliegues Galac en nube | Base: `https://{servidor-galac}/api/v1/` |

---

## 1. Ficha de Cliente → `Clientes` / `Proveedores`

| Campo FideX | Tipo | Campo Galac | Notas |
|---|---|---|---|
| `customer_details.internal_id` | texto | `CodCliente` | Alfanumérico; máx. 12 caracteres |
| `customer_details.name` | texto | `RazonSocial` | Nombre legal; máx. 100 caracteres |
| `customer_details.commercial_name` | texto | `NombreComercial` | |
| `customer_details.tax_id` | texto | `RIF` | Formato `J-########-#`; validado por Galac |
| `customer_details.health_permit.sicm` | texto | `NotasCliente` | Campo de notas libres |
| `contact_info.email` | texto | `Email` | |
| `financial_profile.tax_profile.is_retention_agent_iva` | booleano | `AgenteRetencion` | Marca al cliente como agente de retención IVA |
| `financial_profile.tax_profile.retention_percentage` | número | `PorcentajeRetencion` | Por defecto 75.00 |

> **Nota:** Galac no tiene concepto nativo de SICM/GLN. Almacenar en `NotasCliente` (texto libre) solo como referencia; la validación de Nivel 3 es manejada aguas arriba por el Hub FideX, no por Galac.

---

## 2. Catálogo → No aplica

Galac no gestiona catálogo de productos. Los datos del producto (GTIN, descripción, UoM) se incorporan directamente en cada línea de factura.

---

## 3. Orden → No aplica / 4. Nota de Entrega → No aplica

Galac no procesa órdenes ni despachos. Estos permanecen en el ERP operativo (Profit, Saint u Odoo). Galac recibe únicamente la **factura resultante** luego de completar la orden.

---

## 5. Factura / Nota de Crédito / Nota de Débito → `FacturasVentas` / Notas

**Punto principal de integración.** El adaptador FideX convierte `GS1_INVOICE_JSON` al formato de importación de Galac.

| `doc_type` FideX | Documento Galac | Endpoint / Tipo de importación |
|---|---|---|
| `INVOICE` | `FacturaVenta` | `POST /api/v1/facturas` o importación XML |
| `CREDIT_NOTE` | `NotaCredito` | `POST /api/v1/notas/credito` |
| `DEBIT_NOTE` | `NotaDebito` | `POST /api/v1/notas/debito` |

**Campos del encabezado:**

| Campo FideX | Tipo | Campo Galac | Notas |
|---|---|---|---|
| `document_info.document_number` | texto | `NroFactura` | Número legal de la factura |
| `document_info.dates.issued_at` | **fecha** | `FechaFactura` | ⚠️ Solo fecha ISO (`YYYY-MM-DD`); Galac rechaza formato con hora |
| `parties.biller.rif` | texto | `RIFEmisor` | Debe coincidir con `Empresa.RIF` en la configuración de Galac |
| `parties.payer.rif` | texto | `RIFCliente` | FK a `Clientes.RIF` |
| `payment_terms.exchange_rate_pegged` | número | `TasaCambio` | Tasa BCV para conversión a Bs |
| `fiscal_control.control_number` | texto | `NroControl` | Número de control SENIAT |
| `fiscal_control.fiscal_series_letter` | texto | `Serie` | p.ej. `A`, `B` |
| `summary.fiscal_totals_ves.base_imponible_ves` | número | `BaseImponible` | **En Bs (VES)** — Galac usa siempre Bolívares |
| `summary.fiscal_totals_ves.total_iva_ves` | número | `MontoIVA` | En Bs |
| `summary.fiscal_totals_ves.total_igtf_ves` | número | `MontoIGTF` | En Bs; campo separado del IVA |
| `summary.fiscal_totals_ves.total_exempt_ves` | número | `MontoExento` | En Bs |
| `summary.fiscal_totals_ves.total_gross_ves` | número | `MontoTotal` | En Bs |
| `related_documents[].document_number` | texto | `FacturaAfectada` | Para NC/ND: número de la factura original |

**Formato XML de importación Galac (alternativa a REST):**
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

## 6. Retención → `ComprobantesRetencion` *(módulo principal de Galac)*

**El diferenciador principal de Galac** es su módulo de retenciones. Genera y administra comprobantes SENIAT para IVA (Providencia 049/056) e ISLR (Decreto 1808).

| Campo FideX | Tipo | Campo Galac | Notas |
|---|---|---|---|
| `document_info.document_number` | texto | `NroComprobante` | Comprobante SENIAT secuencial; Galac puede asignarlo automáticamente |
| `document_info.doc_type` | enum | `TipoRetencion` | `IVA` / `ISLR` |
| `document_info.dates.issued_at` | fecha | `FechaComprobante` | Solo `YYYY-MM-DD` |
| `retention_header.period` | texto | `Periodo` | Formato `AAAA-MM`; agrupación por período fiscal |
| `retention_header.withholder.rif` | texto | `RIFAgente` | Debe coincidir con `Empresa.RIF` |
| `retention_header.withheld_party.rif` | texto | `RIFProveedor` | Proveedor al que se le retiene |
| `retention_header.related_invoice` | texto | `NroFactura` | Número de factura retenida |
| `retention_lines[].taxable_base_ves` | número | `BaseImponible` | En Bs (principal para libros Galac) |
| `retention_lines[].retention_rate` | número | `PorcentajeRetencion` | p.ej. 75.00 |
| `retention_lines[].amount_retained_ves` | número | `MontoRetenido` | En Bs; registrado en Libro de Compras |

**Campos específicos ISLR:**

| Campo FideX | Tipo | Campo Galac | Notas |
|---|---|---|---|
| `retention_lines[].retention_code` | texto | `CodigoConcepto` | Código Tabla 26 Decreto 1808 (p.ej. `01`) |
| `retention_lines[].activity_description` | texto | `DescripcionConcepto` | Descripción de la actividad |
| `retention_lines[].islr_rate` | número | `AlicuotaISLR` | Alícuota de la Tabla 26 |

---

## Notas Importantes

- **Alcance de Galac**: Solo las capas de factura y retención de FideX se mapean a Galac. Ficha de cliente, catálogo, órdenes y notas de entrega se manejan exclusivamente en el ERP operativo.
- **Formato de fecha**: El asistente de importación de Galac espera `YYYY-MM-DD` (sin hora). Eliminar la hora de todos los campos FideX `issued_at` y `due_date` antes de enviar a Galac.
- **Montos en Bs**: Los libros fiscales de Galac siempre están en Bolívares (VES). Pasar siempre los valores de `fiscal_totals_ves.*` — nunca montos en USD — a los campos `BaseImponible`, `MontoIVA`, `MontoTotal` de Galac.
- **Numeración automática del comprobante SENIAT**: Para retenciones IVA, Galac puede asignar automáticamente el número secuencial si se omite `NroComprobante`. Para ISLR, el número siempre lo asigna manualmente el agente de retención.
- **Libros de Ventas/Compras**: Todas las facturas y retenciones registradas en Galac actualizan automáticamente los libros de IVA. No se requiere acción adicional del adaptador FideX.
