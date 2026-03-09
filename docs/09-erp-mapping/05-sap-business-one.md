# ERP Mapping: SAP Business One 10.0

> **ERP:** SAP Business One (SAP B1) 10.0 — on-premise or SAP B1 Cloud  
> **Vendor:** SAP SE — https://www.sap.com/products/erp/business-one.html  
> **Integration layer:** SAP B1 Service Layer (REST/JSON, HTTPS port 50000)  
> **Alternative:** SAP B1 DI API (COM/VB.NET) for on-premise legacy integrations  
> **Database engine:** SAP HANA (preferred) or Microsoft SQL Server

---

## API / Integration Reference

SAP Business One Service Layer is the modern REST API available from SAP B1 9.3+. It exposes all B1 business objects as JSON resources.

| Operation | Method | Endpoint | Notes |
|---|---|---|---|
| Login | `POST` | `/b1s/v1/Login` | Returns `SessionId` cookie; must be sent in all subsequent requests |
| Logout | `POST` | `/b1s/v1/Logout` | Invalidates session |
| Business Partner create | `POST` | `/b1s/v1/BusinessPartners` | |
| Business Partner update | `PATCH` | `/b1s/v1/BusinessPartners('{CardCode}')` | |
| Business Partner get | `GET` | `/b1s/v1/BusinessPartners('{CardCode}')` | OData filter supported |
| Item Master create | `POST` | `/b1s/v1/Items` | |
| Item Master update | `PATCH` | `/b1s/v1/Items('{ItemCode}')` | |
| Sales Order create | `POST` | `/b1s/v1/Orders` | |
| Purchase Order create | `POST` | `/b1s/v1/PurchaseOrders` | |
| Delivery create | `POST` | `/b1s/v1/DeliveryNotes` | |
| A/R Invoice create | `POST` | `/b1s/v1/Invoices` | |
| A/R Credit Memo create | `POST` | `/b1s/v1/CreditNotes` | |
| Query (OData) | `GET` | `/b1s/v1/{Object}?$filter=...&$select=...` | Full OData v4 query support |

**Base URL:** `https://{b1-server}:50000/b1s/v1/`

**Login:**
```
POST https://{b1-server}:50000/b1s/v1/Login
Content-Type: application/json

{
  "CompanyDB": "LETI_PROD",
  "UserName": "fidex_adapter",
  "Password": "••••••"
}

→ 200 OK
Set-Cookie: B1SESSION=abc123; path=/b1s
Set-Cookie: ROUTEID=.node1; path=/b1s
```

All subsequent requests must include both cookies:
```
Cookie: B1SESSION=abc123; ROUTEID=.node1
```

---

## 1. Customer Master → `BusinessPartners` (OCRD)

**Upsert strategy:** `GET /b1s/v1/BusinessPartners('{CardCode}')` — if 200 use `PATCH`, if 404 use `POST`.  
**CardType** must be `C` (Customer) or `S` (Supplier). For pharma distributors, always `C`.

