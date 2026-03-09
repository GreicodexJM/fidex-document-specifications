# GS1 Identifiers in FideX Payloads

## Why GS1?

GS1 is the global standard for supply chain identification. In the Venezuelan pharmaceutical context, GS1 identifiers are **mandatory** for:
- SICM (Sistema Integral de Control de Medicamentos) pharmaceutical traceability
- Cold-chain compliance and recall management
- Integration with international laboratories and distributors

---

## GTIN — Global Trade Item Number

**Field name in schemas**: `gtin`
**Format**: 13-digit numeric string (EAN-13)
**Required in**: All product line items in Order, ASN, Invoice, Catalog

```json
"product": {
  "gtin": "7591234567890",
  "vendor_part": "LETI-AMOX-500",
  "description": "Amoxicilina 500mg x 21 capsulas"
}
```

### Why GTIN and not just vendor_part?

`vendor_part` codes are internal to each company. `LETI-AMOX-500` is meaningless to Droguería BLV's ERP, which calls the same product `AMOX500C21`. The GTIN is the universal identifier that both ERPs can look up independently:

```
Leti ERP       → GTIN 7591234567890 → "Amoxicilina 500mg Caja 21 caps"
Droguería ERP  → GTIN 7591234567890 → "Amoxicilina 500mg Caja 21 caps"
```

This eliminates the ambiguity between products with similar names but different concentrations (e.g., Amoxicilina 250mg vs 500mg vs 1g).

### Venezuelan GTIN Prefix
Venezuelan GS1 GTINs start with the country prefix `759`. Any GTIN not starting with `759` in a Venezuelan pharmaceutical context should be verified against the GS1 Venezuela registry.

---

## GLN — Global Location Number

**Field name in schemas**: `gln`
**Format**: 13-digit numeric string
**Required in**: `parties.seller`, `parties.shipper` where a physical location is involved

```json
"seller": {
  "name": "Laboratorios Leti — Almacen Central",
  "rif": "J-00000000-1",
  "gln": "7590000000001"
}
```

GLN identifies **physical locations** (warehouses, production sites, delivery points). It enables:
- Routing deliveries to the exact warehouse bay
- 3PL (third-party logistics) providers to match destinations
- GS1 traceability audit trails

---

## SSCC — Serial Shipping Container Code

**Field name in schemas**: `sscc`
**Format**: 18-digit numeric string
**Required in**: `logistics.packaging` in Despatch Advice (ASN)

```json
"packaging": {
  "total_packages": 2,
  "sscc": "175912345678901234"
}
```

### The SSCC "Masterstroke"

The SSCC is a single barcode on a pallet. When a warehouse worker scans this barcode upon receiving a shipment:

1. The ERP queries the ASN for that SSCC
2. The ASN expands to show all GTINs, quantities, lot numbers, and expiry dates in that pallet
3. Thousands of inventory units are registered in seconds — **without opening a single box**

This eliminates the manual counting bottleneck at droguería receiving docks.

---

## SICM — Sistema Integral de Control de Medicamentos

**Field name in schemas**: `sicm`
**Format**: `S-{number}` string
**Required in**: `parties.buyer`, `parties.ship_to` for any pharmaceutical dispatch

```json
"buyer": {
  "name": "Drogueria Distribuidora X",
  "rif": "J-11111111-2",
  "sicm": "S-12345"
}
```

SICM is Venezuela's national pharmaceutical permit registry managed by MPPS (Ministerio del Poder Popular para la Salud). Every droguería and pharmacy must maintain a valid, non-expired SICM permit to legally receive pharmaceutical products.

### SICM as a Hard Block

In the FideX system, if `health_permit.permit_status` is anything other than `VALID`, or if `health_permit.expiration_date` is past the current date, the Kontext Hub **blocks the document from being processed**. This prevents illegal dispatches to unlicensed entities — a critical compliance requirement that legacy CSV/SFTP systems cannot enforce.

See [`schemas/_common/party.schema.json`](../schemas/_common/party.schema.json) for the full health permit structure.

---

## RIF — Registro de Información Fiscal

**Field name in schemas**: `rif`
**Format**: `^[JVEGPjvegp]-[0-9]{8}-[0-9]$`
**Required in**: All party objects (seller, buyer, shipper, ship_to)

```json
"rif": "J-00000000-1"    // Empresa jurídica
"rif": "V-12345678-9"    // Persona natural venezolana
```

| Prefix | Entity Type |
|---|---|
| `J` | Empresa (Sociedad Anónima, C.A., etc.) |
| `V` | Persona Natural Venezolana |
| `E` | Persona Extranjera |
| `G` | Ente Gubernamental |
| `P` | Pasaporte |

The RIF is SENIAT's primary tax identifier and is mandatory on all Venezuelan fiscal documents (invoices, credit notes, retentions).

---

## Identifier Summary Table

| Identifier | Scope | Where Required | Format |
|---|---|---|---|
| `gtin` | Global product ID | All line items | 13-14 digits |
| `gln` | Global location ID | Seller/shipper location | 13 digits |
| `sscc` | Shipping container | ASN packaging block | 18 digits |
| `sicm` | VE pharma permit | Buyer/ship_to parties | `S-{number}` |
| `rif` | VE tax ID | All parties | `X-{8digits}-{digit}` |
