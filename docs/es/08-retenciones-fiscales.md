# Retenciones Fiscales en FideX

> 🇬🇧 [English version](../08-tax-retention.md)

Este documento explica el mecanismo de retención en la fuente del IVA e ISLR en Venezuela, y cómo se representa en el estándar FideX mediante el tipo de documento `GS1_RETENTION_JSON`.

---

## ¿Qué es una Retención Fiscal?

En Venezuela, los **Contribuyentes Especiales** designados por el SENIAT tienen la obligación de **retener (descontar del pago)** una parte del IVA y/o ISLR que deben pagarle a sus proveedores, y enterarlo directamente al fisco.

El resultado es:
1. El proveedor recibe el pago **menos** el monto retenido.
2. El proveedor obtiene un **Comprobante de Retención** que certifica que el impuesto fue pagado por su cuenta.
3. El proveedor usa ese comprobante como **crédito fiscal** en sus declaraciones mensuales.

---

## Retención IVA (`doc_type: RETENTION_IVA`)

### Base Legal
- **SENIAT Providencia Administrativa N° 049** (sectores generales)
- **SENIAT Providencia Administrativa N° 056** (bancos y aseguradoras)

### Mecánica de Cálculo

```
IVA de la Factura   = Base Imponible × 16%
Monto Retenido      = IVA de la Factura × 75%  (alícuota por defecto)
Monto a Pagar       = Total Factura − Monto Retenido
```

**Ejemplo con factura de $50 USD base imponible:**
```
IVA Factura     = $50.00 × 16%    = $8.00 USD
Monto Retenido  = $8.00 × 75%     = $6.00 USD
Monto a Pagar   = ($50.00 + $8.00) − $6.00 = $52.00 USD
```

### Payload FideX

```json
{
  "document_type": "GS1_RETENTION_JSON",
  "document_info": {
    "doc_type": "RETENTION_IVA",
    "document_number": "RET-IVA-2026-00089",
    "retention_period": "2026-03"
  },
  "retention_header": {
    "withholder": { "rif": "J-11111111-2", "name": "Drogueria X" },
    "withheld_party": { "rif": "J-00000000-1", "name": "Lab. LETI" },
    "related_invoice": "INV-2026-00146"
  },
  "retention_lines": [
    {
      "tax_type": "IVA",
      "taxable_base_usd": 50.00,
      "taxable_base_ves": 2250.00,
      "retention_rate": 75.00,
      "amount_retained_usd": 6.00,
      "amount_retained_ves": 270.00
    }
  ]
}
```

### ¿Quién retiene?
- Solo los **Contribuyentes Especiales** pueden ser Agentes de Retención IVA.
- La designación la otorga el SENIAT y se publica en la página web del SENIAT.
- En la cadena farmacéutica venezolana, las grandes droguerías (Dralca, Cobeca, Farmatodo, etc.) son usualmente Contribuyentes Especiales.

---

## Retención ISLR (`doc_type: RETENTION_ISLR`)

### Base Legal
- **Decreto 1808** — Reglamento de la Ley de ISLR en materia de Retenciones
- **Tabla 26** — Tabla de alícuotas por código de concepto

### Mecánica de Cálculo

```
Base Imponible ISLR = Monto bruto del pago (antes de IVA)
Alícuota ISLR       = Depende del Código de Concepto (Tabla 26 Decreto 1808)
Monto Retenido ISLR = Base Imponible × Alícuota
```

**Ejemplo con Código 1 (servicios profesionales, 1%):**
```
Base Imponible      = $50.00 USD (precio sin IVA)
Alícuota            = 1.00% (Código 01, Tabla 26)
Monto Retenido ISLR = $50.00 × 1.00% = $0.50 USD
```

### Códigos de Concepto más comunes (Tabla 26)

| Código | Descripción | Alícuota |
|---|---|---|
| `01` | Honorarios profesionales | 1% – 3% |
| `02` | Arrendamiento de bienes inmuebles | 3% |
| `04` | Comisiones mercantiles | 2% |
| `44` | Ventas de bienes muebles | 0% (exentas en muchos casos) |
| `48` | Servicios | 1% – 2% |

> Consultar el Decreto 1808 completo para la tabla actualizada.

### Payload FideX

```json
{
  "document_type": "GS1_RETENTION_JSON",
  "document_info": {
    "doc_type": "RETENTION_ISLR",
    "document_number": "RET-ISLR-2026-00012",
    "retention_period": "2026-03"
  },
  "retention_lines": [
    {
      "tax_type": "ISLR",
      "retention_code": "01",
      "taxable_base_usd": 50.00,
      "islr_rate": 1.00,
      "amount_retained_usd": 0.50,
      "amount_retained_ves": 22.50
    }
  ]
}
```

---

## Período de Retención (`retention_period`)

El campo `retention_period` (formato `AAAA-MM`) es **obligatorio** en FideX para:
- Agrupar todas las retenciones del mismo mes en un solo comprobante (si se consolidan).
- Prevenir la mezcla de retenciones de diferentes períodos en un mismo `GS1_RETENTION_JSON`.
- Facilitar la declaración mensual en el portal ISENIAT.

---

## Comprobante como Crédito Fiscal

Una vez emitido el Comprobante de Retención IVA, el proveedor (laboratorio) debe:

1. Registrarlo en su **Libro de Compras** mensual.
2. Deducirlo de su **IVA a pagar** en la Forma 30 del período correspondiente.
3. Archivarlo para auditorías del SENIAT (plazo mínimo: 5 años).

El número de comprobante (`document_number`) es el identificador único que el proveedor usa para este registro.

---

## Plazos de Enteramiento

| Tipo de retención | Plazo para enterar al SENIAT |
|---|---|
| Retención IVA | Días 3 y 10 del mes siguiente según el RIF del agente |
| Retención ISLR | Día 3 del mes siguiente al período de pago |

El incumplimiento genera multas equivalentes al 100% del tributo no enterado, más intereses moratorios.

---

## Mapeo en ERPs

| ERP | Retención IVA | Retención ISLR |
|---|---|---|
| **Odoo** | Diario de retenciones IVA (`account.move`) + `l10n_ve` | Diario ISLR (`account.move`) |
| **Profit** | Tabla `comp_ret_iva` via `ProfitSDK.dll` | Tabla `comp_ret_islr` |
| **Saint** | `POST /api/v1/retenciones` con `TipoRetencion: IVA` | `POST /api/v1/retenciones` con `TipoRetencion: ISLR` |
| **Galac** | Módulo principal; XML import o `POST /api/v1/retenciones` | Mismo módulo; campos adicionales `CodigoConcepto` / `AlicuotaISLR` |
| **SAP B1** | Opción A: código OWHT `RET-IVA-75` / Opción B: UDO `U_RETENCION` | Códigos OWHT por concepto ISLR o UDO |

---

## Ver también

- [`05-fiscal-venezolano.md`](./05-fiscal-venezolano.md) — IVA, IGTF y marco legal
- [`09-integracion-erp/00-indice.md`](./09-integracion-erp/00-indice.md) — Campos fiscales en todos los ERPs
- Ejemplos: [`examples/retention/01-retention-iva.json`](../../examples/retention/01-retention-iva.json) y [`02-retention-islr.json`](../../examples/retention/02-retention-islr.json)
