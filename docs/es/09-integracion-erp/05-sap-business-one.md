# Integración ERP: SAP Business One 10.0

> **ERP:** SAP Business One (SAP B1) 10.0 — on-premise o SAP B1 Cloud  
> **Proveedor:** SAP SE — https://www.sap.com/products/erp/business-one.html  
> **Capa de integración:** SAP B1 Service Layer (REST/JSON, HTTPS puerto 50000)  
> **Alternativa:** SAP B1 DI API (COM/VB.NET) para integraciones on-premise heredadas  
> **Motor de base de datos:** SAP HANA (recomendado) o Microsoft SQL Server

> 🇬🇧 [English version](../../09-erp-mapping/05-sap-business-one.md)

---

## Referencia de API

SAP Business One Service Layer es la API REST moderna disponible desde SAP B1 9.3+.

**URL base:** `https://{servidor-b1}:50000/b1s/v1/`

| Operación | Método | Endpoint | Notas |
|---|---|---|---|
| Login | `POST` | `/b1s/v1/Login` | Devuelve cookie `B1SESSION`; obligatoria en todas las peticiones |
| Logout | `POST` | `/b1s/v1/Logout` | Invalida la sesión |
| Socio de Negocios crear | `POST` | `/b1s/v1/BusinessPartners` | |
| Socio de Negocios actualizar | `PATCH` | `/b1s/v1/BusinessPartners('{CardCode}')` | |
| Artículo crear | `POST` | `/b1s/v1/Items` | |
| Artículo actualizar | `PATCH` | `/b1s/v1/Items('{ItemCode}')` | |
| Orden de Venta | `POST` | `/b1s/v1/Orders` | |
| Orden de Compra | `POST` | `/b1s/v1/PurchaseOrders` | |
| Nota de Entrega | `POST` | `/b1s/v1/DeliveryNotes` | |
| Factura C/C | `POST` | `/b1s/v1/Invoices` | |
| Nota de Crédito C/C | `POST` | `/b1s/v1/CreditNotes` | |
| Consulta OData | `GET` | `/b1s/v1/{Objeto}?$filter=...` | Soporte completo OData v4 |

**Login:**
```
POST https://{servidor}:50000/b1s/v1/Login
{ "CompanyDB": "LETI_PROD", "UserName": "fidex_adapter", "Password": "••••••" }
→ Set-Cookie: B1SESSION=abc123; ROUTEID=.node1
```

Incluir ambas cookies en todas las peticiones siguientes: `Cookie: B1SESSION=abc123; ROUTEID=.node1`

---

## 1. Ficha de Cliente → `BusinessPartners` (OCRD)

**Estrategia:** `GET /b1s/v1/BusinessPartners('{CardCode}')` — si 200 usar `PATCH`, si 404 usar `POST`. `CardType = "C"` para clientes.

| Campo FideX | Tipo | Campo SAP B1 | Objeto | Notas |
|---|---|---|---|---|
| `customer_details.internal_id` | texto | `CardCode` | `OCRD` | Máx. 15 caracteres |
| `customer_details.name` | texto | `CardName` | `OCRD` | Nombre legal |
| `customer_details.commercial_name` | texto | `AliasName` | `OCRD` | Nombre comercial |
| `customer_details.tax_id` | texto | `FederalTaxID` | `OCRD` | RIF; usar para búsqueda OData |
| `customer_details.gln` | texto | `U_GLN` | `OCRD` | Campo definido por usuario (UDF) |
| `customer_details.health_permit.sicm` | texto | `U_SICM` | `OCRD` | UDF; crear en Herramientas → Campos Definidos por Usuario |
| `customer_details.health_permit.permit_status` | enum | `U_SICM_STATUS` | `OCRD` | UDF; `VALID`/`EXPIRED`/`SUSPENDED` |
| `customer_details.health_permit.expiration_date` | fecha | `U_SICM_EXPIRY` | `OCRD` | UDF tipo Fecha |
| `financial_profile.credit_limit.amount` | número | `CreditLimit` | `OCRD` | En moneda base de la empresa |
| `financial_profile.credit_status` | enum | `Frozen` | `OCRD` | `tNO`=Activo, `tYES`=Bloqueado |
| `financial_profile.payment_terms.term_type` | enum | `PayTermsGrpCode` | `OCRD` | FK a condiciones de pago B1 (entero) |
| `financial_profile.tax_profile.is_retention_agent_iva` | booleano | `U_RET_IVA_AGENT` | `OCRD` | UDF Booleano |
| `financial_profile.tax_profile.retention_percentage` | número | `U_RET_IVA_PCT` | `OCRD` | UDF Float; por defecto 75.00 |
| `sales_routing.assigned_agent.employee_id` | texto | `SalesPersonCode` | `OCRD` | FK a `OSLP.SlpCode` |
| `addresses[billing].street` | texto | `BillToStreet` | `OCRD` | |
| `addresses[billing].city` | texto | `BillToCity` | `OCRD` | |
| `addresses[billing].state` | texto | `BillToState` | `OCRD` | Estado venezolano |

