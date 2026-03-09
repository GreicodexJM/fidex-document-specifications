# 12 — Referencia de Mapas de Transformación JSONata

> 🇬🇧 [English version](../12-jsonata-maps.md)

---

## 12.1 ¿Para qué sirven los mapas JSONata?

El Hub FideX recibe documentos canónicos en formato GS1/FideX de los sistemas ERP de los emisores. Cada receptor (Odoo, Profit, Saint, Galac, SAP B1) necesita el mismo documento en **su propio formato de entrada**. Los **mapas JSONata** son las transformaciones que convierten el formato canónico al formato específico de cada adaptador ERP.

```
ERP Emisor
    │
    │  (Adaptador ERP → formato FideX)
    ▼
Hub FideX  ──► aplica mapa JSONata ──► Adaptador ERP Receptor
    │
    │  GS1_INVOICE_JSON canónico
    │
    └──► maps/invoice-to-odoo.jsonata    ──► /api/account.move/create
    └──► maps/invoice-to-profit.jsonata  ──► INSERT INTO factura
    └──► maps/invoice-to-saint.jsonata   ──► POST /api/v1/VeFactura
```

---

## 12.2 Convención de Directorio `maps/`

```
maps/
├── invoice-to-odoo.jsonata
├── invoice-to-profit.jsonata
├── invoice-to-saint.jsonata
├── invoice-to-galac.jsonata
├── invoice-to-sap-b1.jsonata
├── order-to-odoo.jsonata
├── order-to-profit.jsonata
│   ...
├── retention-to-odoo.jsonata
│   ...
└── _lib/
    ├── ves-formatting.jsonata    (funciones compartidas de formateo VES)
    └── gln-lookup.jsonata        (resolución GLN → código ERP)
```

**Regla de nomenclatura**: `{document_type_slug}-to-{erp_slug}.jsonata`

---

## 12.3 Encabezado Estándar de Archivo de Mapa

Todo archivo de mapa JSONata debe comenzar con el siguiente encabezado como comentario:

```jsonata
/**
 * @map invoice-to-odoo
 * @version 1.0.0
 * @source GS1_INVOICE_JSON (FideX v1.5+)
 * @target Odoo 17/18 account.move (JSON-RPC create)
 * @author Greicodex Hub Team
 * @updated 2026-03-09
 *
 * Transforma una factura FideX canónica al formato de creación
 * de account.move en Odoo 17/18 via JSON-RPC /web/dataset/call_kw.
 */
```

---

## 12.4 Ejemplo Completo: Odoo → FideX (Factura)

Este mapa convierte una `account.move` de Odoo al formato `GS1_INVOICE_JSON` canónico de FideX:

```jsonata
/**
 * @map odoo-invoice-to-fidex
 * @version 1.0.0
 * @source Odoo 17/18 account.move (write_date, move_type, l10n_ve_*)
 * @target GS1_INVOICE_JSON (FideX v1.5+)
 */
{
  "kontext_routing": {
    "spec_version": "1.0",
    "message_id": "MSG-" & $string($millis()),
    "timestamp": $now(),
    "tenant_id":    $env.tenant_id,
    "receiver_id":  $env.receiver_id,
    "document_type": "GS1_INVOICE_JSON",
    "correlation_id": $env.correlation_prefix & name
  },
  "payload": {
    "document_info": {
      "version": "1.2",
      "doc_type": move_type = "out_invoice" ? "INVOICE"
                : move_type = "out_refund"  ? "CREDIT_NOTE"
                : "DEBIT_NOTE",
      "document_number": name,
      "status": state = "posted" ? "APPROVED" : "PENDING",
      "currency_base": currency_id[1],
      "dates": {
        "issued_at":  invoice_date & "T00:00:00Z",
        "due_at":     invoice_date_due & "T00:00:00Z"
      }
    },
    "parties": {
      "seller": {
        "name":  company_id[1],
        "rif":   $env.tenant_rif,
        "gln":   $env.tenant_gln
      },
      "buyer": {
        "name":  partner_id[1],
        "rif":   partner_id.l10n_ve_rif,
        "gln":   partner_id.x_gln
      }
    },
    "lines": invoice_line_ids.{
      "line_number":    $string($index + 1),
      "gtin":           product_id.barcode,
      "description":    name,
      "quantity":       quantity,
      "unit":           product_uom_id[1],
      "unit_price_usd": price_unit,
      "tax_lines": tax_ids.{
        "tax_type":  name = "IVA 16%" ? "IVA" : "IGTF",
        "rate":      amount / 100,
        "amount_usd": $round(price_unit * quantity * amount / 100, 2)
      }
    },
    "summary": {
      "subtotal_usd":     amount_untaxed,
      "total_tax_usd":    amount_tax,
      "total_usd":        amount_total
    }
  }
}
```

