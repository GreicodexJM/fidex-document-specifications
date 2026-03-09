# Fiscalidad Venezolana en FideX

> 🇬🇧 [English version](../05-venezuelan-fiscal.md)

Este documento explica los impuestos, tasas, organismos y obligaciones fiscales venezolanas que impactan directamente el diseño de los payloads FideX.

---

## 1. Impuesto al Valor Agregado (IVA)

El IVA venezolano es administrado por el **SENIAT** (Servicio Nacional Integrado de Administración Aduanera y Tributaria).

| Concepto | Detalle |
|---|---|
| **Alícuota general** | 16% sobre la base imponible |
| **Alícuota reducida** | 8% para ciertos bienes (canasta básica, máquinas de cirugía, etc.) |
| **Alícuota adicional** | 15% para bienes de lujo (suma = 31%) |
| **Exención** | Medicamentos de la Gaceta Oficial, alimentos de la canasta básica |
| **Período fiscal** | Mensual; declaración vence el día 15 del mes siguiente |
| **Formulario** | Forma 30 en el portal ISENIAT |

**En el payload FideX:**
```json
"taxes": [
  { "type": "IVA", "rate": 16.00, "amount_usd": 8.00, "amount_ves": 360.00 }
]
```

---

## 2. Impuesto a las Grandes Transacciones Financieras (IGTF)

Aplicable a pagos en moneda extranjera (USD, EUR, USDT, criptomonedas) efectuados en Venezuela.

| Concepto | Detalle |
|---|---|
| **Alícuota** | 3% sobre el monto bruto de la transacción |
| **Base legal** | Decreto-Ley N° 9.410 y reformas posteriores |
| **Responsable** | El pagador (comprador) que paga en divisas |
| **Período** | Declaración diaria o semanal según el contribuyente |
| **Aplicación** | Solo cuando el pago se realiza en moneda extranjera; no aplica si se paga en Bs |

> ⚠️ **El IGTF es un impuesto separado del IVA.** Nunca consolidar en la misma línea de impuesto. Usar siempre `"type": "IGTF"` como código distinto en el payload.

**En el payload FideX:**
```json
"taxes": [
  { "type": "IVA",  "rate": 16.00, "amount_usd": 8.00,  "amount_ves": 360.00 },
  { "type": "IGTF", "rate": 3.00,  "amount_usd": 1.62,  "amount_ves": 72.90 }
]
```

---

## 3. Tasa de Cambio BCV (Bs / USD)

El **Banco Central de Venezuela (BCV)** publica la tasa oficial de cambio Bolívar/USD diariamente.

| Concepto | Detalle |
|---|---|
| **Fuente oficial** | https://www.bcv.org.ve — sección "Estadísticas → Tasas de Cambio" |
| **Frecuencia** | Publicada cada día hábil bancario (lunes a viernes) |
| **Obligatoriedad** | La LOGITP exige usar la tasa BCV del día de la transacción para libros en Bs |
| **Aplicación en FideX** | Campo `payment_terms.exchange_rate_pegged` en todos los documentos transaccionales |

**Cálculo de montos en Bs:**
```
Base Imponible VES = Base Imponible USD × Tasa BCV
IVA VES            = IVA USD × Tasa BCV
Total VES          = Total USD × Tasa BCV
```

**En el payload FideX:**
```json
"payment_terms": {
  "exchange_rate_pegged": 45.00,
  "exchange_rate_source": "BCV"
},
"summary": {
  "fiscal_totals_ves": {
    "exchange_rate_applied": 45.00,
    "base_imponible_ves": 2250.00,
    "total_iva_ves":  360.00,
    "total_gross_ves": 2610.00
  }
}
```

---

## 4. RIF — Registro de Información Fiscal

El **RIF** es el número de identificación fiscal asignado por el SENIAT a personas naturales y jurídicas.

| Prefijo | Tipo de contribuyente |
|---|---|
| `J-` | Persona jurídica (empresa) |
| `V-` | Persona natural venezolana |
| `E-` | Persona natural extranjera |
| `G-` | Organismo del gobierno |
| `P-` | Pasaporte (turistas / no residentes) |

**Formato:** `{Prefijo}-########-#` (8 dígitos + 1 dígito verificador)

**Validación:** El dígito verificador se calcula mediante el algoritmo de módulo 11 del SENIAT.

**En el payload FideX:** el campo `rif` aparece en todos los objetos de partes (`parties.*`) y en `customer_details.tax_id`.

---

## 5. Número de Control SENIAT

El **Número de Control** es un correlativo secuencial asignado por el SENIAT a cada documento fiscal (factura, nota de crédito, nota de débito) emitido por una empresa.

| Concepto | Detalle |
|---|---|
| **Longitud** | 8 dígitos (rellenados con ceros a la izquierda) |
| **Asignación** | Secuencial por empresa; no se puede saltar ni reutilizar |
| **Obligatorio en** | Facturas, notas de crédito, notas de débito |
| **Campo FideX** | `fiscal_control.control_number` |
| **Campo en ERP** | Profit: `nro_control` / Saint: `NroControl` / Odoo: `l10n_ve_control_number` |

---

## 6. Serie Fiscal

Acompaña al Número de Control para identificar la máquina fiscal o el talonario de facturas.

| Campo FideX | Ejemplo | Notas |
|---|---|---|
| `fiscal_control.fiscal_series_letter` | `"A"` | Letra asignada por el SENIAT al talonario |
| `fiscal_control.machine_serial` | `"Z1A2B3C4"` | Serial de la impresora fiscal (si aplica) |

---

## 7. ISLR — Impuesto Sobre la Renta

El ISLR aplica sobre los ingresos de personas y empresas. En el contexto B2B farmacéutico, el ISLR se manifiesta principalmente como **retención en la fuente** cuando un Contribuyente Especial paga a un proveedor.

Ver [`08-retenciones-fiscales.md`](./08-retenciones-fiscales.md) para el mecanismo completo de retención ISLR.

---

## 8. SICM — Sistema Integral de Control de Medicamentos

El **SICM** (MPPS) es el registro de permisos sanitarios para farmacias, droguerías y distribuidores farmacéuticos.

| Campo FideX | Notas |
|---|---|
| `customer_details.health_permit.sicm` | Número de permiso SICM |
| `customer_details.health_permit.permit_status` | `VALID` / `EXPIRED` / `SUSPENDED` |
| `customer_details.health_permit.expiration_date` | Fecha de vencimiento del permiso |

**Regla de negocio crítica:** El Hub FideX (Nivel 3) debe **rechazar órdenes de compra** si el permiso SICM del comprador está vencido o suspendido. Esta validación es obligatoria para el cumplimiento regulatorio farmacéutico venezolano.
