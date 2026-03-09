Here is the complete, canonical **GS1\_CATALOG\_JSON** example. This payload integrates the standardized routing envelope 1, pharmaceutical traceability (GS1, GLN, GTIN) 2, embedded real-time inventory for offline sales apps 3, and the multi-tiered, multi-currency pricing array we discussed.  
This is the exact JSON structure Laboratorios Leti would emit to the Kontext AS5 Hub to update a distributor's ERP (and subsequently, the Kontext Pedidos mobile app) with their latest prices, commercial tiers, and available stock.  
{  
  "kontext\_routing": {  
    "tenant\_id": "tenant-leti-01",  
    "receiver\_id": "partner-drogueria-x",  
    "document\_type": "GS1\_CATALOG\_JSON",  
    "correlation\_id": "CAT-2026-03-VE"  
  },  
  "payload": {  
    "document\_info": {  
      "version": "1.2",  
      "doc\_type": "CATALOG",  
      "document\_number": "CAT-2026-03-VE",  
      "status": "PUBLISHED",  
      "currency\_base": "USD",  
      "dates": {  
        "published\_at": "2026-02-27T08:00:00Z",  
        "valid\_from": "2026-03-01T00:00:00Z",  
        "valid\_to": "2026-03-31T23:59:59Z"  
      }  
    },

    "parties": {  
      "publisher": {  
        "name": "Laboratorios Leti",  
        "rif": "J-00000000-1",  
        "gln": "7590000000001"  
      },  
      "target\_recipient": {  
        "name": "Drogueria Distribuidora X",  
        "rif": "J-11111111-2",  
        "sicm": "S-12345"  
      }  
    },

    "catalog\_metadata": {  
      "catalog\_name": "Lista de Precios y Stock \- Marzo 2026",  
      "catalog\_type": "DELTA\_UPDATE",  
      "includes\_inventory": true  
    },

    "items": \[  
      {  
        "action": "UPDATE",  
        "product": {  
          "vendor\_part": "LETI-AMOX-500",  
          "gtin": "7591234567890",  
          "brand\_name": "Leti",  
          "description": "Amoxicilina 500mg x 21 capsulas"  
        },  
        "pharma\_attributes": {  
          "active\_ingredient": "Amoxicilina Trihidrato",  
          "therapeutic\_class": "Antibiotico de amplio espectro",  
          "presentation": "Caja x 21 Capsulas",  
          "requires\_prescription": true,  
          "storage\_conditions": "ROOM\_TEMPERATURE"  
        },  
        "logistics": {  
          "uom\_sales": "Caja",  
          "units\_per\_box": 1,  
          "master\_carton\_qty": 50,  
          "weight\_kg": 0.05  
        },  
        "tax\_profile": {  
          "is\_exempt": true,  
          "tax\_type": "IVA",  
          "percentage": 0.00  
        },  
        "pricing\_tiers": \[  
          {  
            "tier\_code": "WHOLESALE\_VIP",  
            "description": "Distribuidor Exclusivo (\>100 unidades)",  
            "currency": "USD",  
            "unit\_price\_net": 2.10,  
            "msrp\_usd": 4.00,  
            "conditions": {  
              "minimum\_order\_qty": 100,  
              "valid\_from": "2026-03-01T00:00:00Z",  
              "valid\_to": "2026-12-31T23:59:59Z"  
            }  
          },  
          {  
            "tier\_code": "WHOLESALE\_STD",  
            "description": "Distribuidor Estándar",  
            "currency": "USD",  
            "unit\_price\_net": 2.50,  
            "msrp\_usd": 4.00,  
            "conditions": {  
              "minimum\_order\_qty": 1  
            }  
          },  
          {  
            "tier\_code": "RETAIL\_VES",  
            "description": "Precio Regulado Farmacia Local (Bolívares)",  
            "currency": "VES",  
            "unit\_price\_net": 112.50,  
            "msrp\_ves": 180.00,  
            "conditions": {  
              "minimum\_order\_qty": 1,  
              "exchange\_rate\_pegged": 45.00  
            }  
          }  
        \],  
        "inventory": {  
          "status": "IN\_STOCK",  
          "available\_qty": 15000,  
          "last\_updated": "2026-02-27T07:55:00Z"  
        }  
      },  
      {  
        "action": "INSERT",  
        "product": {  
          "vendor\_part": "LETI-IBUP-400",  
          "gtin": "7590987654321",  
          "brand\_name": "Leti",  
          "description": "Ibuprofeno 400mg x 10 tabletas"  
        },  
        "pharma\_attributes": {  
          "active\_ingredient": "Ibuprofeno",  
          "therapeutic\_class": "AINE / Analgesico",  
          "presentation": "Caja x 10 Tabletas",  
          "requires\_prescription": false,  
          "storage\_conditions": "ROOM\_TEMPERATURE"  
        },  
        "logistics": {  
          "uom\_sales": "Caja",  
          "units\_per\_box": 1,  
          "master\_carton\_qty": 100,  
          "weight\_kg": 0.03  
        },  
        "tax\_profile": {  
          "is\_exempt": true,  
          "tax\_type": "IVA",  
          "percentage": 0.00  
        },  
        "pricing\_tiers": \[  
          {  
            "tier\_code": "WHOLESALE\_STD",  
            "description": "Distribuidor Estándar",  
            "currency": "USD",  
            "unit\_price\_net": 1.20,  
            "msrp\_usd": 2.00,  
            "conditions": {  
              "minimum\_order\_qty": 1  
            }  
          }  
        \],  
        "inventory": {  
          "status": "OUT\_OF\_STOCK",  
          "available\_qty": 0,  
          "last\_updated": "2026-02-27T07:55:00Z"  
        }  
      }  
    \]  
  }  
}

### Key Architectural Features of this Payload:

1. **The Routing Envelope:** The kontext\_routing object wraps the business data so the Kontext AS5 Hub knows exactly how to query the Trading Partner Directory (TPD) and route this document to "partner-drogueria-x" 1, 4\. Because this relies on English machine-enums (GS1\_CATALOG\_JSON), the Hub can route it dynamically without parsing the inner array 1, 5\.  
2. **"Delta" Updates (action: UPDATE):** The catalog\_type is marked as a DELTA\_UPDATE, and individual SKUs specify INSERT, UPDATE, or DELETE. This prevents Leti from having to send a massive 50MB file of their entire database every time stock fluctuates; they only send the specific items that changed inventory or pricing that morning.  
3. **Array of Pricing Tiers:** Instead of flat pricing, the pricing\_tiers array supports complex commercial rules. It defines volume-based scaling (minimum\_order\_qty: 100), promotional dates, and multi-currency compliance (USD alongside VES with a pegged exchange rate) inside a single SKU payload.  
4. **Offline Sales Enablement:** By combining the pricing\_tiers constraints and the real-time available\_qty from the inventory object, the Kontext Pedidos mobile app can automatically calculate volume discounts and prevent stockouts even when the sales agent is completely offline 3, 6\.

