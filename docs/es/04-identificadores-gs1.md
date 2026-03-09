# Identificadores GS1 en los Payloads FideX

> 🇬🇧 [English version](../04-gs1-identifiers.md)

---

## ¿Por qué GS1?

GS1 es el estándar global para la identificación en la cadena de suministro. En el contexto farmacéutico venezolano, los identificadores GS1 son **obligatorios** para:
- Trazabilidad farmacéutica del SICM (Sistema Integral de Control de Medicamentos)
- Cumplimiento de cadena de frío y gestión de retiros del mercado
- Integración con laboratorios y distribuidores internacionales

---

## GTIN — Número Global de Artículo Comercial

**Nombre del campo en schemas**: `gtin`
**Formato**: Cadena numérica de 13 dígitos (EAN-13)
**Requerido en**: Todas las líneas de productos en Orden, ASN, Factura, Catálogo

```json
"product": {
  "gtin": "7591234567890",
  "vendor_part": "LETI-AMOX-500",
  "description": "Amoxicilina 500mg x 21 capsulas"
}
```

### ¿Por qué GTIN y no solo vendor_part?

Los códigos `vendor_part` son internos de cada empresa. `LETI-AMOX-500` no tiene significado para el ERP de Droguería BLV, que llama al mismo producto `AMOX500C21`. El GTIN es el identificador universal que ambos ERPs pueden consultar independientemente:

```
ERP Leti          → GTIN 7591234567890 → "Amoxicilina 500mg Caja 21 caps"
ERP Droguería     → GTIN 7591234567890 → "Amoxicilina 500mg Caja 21 caps"
```

Esto elimina la ambigüedad entre productos con nombres similares pero diferentes concentraciones (ej. Amoxicilina 250mg vs 500mg vs 1g).

### Prefijo GTIN Venezolano
Los GTINs GS1 venezolanos comienzan con el prefijo de país `759`. Cualquier GTIN que no comience con `759` en un contexto farmacéutico venezolano debe verificarse contra el registro GS1 Venezuela.

---

## GLN — Número Global de Localización

**Nombre del campo en schemas**: `gln`
**Formato**: Cadena numérica de 13 dígitos
**Requerido en**: `parties.seller`, `parties.shipper` donde se involucra una ubicación física

```json
"seller": {
  "name": "Laboratorios Leti — Almacén Central",
  "rif": "J-00000000-1",
  "gln": "7590000000001"
}
```

El GLN identifica **ubicaciones físicas** (almacenes, sitios de producción, puntos de entrega). Permite:
- Enrutar entregas al muelle exacto del almacén
- Que los operadores logísticos 3PL (terceros) coincidan destinos
- Registros de trazabilidad de auditoría GS1

---

## SSCC — Código de Contenedor de Envío en Serie

**Nombre del campo en schemas**: `sscc`
**Formato**: Cadena numérica de 18 dígitos
**Requerido en**: `logistics.packaging` en el Aviso de Despacho (ASN)

```json
"packaging": {
  "total_packages": 2,
  "sscc": "175912345678901234"
}
```

### La "Obra Maestra" del SSCC

El SSCC es un único código de barras en un palé. Cuando un empleado del almacén escanea este código al recibir un envío:

1. El ERP consulta el ASN para ese SSCC
2. El ASN despliega todos los GTINs, cantidades, números de lote y fechas de vencimiento de ese palé
3. Miles de unidades de inventario se registran en segundos — **sin abrir ni una sola caja**

Esto elimina el cuello de botella del conteo manual en los muelles de recepción de droguerías.

---

## SICM — Sistema Integral de Control de Medicamentos

**Nombre del campo en schemas**: `sicm`
**Formato**: Cadena `S-{número}`
**Requerido en**: `parties.buyer`, `parties.ship_to` para cualquier despacho farmacéutico

```json
"buyer": {
  "name": "Drogueria Distribuidora X",
  "rif": "J-11111111-2",
  "sicm": "S-12345"
}
```

El SICM es el registro nacional de permisos farmacéuticos de Venezuela, administrado por el MPPS (Ministerio del Poder Popular para la Salud). Toda droguería y farmacia debe mantener un permiso SICM válido y no vencido para recibir legalmente productos farmacéuticos.

### SICM como Bloque Duro

En el sistema FideX, si `health_permit.permit_status` es cualquier valor distinto de `VALID`, o si `health_permit.expiration_date` es anterior a la fecha actual, el Hub Kontext **bloquea el documento para que no sea procesado**. Esto previene despachos ilegales a entidades sin licencia — un requisito de cumplimiento crítico que los sistemas CSV/SFTP legados no pueden enforcar.

Ver [`schemas/_common/party.schema.json`](../../schemas/_common/party.schema.json) para la estructura completa del permiso sanitario.

---

## RIF — Registro de Información Fiscal

**Nombre del campo en schemas**: `rif`
**Formato**: `^[JVEGPjvegp]-[0-9]{8}-[0-9]$`
**Requerido en**: Todos los objetos de parte (vendedor, comprador, despachador, destinatario)

```json
"rif": "J-00000000-1"    // Empresa jurídica
"rif": "V-12345678-9"    // Persona natural venezolana
```

| Prefijo | Tipo de Entidad |
|---|---|
| `J` | Empresa (Sociedad Anónima, C.A., etc.) |
| `V` | Persona Natural Venezolana |
| `E` | Persona Extranjera |
| `G` | Ente Gubernamental |
| `P` | Pasaporte |

El RIF es el identificador tributario principal del SENIAT y es obligatorio en todos los documentos fiscales venezolanos (facturas, notas de crédito, retenciones).

---

## Tabla Resumen de Identificadores

| Identificador | Alcance | Dónde se Requiere | Formato |
|---|---|---|---|
| `gtin` | ID global de producto | Todas las líneas | 13-14 dígitos |
| `gln` | ID global de ubicación | Ubicación vendedor/despachador | 13 dígitos |
| `sscc` | Contenedor de envío | Bloque de empaquetado ASN | 18 dígitos |
| `sicm` | Permiso farmacéutico VE | Partes comprador/destinatario | `S-{número}` |
| `rif` | ID tributario VE | Todas las partes | `X-{8dígitos}-{dígito}` |