| FideX field | Type | SAP B1 field | Object | Notes |
|---|---|---|---|---|
| `customer_details.internal_id` | string | `CardCode` | `OCRD` | Max 15 chars; maps to `cod_cli` |
| `customer_details.name` | string | `CardName` | `OCRD` | Legal name; max 100 chars |
| `customer_details.commercial_name` | string | `AliasName` | `OCRD` | Trading name |
| `customer_details.tax_id` | string | `FederalTaxID` | `OCRD` | RIF without dashes; or full formatted |
| `customer_details.gln` | string | `U_GLN` | `OCRD` | User-defined field (UDF); create as `UDF_GLN` |
| `customer_details.health_permit.sicm` | string | `U_SICM` | `OCRD` | UDF; create via Tools → User-Defined Fields |
| `customer_details.health_permit.permit_status` | enum | `U_SICM_STATUS` | `OCRD` | UDF; `VALID`/`EXPIRED`/`SUSPENDED` |
| `customer_details.health_permit.expiration_date` | date | `U_SICM_EXPIRY` | `OCRD` | UDF Date type |
| `customer_details.customer_type` | enum | `GroupCode` | `OCRD` | Map to B1 Customer Group; `GroupCode` is integer |
| `contact_info.email` | string | `EmailAddress` | `OCRD` | |
| `contact_info.phone` | string | `Phone1` | `OCRD` | |
| `financial_profile.credit_limit.amount` | number | `CreditLimit` | `OCRD` | In base company currency |
| `financial_profile.credit_status` | enum | `Frozen` | `OCRD` | `tNO`=Active, `tYES`=Blocked |
| `financial_profile.payment_terms.term_type` | enum | `PayTermsGrpCode` | `OCRD` | FK to B1 Payment Terms; integer code |
| `financial_profile.tax_profile.is_retention_agent_iva` | boolean | `U_RET_IVA_AGENT` | `OCRD` | UDF Boolean |
| `financial_profile.tax_profile.retention_percentage` | number | `U_RET_IVA_PCT` | `OCRD` | UDF Float |
| `sales_routing.assigned_agent.employee_id` | string | `SalesPersonCode` | `OCRD` | FK to `OSLP.SlpCode` |
| `addresses[billing].street` | string | `BillToStreet` | `OCRD` | |
| `addresses[billing].city` | string | `BillToCity` | `OCRD` | |
| `addresses[billing].state` | string | `BillToState` | `OCRD` | Venezuelan state code |
| `addresses[billing].zip` | string | `BillToZipCode` | `OCRD` | |
| `addresses[shipping].street` | string | `ShipToStreet` | `OCRD` | Primary shipping; additional in `BPAddresses` array |

**Service Layer create:**
```
POST /b1s/v1/BusinessPartners
Cookie: B1SESSION=...

{
  "CardCode": "C-10045",
  "CardName": "Farmacia El Pueblo C.A.",
  "CardType": "C",
  "FederalTaxID": "J222222223",
  "CreditLimit": 5000.00,
  "U_SICM": "S-98765",
  "U_SICM_STATUS": "VALID",
  "U_RET_IVA_AGENT": "Y",
  "U_RET_IVA_PCT": 75.00
}
```

---

## 2. Catalog → `Items` (OITM)

**Upsert strategy:** `GET /b1s/v1/Items('{ItemCode}')` — PATCH if exists, POST if new.

| FideX field | Type | SAP B1 field | Object | Notes |
|---|---|---|---|---|
| `item.gtin` | string | `CodeBars` | `OITM` | GS1 GTIN-14 |
| `item.vendor_part` | string | `ItemCode` | `OITM` | Internal item code; max 20 chars |
| `item.description` | string | `ItemName` | `OITM` | |
| `item.uom` | string | `SalesUnit` / `PurchaseUnit` | `OITM` | UoM name string |
| `item.pharma.active_ingredient` | string | `U_ACTIVE_ING` | `OITM` | UDF |
| `item.pharma.concentration` | string | `U_CONCENTRATION` | `OITM` | UDF |
| `item.pharma.presentation` | string | `U_PRESENTATION` | `OITM` | UDF |
| `item.pharma.requires_refrigeration` | boolean | `U_COLD_CHAIN` | `OITM` | UDF; `Y`/`N` |
| `item.pharma.lot_tracking` | boolean | `ManSerNum` | `OITM` | `S`=Serial, `L`=Lot, `N`=None; use `L` |
| `item.pricing.unit_price` | number | `Price` | `OITM` | Base price in `SalesPriceLists` |
| `item.tax_info.is_exempt` | boolean | `TaxCodeAR` | `OITM` | Set to exempt tax code (e.g. `EXENTO`) |
| `item.tax_info.iva_rate` | number | *(via TaxCodeAR)* | `OVTG` | Rate is on the tax code, not the item |
| `item.inventory.merkle_root` | string | `U_MERKLE_ROOT` | `OITM` | UDF; for delta sync tracking |