**Búsqueda OData por RIF:**
```
GET /b1s/v1/BusinessPartners?$filter=FederalTaxID eq 'J222222223'&$select=CardCode
```

---

## 2. Catálogo → `Items` (OITM)

| Campo FideX | Tipo | Campo SAP B1 | Objeto | Notas |
|---|---|---|---|---|
| `item.gtin` | texto | `CodeBars` | `OITM` | GTIN-14 GS1 |
| `item.vendor_part` | texto | `ItemCode` | `OITM` | Código interno; máx. 20 caracteres |
| `item.description` | texto | `ItemName` | `OITM` | |
| `item.pharma.lot_tracking` | booleano | `ManSerNum` | `OITM` | `L`=Lote (usar para farmacéuticos) |
| `item.pharma.requires_refrigeration` | booleano | `U_COLD_CHAIN` | `OITM` | UDF |
| `item.pricing.unit_price` | número | `Price` | `OITM` | Precio base en listas de precios |
| `item.tax_info.is_exempt` | booleano | `TaxCodeAR` | `OITM` | Asignar código de exento (p.ej. `EXENTO`) |
| `item.inventory.merkle_root` | texto | `U_MERKLE_ROOT` | `OITM` | UDF para sincronización delta |

---

## 3. Orden → `Orders` (ORDR) / `PurchaseOrders` (OPOR)

| Campo FideX | Tipo | Campo SAP B1 | Objeto | Notas |
|---|---|---|---|---|
| `document_info.document_number` | texto | `NumAtCard` | `ORDR` | Referencia de orden del cliente |
| `document_info.dates.created_at` | fecha | `DocDate` | `ORDR` | |
| `document_info.dates.delivery_requested` | fecha | `DocDueDate` | `ORDR` | |
| `parties.buyer.rif` | texto | `CardCode` | `ORDR` | Resolver via `FederalTaxID` |
| `payment_terms.exchange_rate_pegged` | número | `DocRate` | `ORDR` | Tasa de cambio BCV |
| `lines[].product.gtin` | texto | `ItemCode` | `RDR1` | Resolver via consulta `CodeBars` |
| `lines[].qty.ordered` | número | `Quantity` | `RDR1` | |
| `lines[].pricing.unit_price` | número | `UnitPrice` | `RDR1` | |
| `lines[].taxes[].type` | texto | `TaxCode` | `RDR1` | `IVA16`, `IGTF3`, `EXENTO` |
| `applied_payments[].reference_data.confirmation_number` | texto | `U_PAGO_MOVIL_REF` | `ORDR` | UDF; referencia PagoMóvil |

---

## 4. Nota de Entrega → `DeliveryNotes` (ODLN)

**Estrategia:** crear desde Orden de Venta usando `BaseType=17` y `BaseEntry` (DocEntry de la orden).

| Campo FideX | Tipo | Campo SAP B1 | Objeto | Notas |
|---|---|---|---|---|
| `document_info.document_number` | texto | `NumAtCard` | `ODLN` | Número externo del ASN |
| `logistics.packaging.sscc` | texto | `U_SSCC` | `ODLN` | UDF; SSCC-18 GS1 |
| `logistics.driver.vehicle_plate` | texto | `U_VEHICLE_PLATE` | `ODLN` | UDF |
| `lines[].qty.shipped` | número | `Quantity` | `DLN1` | |
| `lines[].pharma_tracking.lot_number` | texto | `BatchNumber` | `BatchNumbers` | Sub-arreglo de números de lote |
| `lines[].pharma_tracking.expiry_date` | fecha | `ExpiryDate` | `BatchNumbers` | |

