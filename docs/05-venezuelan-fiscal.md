# Venezuelan Fiscal Requirements

## Overview

Venezuela has a complex, layered tax system administered by **SENIAT** (Servicio Nacional Integrado de Administración Aduanera y Tributaria). FideX handles this through the **Extensible Object Philosophy**: Venezuelan-specific fiscal data lives in isolated nested objects that don't break the core GS1/AS5 format.

---

## Tax Types

| Tax | Name | Rate | Notes |
|---|---|---|---|
| `IVA` | Impuesto al Valor Agregado | 16% (standard) / 0% (exempt) | VAT equivalent; many medicines are exempt |
| `IGTF` | Impuesto a las Grandes Transacciones Financieras | 3% | Applied to foreign currency transactions (USD, EUR) |
| `ISLR` | Impuesto Sobre la Renta | Variable | Income tax withholding (see v1.1 retention docs) |

### IVA Exemptions for Medicines

Many essential medicines in Venezuela are **IVA-exempt** under Decreto 3.111. When a product has `is_exempt: true` in the catalog:

```json
"tax_profile": {
  "is_exempt": true,
  "tax_type": "IVA",
  "percentage": 0.00
}
```

This exemption must propagate from the Catalog → Order → Invoice to avoid erroneously applying 16% IVA to regulated medications.

---

## Multi-Currency Architecture

Venezuela operates in a **dual-currency environment**: USD as the commercial base, VES (Bolívares) as the legal tender for fiscal reporting.

### The Decoupling Principle

All commercial calculations use **USD as the base currency**. VES amounts are derived by applying the official BCV (Banco Central de Venezuela) exchange rate:

```
amount_ves = amount_usd × exchange_rate_applied (BCV rate at time of transaction)
```

This prevents the decimal rounding mismatches that plague Venezuelan ERP integrations when the rate fluctuates daily.

### The `fiscal_totals_ves` Block

Every invoice summary includes a `fiscal_totals_ves` object with all amounts converted to Bolívares:

```json
"summary": {
  "total_net_usd": 112.50,
  "total_taxes_usd": 18.00,
  "total_gross_usd": 130.50,
  "fiscal_totals_ves": {
    "exchange_rate_applied": 45.00,
    "base_imponible_ves": 5062.50,
    "total_iva_ves": 810.00,
    "total_igtf_ves": 0.00,
    "total_gross_ves": 5872.50
  }
}
```

The FideX Government Observer Node extracts **only** this block for SENIAT reporting. The line-item details (prices, margins, product names) are never transmitted to the government.

---

## The `fiscal_control` Object

For documents processed through the Unidigital (SENIAT) digital receipt system, an optional `fiscal_control` block captures:

```json
"fiscal_control": {
  "fiscal_series_id": "123e4567-e89b-12d3-a456-426614174000",
  "amount_in_letters_ves": "Ciento sesenta y cuatro con 00/100",
  "bcv_message": "Tasa BCV: 45.00",
  "printable_notes": [
    "Mercancía revisada al momento de la entrega.",
    "Sin derecho a devolución sin factura original."
  ]
}
```

| Field | Purpose |
|---|---|
| `fiscal_series_id` | Maps to Unidigital's `SerieStrongId` for the talonario digital |
| `amount_in_letters_ves` | Required by SENIAT for printed invoice PDFs |
| `bcv_message` | BCV rate disclosure printed on fiscal receipt |
| `printable_notes` | Up to 4 custom notes printed on the fiscal receipt (notas 1-4) |

This block is **optional** — omitting it produces a valid international B2B document. Including it activates the SENIAT fiscal printing workflow.

---

## Venezuelan Payment Methods

The `applied_payments` array captures specific Venezuelan payment methods with the fields required for **Zero-Touch Bank Reconciliation**:

### PagoMóvil

```json
{
  "method": "PAGO_MOVIL",
  "amounts": {
    "paid_currency": "VES",
    "amount_paid": 4500.00,
    "exchange_rate_usd": 45.00,
    "amount_usd_equivalent": 100.00
  },
  "reference_data": {
    "confirmation_number": "1928374652",
    "bank_code": "0102",
    "payer_id": "V-12345678",
    "payer_phone": "04141234567"
  }
}
```

The `bank_code` + `payer_phone` + `confirmation_number` combination allows the receiving ERP to automatically match the PagoMóvil notification from the bank against the invoice in Odoo or Profit — eliminating manual reconciliation.

### Common Venezuelan Bank Codes

| Code | Bank |
|---|---|
| `0102` | Banco de Venezuela |
| `0104` | Venezolano de Crédito |
| `0105` | Banco Mercantil |
| `0108` | BBVA Provincial |
| `0134` | Banesco |
| `0175` | Banco Bicentenario |

### Other Supported Methods

| `method` | Required fields |
|---|---|
| `ZELLE` | `confirmation_number`, `sender_email` |
| `TRANSFERENCIA` | `bank_code`, `account_reference`, `confirmation_number` |
| `TARJETA_DEBITO` | `bank_code`, `pos_terminal_id` |
| `TARJETA_CREDITO` | `bank_code`, `pos_terminal_id` |
| `EFECTIVO_USD` | `amount_paid` |

---

## Special Taxpayers (Agentes de Retención IVA)

Certain large distributors in Venezuela are designated as **Agentes de Retención IVA** (Special Taxpayers) by SENIAT. They are required to withhold 75% of the IVA from their supplier invoices and remit it directly to SENIAT.

This is captured in the Customer Master:

```json
"financial_profile": {
  "tax_profile": {
    "is_retention_agent_iva": true,
    "retention_percentage": 75.00
  }
}
```

When a droguería with `is_retention_agent_iva: true` receives an invoice, their ERP automatically:
1. Calculates 75% of the IVA amount
2. Withholds it from the payment to the laboratory
3. Issues a `RETENTION_IVA` document (v1.1) back to the laboratory

This workflow is fully automated in the FideX schema design — the flag in the Customer Master triggers the correct behavior in both ERPs.