**Service Layer create:**
```
POST /b1s/v1/Items
Cookie: B1SESSION=...

{
  "ItemCode": "LETI-AMOX-500",
  "ItemName": "Amoxicilina 500mg x21 capsulas",
  "CodeBars": "07591234567890",
  "ManSerNum": "L",
  "TaxCodeAR": "IVA16",
  "U_COLD_CHAIN": "N"
}
```

---

## 3. Order → `Orders` (ORDR) / `PurchaseOrders` (OPOR)

**`PURCHASE_ORDER`** (seller side) → `Orders` (Sales Order, ORDR)  
**`PURCHASE_ORDER`** (buyer side) → `PurchaseOrders` (OPOR)  
**`QUOTE`** → `Quotations` (OQUT, `/b1s/v1/Quotations`)  
**`ORDER_CONFIRMED`** → confirm by updating `DocStatus` to `O` (Open/Approved)

| FideX field | Type | SAP B1 field | Object | Notes |
|---|---|---|---|---|
| `document_info.document_number` | string | `NumAtCard` | `ORDR` | Customer/vendor order ref |
| `document_info.status` | enum | `DocStatus` | `ORDR` | `O`=Open, `C`=Closed |
| `document_info.dates.created_at` | date | `DocDate` | `ORDR` | |
| `document_info.dates.delivery_requested` | date | `DocDueDate` | `ORDR` | |
| `document_info.dates.expiration` | date | `DocDueDate` | `OQUT` | For quotes |
| `parties.buyer.rif` | string | `CardCode` | `ORDR` | Resolve via `FederalTaxID` |
| `parties.ship_to.rif` | string | `ShipToCode` | `ORDR` | Address code from BP master |
| `payment_terms.term_type` | enum | `PaymentGroupCode` | `ORDR` | FK to B1 Payment Terms |
| `payment_terms.exchange_rate_pegged` | number | `DocRate` | `ORDR` | Exchange rate header |
| `lines[].product.gtin` | string | `ItemCode` | `RDR1` | Resolve via `CodeBars` query |
| `lines[].qty.ordered` | number | `Quantity` | `RDR1` | |
| `lines[].qty.uom` | string | `UnitOfMeasure` | `RDR1` | |
| `lines[].pricing.unit_price` | number | `UnitPrice` | `RDR1` | |
| `lines[].discounts_charges[].percentage` | number | `DiscountPercent` | `RDR1` | |
| `lines[].taxes[].type = "IVA"` | — | `TaxCode` | `RDR1` | Tax code name (e.g. `IVA16`) |
| `lines[].pharma_tracking.lot_number` | string | *(set at delivery)* | `OBIN` | Lot set on delivery/goods receipt |
| `applied_payments[].reference_data.confirmation_number` | string | `U_PAGO_MOVIL_REF` | `ORDR` | UDF; PagoMóvil confirmation |

---

## 4. Despatch Advice → `DeliveryNotes` (ODLN)

**Strategy:** Create from Sales Order using `BaseType=17` (Sales Order) and `BaseEntry` (order `DocEntry`).

| FideX field | Type | SAP B1 field | Object | Notes |
|---|---|---|---|---|
| `document_info.document_number` | string | `NumAtCard` | `ODLN` | External ASN number |
| `document_info.related_order` | string | `NumAtCard` | `ORDR` | Resolve `DocEntry` to set `BaseEntry` |
| `document_info.dates.issued_at` | date | `DocDate` | `ODLN` | |
| `document_info.dates.estimated_delivery` | date | `DocDueDate` | `ODLN` | |
| `parties.ship_to.rif` | string | `CardCode` | `ODLN` | |
| `logistics.carrier.name` | string | `TransportName` | `ODLN` | |
| `logistics.driver.vehicle_plate` | string | `U_VEHICLE_PLATE` | `ODLN` | UDF |
| `logistics.packaging.sscc` | string | `U_SSCC` | `ODLN` | UDF; GS1 SSCC-18 |
| `lines[].product.gtin` | string | `ItemCode` | `DLN1` | |
| `lines[].qty.shipped` | number | `Quantity` | `DLN1` | |
| `lines[].pharma_tracking.lot_number` | string | `BatchNumber` | `DLN1` (via `BatchNumbers`) | Set in `BatchNumbers` sub-array |
| `lines[].pharma_tracking.expiry_date` | date | `ExpiryDate` | `BatchNumbers` | |