⚠️ **SAP B1 requiere que los números de lote se registren en la Nota de Entrega**, no en la factura. El adaptador FideX debe crear primero la entrega y luego la factura cuando el seguimiento por lotes está activo.

---

## 5. Factura / Nota de Crédito / Nota de Débito → `Invoices` / `CreditNotes` (OINV / ORIN)

| `doc_type` FideX | Objeto SAP B1 | Endpoint |
|---|---|---|
| `INVOICE` | Factura C/C (`OINV`) | `POST /b1s/v1/Invoices` |
| `CREDIT_NOTE` | Nota de Crédito C/C (`ORIN`) | `POST /b1s/v1/CreditNotes` |
| `DEBIT_NOTE` | Factura C/C (diario separado) | `POST /b1s/v1/Invoices` con UDF `U_DOC_TYPE=DN` |

| Campo FideX | Tipo | Campo SAP B1 | Objeto | Notas |
|---|---|---|---|---|
| `document_info.document_number` | texto | `NumAtCard` | `OINV` | |
| `parties.payer.rif` | texto | `CardCode` | `OINV` | Resolver via `FederalTaxID` |
| `payment_terms.exchange_rate_pegged` | número | `DocRate` | `OINV` | Tasa BCV |
| `lines[].taxes[].type` | texto | `TaxCode` | `INV1` | `IVA16`, `IGTF3`, `EXENTO` |
| `summary.fiscal_totals_ves.base_imponible_ves` | número | `U_BASE_IMP_VES` | `OINV` | UDF |
| `summary.fiscal_totals_ves.total_iva_ves` | número | `U_IVA_VES` | `OINV` | UDF |
| `summary.fiscal_totals_ves.total_igtf_ves` | número | `U_IGTF_VES` | `OINV` | UDF |
| `fiscal_control.control_number` | texto | `U_NRO_CONTROL` | `OINV` | UDF; número de control SENIAT |
| `related_documents[].document_number` | texto | `NumAtCard` (factura base) | `ORIN` | Para NC: `BaseType=13` en líneas |

---

## 6. Retención Fiscal → Código de Retención o UDO

SAP B1 no tiene documento de retención venezolano nativo. Usar una de dos opciones:

### Opción A — Código de Retención en líneas de factura (recomendado para IVA)

Configurar un **Código de Impuesto Retenido** (OWHT) para retención IVA (75%) y códigos ISLR:

```json
"WTInformation": [{
  "WTCode": "RET-IVA-75",
  "WTAmnt": 18.00
}]
```

Almacenar el número de comprobante SENIAT en UDF `U_COMPROBANTE` sobre el encabezado `OINV`.

### Opción B — Objeto Definido por Usuario `U_RETENCION`

Crear un UDO `U_RETENCION` via SDK o Service Layer:

| Campo FideX | Tipo | Campo UDO | Notas |
|---|---|---|---|
| `document_info.document_number` | texto | `U_NroComprobante` | |
| `document_info.doc_type` | enum | `U_TipoRet` | `IVA` / `ISLR` |
| `retention_header.withholder.rif` | texto | `U_RifAgente` | |
| `retention_header.withheld_party.rif` | texto | `U_RifProveedor` | |
| `retention_header.related_invoice` | texto | `U_NroFactura` | |
| `retention_lines[].taxable_base_ves` | número | `U_BaseImponible` | |
| `retention_lines[].retention_rate` | número | `U_PorcRet` | |
| `retention_lines[].amount_retained_ves` | número | `U_MontoRetenido` | |

---

## Notas Importantes

- **Creación de UDFs**: Todos los campos `U_*` deben crearse como Campos Definidos por Usuario antes de ejecutar la integración. Ir a SAP B1 → Herramientas → Herramientas de Personalización → Administración de Campos Definidos por Usuario.
- **Gestión de sesión**: Las sesiones de Service Layer expiran después de 30 minutos de inactividad. Implementar re-login o refresh de sesión en el cliente HTTP del adaptador FideX.
- **Localización venezolana (SAP B1 VE)**: Los socios SAP en Venezuela ofrecen un add-on de localización que agrega validación de RIF, libros IVA/ISLR y módulos de reportes SENIAT. Verificar disponibilidad con el socio SAP local (p.ej. **TechGestion**, **BM Tech**).
- **Documentación Service Layer**: https://sap.github.io/SAPBusinessOne-ServiceLayer-Reference/
