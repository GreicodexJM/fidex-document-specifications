# El Sobre de Enrutamiento — `kontext_routing`

> 🇬🇧 [English version](../02-routing-envelope.md)

---

## Propósito

El objeto `kontext_routing` es la **capa de metadatos de transporte** de cada documento FideX. Siempre está presente en el nivel superior y es la **única** parte del mensaje que el Hub AS5 lee para tomar decisiones de enrutamiento.

Esto implementa el principio de **Separación de Responsabilidades**: el hub sabe *dónde* entregar el mensaje sin saber nunca *qué* hay dentro de él.

---

## Referencia de Schema

Ver [`schemas/_common/kontext-routing.schema.json`](../../schemas/_common/kontext-routing.schema.json)

```json
{
  "kontext_routing": {
    "tenant_id": "tenant-leti-01",
    "receiver_id": "partner-drogueria-x",
    "document_type": "GS1_ORDER_JSON",
    "correlation_id": "ORD-2026-9921"
  }
}
```

---

## Campos

### `tenant_id`
**Tipo**: `string` | **Requerido**: Sí

El identificador de tenant del emisor registrado en el Hub FideX AS5. Se asigna durante el proceso de incorporación (onboarding) de 4 fases del socio comercial y mapea al endpoint de clave pública JWKS del emisor.

**Formato**: `tenant-{slug-empresa}-{secuencia}`
**Ejemplo**: `tenant-leti-01`, `tenant-belo-01`

---

### `receiver_id`
**Tipo**: `string` | **Requerido**: Sí

El identificador de socio del receptor en el Directorio de Socios Comerciales (TPD). El hub lo usa para buscar el `message_endpoint` del receptor y sus claves de cifrado (desde su URI JWKS).

**Formato**: `partner-{slug-empresa}`
**Ejemplo**: `partner-drogueria-x`, `partner-belo-distribuciones`

---

### `document_type`
**Tipo**: `enum` | **Requerido**: Sí

Tipo de documento legible por máquina. El hub lo usa para aplicar reglas de enrutamiento, mapas de traducción JSONata y ganchos de cumplimiento (p.ej., activar el observador SENIAT para facturas).

| Valor | Activa |
|---|---|
| `GS1_CUSTOMER_MASTER_JSON` | Adaptador de upsert `res.partner` en ERP |
| `GS1_CATALOG_JSON` | Motor de sincronización de catálogo + validación Merkle |
| `GS1_ORDER_JSON` | Máquina de estados del ciclo de vida de órdenes |
| `GS1_DESPATCH_ADVICE_JSON` | Evento logístico + recepción en almacén |
| `GS1_INVOICE_JSON` | Cumplimiento fiscal + observador SENIAT |
| `GS1_RETENTION_JSON` *(v1.1)* | Procesamiento del agente de retención |

---

### `correlation_id`
**Tipo**: `string` | **Requerido**: Sí

La clave de correlación de negocio. Todos los documentos que pertenecen a la misma transacción comparten el mismo `correlation_id`. Esto permite al hub vincular el triángulo Orden → ASN → Factura y realizar la validación de Three-Way Match.

**Convención**: Usa el número de la orden/transacción original como ancla:
```
correlation_id = "ORD-2026-9921"   (para la Orden)
correlation_id = "ORD-2026-9921"   (para el ASN que referencia esa orden)
correlation_id = "ORD-2026-9921"   (para la Factura que referencia esa orden)
```

Para datos maestros (cliente, catálogo), usa el ID propio del documento:
```
correlation_id = "CUST-J222222223"
correlation_id = "CAT-2026-03-VE"
```

---

## Cómo el Hub Procesa el Sobre de Enrutamiento

```
Mensaje entrante (cifrado JWE)
    │
    ▼
Hub descifra el sobre JWE externo
    │
    ▼
Hub lee kontext_routing (capa en texto plano, antes del descifrado del payload)
    │
    ├─ Busca receiver_id en el Directorio de Socios Comerciales
    ├─ Selecciona el mapa de traducción JSONata para document_type
    ├─ Aplica ganchos de cumplimiento (observador SENIAT para GS1_INVOICE_JSON)
    └─ Reenvía el payload cifrado al message_endpoint del receptor
         │
         ▼
    Receptor descifra con su clave privada
    Receptor valida el payload contra los schemas de este repositorio
    Receptor devuelve recibo J-MDN
```

Nota: El hub **nunca descifra el payload**. Solo lee `kontext_routing`. El contenido comercial (líneas de detalle, precios, márgenes) solo es visible para el emisor y el receptor.