**Service Layer create (delivery from SO):**
```
POST /b1s/v1/DeliveryNotes
Cookie: B1SESSION=...

{
  "CardCode": "C-10045",
  "DocDate": "2026-02-28",
  "DocumentLines": [{
    "ItemCode": "LETI-AMOX-500",
    "Quantity": 50,
    "BaseType": 17,
    "BaseEntry": 142,
    "BaseLine": 0,
    "BatchNumbers": [{
      "BatchNumber": "L-202509A",
      "Quantity": 50,
      "ExpiryDate": "2028-09-01"
    }]
  }]
}
```

---

## 5. Invoice / Credit Note / Debit Note → `Invoices` / `CreditNotes` (OINV / ORIN)

**`doc_type` → Service Layer object:**

| FideX `doc_type` | SAP B1 object | Endpoint |
|---|---|---|
| `INVOICE` | A/R Invoice (`OINV`) | `POST /b1s/v1/Invoices` |
| `CREDIT_NOTE` | A/R Credit Memo (`ORIN`) | `POST /b1s/v1/CreditNotes` |
| `DEBIT_NOTE` | A/R Invoice (separate journal) | `POST /b1s/v1/Invoices` with `U_DOC_TYPE=DN` UDF |

| FideX field | Type | SAP B1 field | Object | Notes |
|---|---|---|---|---|
| `document_info.document_number` | string | `NumAtCard` | `OINV` | Customer invoice ref |
| `document_info.status` | enum | `DocStatus` | `OINV` | `O`=Open, `C`=Paid/Closed |
| `document_info.dates.issued_at` | date | `DocDate` | `OINV` | |
| `document_info.dates.due_date` | date | `DocDueDate` | `OINV` | |
| `document_info.related_order` | string | *(via `BaseEntry` on lines)* | `INV1` | Link lines to SO via `BaseType=17` |
| `document_info.related_asn` | string | *(via `BaseEntry` on lines)* | `INV1` | Link lines to Delivery via `BaseType=15` |
| `parties.payer.rif` | string | `CardCode` | `OINV` | Resolve via `FederalTaxID` |
| `payment_terms.exchange_rate_pegged` | number | `DocRate` | `OINV` | BCV rate header |
| `lines[].product.gtin` | string | `ItemCode` | `INV1` | |
| `lines[].qty.invoiced` | number | `Quantity` | `INV1` | |
| `lines[].pricing.unit_price` | number | `UnitPrice` | `INV1` | |
| `lines[].taxes[].type` | string | `TaxCode` | `INV1` | `IVA16`, `IGTF3`, `EXENTO` |
| `summary.total_net_usd` | number | `DocTotal` (pre-tax) | `OINV` | |
| `summary.total_gross_usd` | number | `DocTotal` | `OINV` | Final total incl. taxes |
| `summary.fiscal_totals_ves.exchange_rate_applied` | number | `DocRate` | `OINV` | |
| `summary.fiscal_totals_ves.base_imponible_ves` | number | `U_BASE_IMP_VES` | `OINV` | UDF |
| `summary.fiscal_totals_ves.total_iva_ves` | number | `U_IVA_VES` | `OINV` | UDF |
| `summary.fiscal_totals_ves.total_igtf_ves` | number | `U_IGTF_VES` | `OINV` | UDF |
| `fiscal_control.control_number` | string | `U_NRO_CONTROL` | `OINV` | UDF; SENIAT control number |
| `fiscal_control.fiscal_series_letter` | string | `U_FISCAL_SERIES` | `OINV` | UDF |
| `related_documents[].document_number` | string | `NumAtCard` (of base invoice) | `ORIN` | For CN: set `BaseType=13` on lines |

---

