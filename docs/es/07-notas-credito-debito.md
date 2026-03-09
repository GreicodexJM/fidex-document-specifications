# Notas de Crédito y Débito en FideX

> 🇬🇧 [English version](../07-credit-debit-notes.md)

Las notas de crédito y débito son documentos fiscales post-factura que corrigen el monto o contenido de una factura previamente emitida. En FideX ambas reutilizan el tipo `GS1_INVOICE_JSON`, diferenciadas por `doc_type`.

---

## Nota de Crédito (`doc_type: CREDIT_NOTE`)

**Propósito:** Reducir el monto de una factura previamente emitida.

**Casos de uso más comunes:**
- Devolución parcial o total de mercancía
- Ajuste de precio pactado posterior a la facturación
- Descuento no aplicado en la factura original
- Error de cantidad facturada (se cobró de más)

**Regla fiscal:** La Nota de Crédito **siempre debe referenciar** la factura original mediante `related_documents`. El SENIAT no acepta NC sin respaldo de factura.

```json
{
  "document_info": {
    "doc_type": "CREDIT_NOTE",
    "document_number": "NC-2026-00021",
    "status": "ISSUED"
  },
  "related_documents": [
    {
      "document_type": "GS1_INVOICE_JSON",
      "doc_type": "INVOICE",
      "document_number": "INV-2026-00145",
      "relation_type": "CORRECTS"
    }
  ]
}
```

---

## Nota de Débito (`doc_type: DEBIT_NOTE`)

**Propósito:** Incrementar el monto de una factura previamente emitida.

**Casos de uso más comunes:**
- Cargo omitido en la factura original (flete, seguro, embalaje)
- Ajuste de precio al alza posterior a la facturación
- Intereses de mora por pago tardío
- Unidades adicionales no incluidas en la factura original

**Regla fiscal:** Al igual que la NC, la ND debe referenciar la factura afectada con `relation_type: CORRECTS`.

---

## Matemática Fiscal

### Nota de Crédito
```
Monto NC = Precio Unitario × Cantidad devuelta
IVA NC   = Monto NC × Alícuota IVA (si el ítem no es exento)
Total NC = Monto NC + IVA NC

La factura original se reduce en el Total NC.
```

### Nota de Débito
```
Monto ND = Cargo adicional (precio × cantidad adicional ó cargo único)
IVA ND   = Monto ND × Alícuota IVA (si aplica)
Total ND = Monto ND + IVA ND

La factura original se incrementa en el Total ND.
```

---

## Mapeo en Schemas FideX

El esquema `gs1-invoice.schema.json` (v1.1) incluye una restricción `if/then` de JSON Schema 2020-12 que hace **obligatorio** el campo `related_documents` cuando `doc_type` es `CREDIT_NOTE` o `DEBIT_NOTE`:

```json
{
  "if": {
    "properties": {
      "document_info": {
        "properties": {
          "doc_type": { "enum": ["CREDIT_NOTE", "DEBIT_NOTE"] }
        }
      }
    }
  },
  "then": {
    "required": ["related_documents"],
    "properties": {
      "related_documents": { "minItems": 1 }
    }
  }
}
```

Esta validación se aplica en el **Nivel 2** (validación de esquema con AJV), antes de que el adaptador ERP procese el documento.

---

## Mapeo ERP por Tipo de Documento

| `doc_type` FideX | Odoo | Profit | Saint | Galac | SAP B1 |
|---|---|---|---|---|---|
| `CREDIT_NOTE` | `out_refund` (`account.move`) | `N` en `factura.tipo_doc` | `POST /api/v1/notas/credito` | `POST /api/v1/notas/credito` o XML | `POST /b1s/v1/CreditNotes` |
| `DEBIT_NOTE` | `out_invoice` (diario ND) | `D` en `factura.tipo_doc` | `POST /api/v1/notas/debito` | `POST /api/v1/notas/debito` o XML | `POST /b1s/v1/Invoices` + UDF `U_DOC_TYPE=DN` |

---

## Número de Control SENIAT en NC/ND

Tanto la Nota de Crédito como la Nota de Débito requieren su propio Número de Control SENIAT (distinto al de la factura original). El campo FideX es `fiscal_control.control_number`.

---

## Ver también

- [`05-fiscal-venezolano.md`](./05-fiscal-venezolano.md) — IVA, IGTF y base legal
- [`08-retenciones-fiscales.md`](./08-retenciones-fiscales.md) — Retenciones sobre NC/ND
- Ejemplos: [`examples/invoice/03-credit-note.json`](../../examples/invoice/03-credit-note.json) y [`04-debit-note.json`](../../examples/invoice/04-debit-note.json)
