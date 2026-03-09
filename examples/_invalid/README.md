# Negative Test Examples (`examples/_invalid/`)

These examples are **intentionally invalid**. Each one is designed to trigger a specific schema validation rule. They are used by `make validate-negative` to confirm that the schemas correctly **reject** malformed payloads.

## Test Matrix

| File | Schema Tested | Rule Violated | Expected Error |
|---|---|---|---|
| `invoice/01-credit-note-no-related.json` | `gs1-invoice.schema.json` | `if/then` enforcement | CREDIT_NOTE without `related_documents` → must fail |
| `order/01-order-confirmed-no-quote.json` | `gs1-order.schema.json` | `if/then` enforcement | ORDER_CONFIRMED without `related_order`/`related_quote` → must fail |
| `retention/01-bad-period-format.json` | `gs1-retention.schema.json` | `retention_period` pattern | `"2026-3"` does not match `^[0-9]{4}-(0[1-9]|1[0-2])$` → must fail |

## Running

```bash
make validate-negative
```

Expected output:
```
→ Running negative validation tests...
✅  examples/_invalid/invoice/01-credit-note-no-related.json correctly rejected by schema
✅  examples/_invalid/order/01-order-confirmed-no-quote.json correctly rejected by schema
✅  examples/_invalid/retention/01-bad-period-format.json correctly rejected by schema

✅  All negative examples correctly rejected by schemas.
```

## Adding New Negative Tests

1. Create a file under `examples/_invalid/{domain}/`
2. The `{domain}` must match an existing schema directory (`invoice`, `order`, `retention`, `catalog`, `customer-master`, `despatch-advice`)
3. Document the violated rule in this README's test matrix
4. Run `make validate-negative` to confirm the example fails as expected
