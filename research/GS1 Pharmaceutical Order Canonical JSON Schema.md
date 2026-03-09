Here is the complete, merged **GS1\_ORDER\_JSON** canonical example. It combines the standardized routing envelope 1, pharmaceutical traceability (GS1 & SICM), multi-currency tax reporting in Bolívares, and the local Venezuelan payment capture methods (PagoMovil and Debit) into one cohesive, enterprise-grade payload.  
{  
  "kontext\_routing": {  
    "tenant\_id": "tenant-leti-01",  
    "receiver\_id": "partner-drogueria-x",  
    "document\_type": "GS1\_ORDER\_JSON",  
    "correlation\_id": "ORD-2026-9921"  
  },  
  "payload": {  
    "document\_info": {  
      "version": "1.1",  
      "doc\_type": "ORDEN",   
      "document\_number": "ORD-2026-9921",  
      "status": "CONFIRMADA",  
      "currency\_base": "USD",  
      "dates": {  
        "created\_at": "2026-02-27T10:00:00Z",  
        "delivery\_requested": "2026-02-28T14:00:00Z",  
        "expiration": "2026-03-05T23:59:59Z"  
      }  
    },  
      
    "parties": {  
      "seller": {  
        "name": "Laboratorios Leti",  
        "rif": "J-00000000-1",  
        "gln": "7590000000001"  
      },  
      "buyer": {  
        "name": "Drogueria Distribuidora X",  
        "rif": "J-11111111-2",  
        "sicm": "S-12345"  
      },  
      "ship\_to": {  
        "name": "Farmacia El Pueblo",  
        "rif": "J-22222222-3",  
        "sicm": "S-98765",  
        "delivery\_address": {  
          "street": "Av. Principal",  
          "city": "Caracas",  
          "state": "Distrito Capital",  
          "zip": "1010"  
        }  
      },  
      "sales\_agent": {  
        "name": "Juan Perez",  
        "employee\_id": "VEN-042"  
      }  
    },

    "logistics": {  
      "carrier": "Yummy",  
      "shipping\_method": "Motorizado Express",  
      "tracking\_reference": "YUM-8821-XX"  
    },

    "payment\_terms": {  
      "method": "Multi-Pago",  
      "term\_type": "Contado",  
      "net\_days": 0,  
      "currency": "USD"  
    },

    "applied\_payments": \[  
      {  
        "payment\_id": "PAY-001",  
        "method": "PAGO\_MOVIL",  
        "status": "COMPLETED",  
        "amounts": {  
          "paid\_currency": "VES",  
          "amount\_paid": 4500.00,  
          "exchange\_rate\_usd": 45.00,  
          "amount\_usd\_equivalent": 100.00  
        },  
        "reference\_data": {  
          "confirmation\_number": "1928374652",  
          "bank\_code": "0102",  
          "payer\_id": "V-12345678",  
          "payer\_phone": "04141234567"  
        }  
      },  
      {  
        "payment\_id": "PAY-002",  
        "method": "TARJETA\_DEBITO",  
        "status": "COMPLETED",  
        "amounts": {  
          "paid\_currency": "VES",  
          "amount\_paid": 1372.50,  
          "exchange\_rate\_usd": 45.00,  
          "amount\_usd\_equivalent": 30.50  
        },  
        "reference\_data": {  
          "confirmation\_number": "000456",  
          "bank\_code": "0105",  
          "pos\_terminal\_id": "TERM-8821"  
        }  
      }  
    \],

    "lines": \[  
      {  
        "line\_id": 1,  
        "product": {  
          "gtin": "7591234567890",  
          "vendor\_part": "LETI-AMOX-500",  
          "description": "Amoxicilina 500mg x 21 capsulas"  
        },  
        "pharma\_tracking": {  
          "lot\_number": "L-202509A",  
          "expiry\_date": "2028-09-01"  
        },  
        "qty": {  
          "uom": "Caja",  
          "ordered": 50,  
          "delivered": null  
        },  
        "pricing": {  
          "unit\_price": 2.50,  
          "currency": "USD"  
        },  
        "discounts\_charges": \[  
          {  
            "type": "Discount",  
            "description": "Descuento Comercial Leti",  
            "applied\_by": "Laboratorio",  
            "percentage": 10.00,  
            "amount": 12.50  
          }  
        \],  
        "taxes": \[  
          {  
            "type": "IVA",  
            "percentage": 16.00,  
            "amount\_bs": 720.00   
          },  
          {  
            "type": "IGTF",  
            "percentage": 3.00,  
            "amount\_bs": 135.00  
          }  
        \],  
        "line\_total\_net": 112.50  
      }  
    \],

    "summary": {  
      "total\_lines": 1,  
      "total\_net\_usd": 112.50,  
      "total\_discounts\_usd": 12.50,  
      "total\_gross\_usd": 130.50,  
      "total\_taxes\_bs": 855.00,  
      "total\_paid\_bs": 5872.50,  
      "total\_paid\_usd": 130.50  
    }  
  }  
}

### Key Architectural Features of this Payload:

1. **The Routing Envelope:** The kontext\_routing object ensures the AS5 Hub knows exactly how to route and process this document (e.g., triggering the correct JSONata translation scripts) without needing to inspect the heavy business logic inside the payload 1, 2\.  
2. **GS1 & SICM Compliance:** By including gln, gtin, and sicm numbers, the payload satisfies LATAM pharmaceutical traceability requirements to ensure valid health permits and batch tracking 3\.  
3. **Decoupled Exchange Rates:** The applied\_payments array cleanly isolates the VES (Bolívares) amounts paid at the time of sale alongside the exact exchange\_rate\_usd applied, guaranteeing Leti and the Droguerías have zero decimal-rounding mismatches during reconciliation.  
4. **Zero-Touch Bank Reconciliation:** The reference\_data block securely transmits PagoMovil and point-of-sale data, allowing the receiving ERP to automatically match the transaction against their daily bank statements.

