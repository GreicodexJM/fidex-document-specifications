# Negative Test Examples (`examples/_invalid/`)

These examples are **intentionally invalid**. Each one is designed to trigger a specific schema validation rule. They are used by `make validate-negative` to confirm that the schemas correctly **reject** malformed payloads.

## Test Matrix

| File | Schema Tested | Rule Violated | Expected Error |
|---|---|---|---|
| `invoice/01-credit-note-no-related.json` | `gs1-invoice.schema.json` | `if/then` enforcement | CREDIT_NOTE without `related_documents` → must fail |
| `invoice/02-empty-document-number.json` | `gs1-invoice.schema.json` | `minLength: 1` | `document_number: ""` violates minimum length → must fail |
| `order/01-order-confirmed-no-quote.json` | `gs1-order.schema.json` | `if/then` enforcement | ORDER_CONFIRMED without `related_order`/`related_quote` → must fail |
| `retention/01-bad-period-format.json` | `gs1-retention.schema.json` | `retention_period` pattern | `"2026-3"` does not match `^[0-9]{4}-(0[1-9]|1[0-2])$` → must fail |
| `customer-master/01-missing-tax-id.json` | `gs1-customer-master.schema.json` | `required` field | `tax_id` removed from `customer_details` → must fail |
| `catalog/01-invalid-sync-type.json` | `gs1-catalog.schema.json` | `enum` violation | `catalog_type: "BOGUS_SYNC"` not in allowed enum values → must fail |
| `despatch-advice/01-bad-sscc.json` | `gs1-despatch-advice.schema.json` | `pattern` violation | SSCC `"1234567890"` (10 digits) does not match `^[0-9]{18}$` → must fail |
| `jmdn/01-fiscal-no-merkle.json` | `gs1-jmdn.schema.json` | `if/then/else` enforcement | `FISCAL_CLEARED` without `merkle_proof` violates else-branch → must fail |

## Running

```bash
make validate-negative
```

Expected output (8 fixtures, all domains covered):
```
→ Running negative validation tests...
✅  examples/_invalid/invoice/01-credit-note-no-related.json correctly rejected by schema
✅  examples/_invalid/invoice/02-empty-document-number.json correctly rejected by schema
✅  examples/_invalid/order/01-order-confirmed-no-quote.json correctly rejected by schema
✅  examples/_invalid/retention/01-bad-period-format.json correctly rejected by schema
✅  examples/_invalid/customer-master/01-missing-tax-id.json correctly rejected by schema
✅  examples/_invalid/catalog/01-invalid-sync-type.json correctly rejected by schema
✅  examples/_invalid/despatch-advice/01-bad-sscc.json correctly rejected by schema
✅  examples/_invalid/jmdn/01-fiscal-no-merkle.json correctly rejected by schema

✅  All negative examples correctly rejected by schemas.
```

## Adding New Negative Tests

1. Create a file under `examples/_invalid/{domain}/`
2. The `{domain}` must match an existing schema directory:
   `invoice`, `order`, `retention`, `catalog`, `customer-master`, `despatch-advice`, `jmdn`
3. Document the violated rule in this README's test matrix above
4. Run `make validate-negative` to confirm the example fails as expected
5. Run `make validate-all` to confirm all positive examples still pass

## Domain Coverage

| Domain | Positive Examples | Negative Fixtures | Coverage |
|---|---|---|---|
| `customer-master` | 1 | 1 | required field |
| `catalog` | 2 | 1 | enum violation |
| `order` | 3 | 1 | if/then enforcement |
| `despatch-advice` | 1 | 1 | pattern (SSCC) |
| `invoice` | 4 | 2 | if/then + minLength |
| `retention` | 2 | 1 | pattern (period) |
| `jmdn` | 2 | 1 | if/then/else |