---

## 12.5 Contexto de Ejecución `$env`

Los mapas JSONata acceden a valores de configuración del Hub mediante el objeto `$env`, que el Hub inyecta en tiempo de ejecución:

| Campo `$env` | Descripción | Ejemplo |
|---|---|---|
| `$env.tenant_id` | Identificador del tenant en FideX | `"leti-ve"` |
| `$env.tenant_gln` | GLN del emisor | `"7590000000001"` |
| `$env.tenant_rif` | RIF del emisor (formato SENIAT) | `"J-00000000-1"` |
| `$env.receiver_id` | ID del receptor en FideX | `"drogueria-xyz"` |
| `$env.correlation_prefix` | Prefijo para `correlation_id` | `"LETI-2026-"` |
| `$env.bcv_rate` | Tasa BCV vigente (VES/USD) | `45.12` |
| `$env.map_version` | Versión del mapa activo | `"1.0.0"` |

---

## 12.6 Manejo de Errores

Si el mapa JSONata produce un documento que no pasa la validación de esquema (Tier 2), el Hub:

1. **No reenvía** el documento al receptor
2. Registra el error con `message_id`, `map_name`, y el error de validación
3. Envía un **J-MDN de error** al emisor con `status: "MAPPING_FAILED"`
4. Notifica al equipo de operaciones del Hub para corrección del mapa

**Errores comunes en mapas:**

| Error | Causa típica | Solución |
|---|---|---|
| `required field missing` | Campo obligatorio no mapeado | Agregar el campo al mapa |
| `pattern mismatch` | RIF/GLN en formato incorrecto del ERP origen | Agregar transformación de formato |
| `unevaluatedProperties` | Campo extra no definido en schema | Remover del objeto de salida |
| `minLength violation` | Campo mapeado a string vacío | Agregar guard `$string() != "" ? ... : ...` |

---

## 12.7 Convenciones de Testing de Mapas

Cada mapa debe tener su fixture de prueba en el directorio de tests del Hub:

```
maps/tests/
├── invoice-to-odoo/
│   ├── input.json          (GS1_INVOICE_JSON de ejemplo)
│   ├── expected-output.json (resultado esperado para Odoo)
│   └── test.jsonata        (expresión de aserción)
```

**Ejecutar tests de mapas:**

```bash
# En el repositorio greicodex/fidex-hub:
make test-maps
make test-maps MAP=invoice-to-odoo
```

---

## 12.8 Diagrama de Enrutamiento Hub → ERP

```
                    ┌─────────────────────────────────┐
                    │          FideX Hub               │
                    │                                  │
Mensaje entrante ──►│  1. Valida esquema (Tier 1+2)    │
                    │  2. Descifra JWE                 │
                    │  3. Determina receptor (GLN/RIF) │
                    │  4. Selecciona mapa JSONata       │
                    │  5. Transforma payload           │
                    │  6. Reencripta con pubkey receptor│
                    │  7. Reenvía al adaptador ERP     │
                    └─────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
         Adaptador        Adaptador       Adaptador
           Odoo            Profit           Saint
        JSON-RPC          SQL Server      REST API
       /api/account     INSERT factura   /api/v1/VeFactura
```

---

*Ver también: [`docs/es/09-integracion-erp/00-indice.md`](09-integracion-erp/00-indice.md) (matrices de integración ERP), [`docs/es/10-nodo-observador-gubernamental.md`](10-nodo-observador-gubernamental.md) (mapa JSONata del Observador)*