## 6. Tax Retention → User-Defined Object / `WithholdingTaxCodes`

SAP B1 does not have a native Venezuelan retention document. Implementation uses one of two approaches:

### Option A — Withholding Tax on Invoice Lines (recommended for IVA)

Configure a **Withholding Tax Code** for IVA retention (75%) and ISLR codes:

| FideX field | Type | SAP B1 field | Notes |
|---|---|---|---|
| `retention_lines[].tax_type` | enum | `WTCode` | `OWHT` withholding tax code (e.g. `RET-IVA-75`, `ISLR-01`) |
| `retention_lines[].retention_rate` | number | `Rate` | Configured on `OWHT` code |
| `retention_lines[].amount_retained_usd` | number | `WTAmnt` | Auto-calculated when `WTCode` applied to invoice line |
| `document_info.document_number` | string | `U_COMPROBANTE` | UDF on `OINV`; store SENIAT comprobante ref |

Apply withholding codes to invoice lines in `INV1.WTInformation` array:
```json
"WTInformation": [{
  "WTCode": "RET-IVA-75",
  "WTAmnt": 18.00
}]
```

### Option B — User-Defined Object (full retention document)

Create a User-Defined Object `U_RETENCION` via SAP B1 SDK or SL with:

| FideX field | Type | UDO field | Notes |
|---|---|---|---|
| `document_info.document_number` | string | `U_NroComprobante` | |
| `document_info.doc_type` | enum | `U_TipoRet` | `IVA` / `ISLR` |
| `document_info.dates.issued_at` | date | `U_Fecha` | |
| `retention_header.withholder.rif` | string | `U_RifAgente` | |
| `retention_header.withheld_party.rif` | string | `U_RifProveedor` | |
| `retention_header.related_invoice` | string | `U_NroFactura` | |
| `retention_lines[].taxable_base_ves` | number | `U_BaseImponible` | |
| `retention_lines[].retention_rate` | number | `U_PorcRet` | |
| `retention_lines[].amount_retained_ves` | number | `U_MontoRetenido` | |

**Service Layer UDO endpoint (after creation):**
```
POST /b1s/v1/U_RETENCION
Cookie: B1SESSION=...

{
  "U_NroComprobante": "RET-IVA-2026-00089",
  "U_TipoRet": "IVA",
  "U_Fecha": "2026-03-11",
  "U_RifAgente": "J-11111111-2",
  "U_RifProveedor": "J-00000000-1",
  "U_NroFactura": "INV-2026-00146",
  "U_BaseImponible": 1080.00,
  "U_PorcRet": 75.00,
  "U_MontoRetenido": 810.00
}
```

---

## Key Notes

- **UDF creation**: All `U_*` fields (GLN, SICM, fiscal VES totals, etc.) must be created as User-Defined Fields before the integration runs. Use SAP B1 → Tools → Customization Tools → User-Defined Fields - Management.
- **Session management**: SAP B1 Service Layer sessions expire after 30 minutes of inactivity. Implement session refresh or re-login in the FideX adapter's HTTP client.
- **OData queries for RIF lookup**: To resolve `FederalTaxID` → `CardCode`, use:  
  `GET /b1s/v1/BusinessPartners?$filter=FederalTaxID eq 'J222222223'&$select=CardCode`
- **Lot numbers on invoices**: SAP B1 requires lot numbers to be recorded on the Delivery Note (`ODLN`), not on the invoice. The FideX adapter must create the Delivery before the Invoice when lot tracking is enabled.
- **Venezuela localization (SAP B1 VE)**: SAP partners in Venezuela offer a localization add-on that adds native RIF validation, IVA/ISLR retention books, and SENIAT fiscal report modules. Verify with the local SAP partner (e.g. **TechGestion**, **BM Tech**) for availability.
- **Service Layer documentation**: https://sap.github.io/SAPBusinessOne-ServiceLayer-Reference/ (unofficial community reference) and SAP Help Portal: https://help.sap.com/viewer/e0d4539d39d34f0abe9b40e4a5b6582d/
