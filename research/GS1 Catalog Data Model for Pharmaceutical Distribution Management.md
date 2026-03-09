Here is the canonical **GS1\_CATALOG\_JSON** structure (Pricelist and Master Data).  
In your Odoo architecture, this payload maps directly to updating product.template (the master SKUs) and product.pricelist (the specific pricing rules for the partner) 1\. For Leti, this document is vital because it pushes their live inventory, updated USD prices, and specific pharmaceutical attributes down to the Droguerías and the Kontext Pedidos offline app 1, 2\.  
{  
  "kontext\_routing": {  
    "tenant\_id": "tenant-leti-01",  
    "receiver\_id": "partner-drogueria-x",  
    "document\_type": "GS1\_CATALOG\_JSON",  
    "correlation\_id": "CAT-2026-02-VE"  
  },  
  "payload": {  
    "document\_info": {  
      "version": "1.1",  
      "doc\_type": "CATALOG",  
      "document\_number": "CAT-2026-02-VE",  
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
      "catalog\_name": "Lista de Precios Mayorista \- Marzo 2026",  
      "catalog\_type": "MASTER\_UPDATE",  
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
        "pricing": {  
          "unit\_price\_net": 2.50,  
          "msrp\_usd": 4.00,  
          "currency": "USD",  
          "tax\_profile": {  
            "is\_exempt": true,  
            "tax\_type": "IVA",  
            "percentage": 0.00  
          }  
        },  
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
        "pricing": {  
          "unit\_price\_net": 1.20,  
          "msrp\_usd": 2.00,  
          "currency": "USD",  
          "tax\_profile": {  
            "is\_exempt": true,  
            "tax\_type": "IVA",  
            "percentage": 0.00  
          }  
        },  
        "inventory": {  
          "status": "OUT\_OF\_STOCK",  
          "available\_qty": 0,  
          "last\_updated": "2026-02-27T07:55:00Z"  
        }  
      }  
    \]  
  }  
}

### Key Architectural Features of the Pricelist Data Model:

1. **The action Flag (INSERT, UPDATE, DELETE)**Master catalogs can be enormous. By including an action flag at the item level, Leti does not need to send the entire database every time. They can send a "Delta" catalog containing only the SKUs that had price or inventory changes that morning, dramatically reducing the JSON payload size 3, 4\.  
2. **GS1 Pharmaceutical Identity (gtin & pharma\_attributes)**In standard retail EDI (like an 832 Price/Sales Catalog), you usually just send the UPC and the price. In the pharmaceutical industry, regulatory bodies and pharmacies need to know the active\_ingredient, therapeutic\_class, and whether the item requires\_prescription 5\. This ensures that when the Droguería loads the catalog into their local system, their internal pharmacists have the exact sanitary profile of the drug.  
3. **Suggested Retail Price (msrp\_usd)**Because Leti relies on independent pharmacies, controlling the final market price is critical. Sending the msrp\_usd (Manufacturer's Suggested Retail Price) alongside the distributor's unit\_price\_net allows the distributor's POS system to automatically suggest the correct final price to the consumer.  
4. **Embedded Real-Time Inventory (inventory)**Your use-case specifically requires sales forces to have "available inventory and prices" 2\. By embedding the available\_qty and status directly into the catalog update, the Hub can push this JSON down to the **Kontext Pedidos** backend. When the Leti sales rep opens their tablet offline, they immediately know that Ibuprofen is OUT\_OF\_STOCK and Amoxicillin has 15,000 units available 6\.  
5. **Tax Profile Exemption (is\_exempt)**In Venezuela, many essential medicines are exempt from IVA. By explicitly defining "is\_exempt": true and "percentage": 0.00 at the catalog level, Leti guarantees that when the distributor's ERP generates an order, it will not accidentally apply 16% IVA to a regulated medication.

