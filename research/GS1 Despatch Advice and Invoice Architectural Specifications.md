Following the exact same philosophy we established for Orders and Catalogs—utilizing the kontext\_routing envelope, English machine-readable enums, GS1 LATAM traceability, and multi-currency tax decoupling—we can define the **Despatch Advice** (Advance Ship Notice / ASN) and the **Invoice**.  
In supply chain architecture, these documents must be mathematically correlated. If Laboratorios Leti receives an Order (ORD-2026-9921), the subsequent ASN and Invoice must reference that original order to allow the distributor's ERP to achieve a "Three-Way Match" (Order \= Receipt \= Invoice) 1\.  
Here are the canonical JSON formats for both documents.

### 1\. The Despatch Advice (Advance Ship Notice / ASN)

The Despatch Advice is critical for the physical logistics layer. It tells the Droguería's receiving warehouse exactly what is in the truck, what batches/lots are arriving, and when to expect them 2\.  
{  
  "kontext\_routing": {  
    "tenant\_id": "tenant-leti-01",  
    "receiver\_id": "partner-drogueria-x",  
    "document\_type": "GS1\_DESPATCH\_ADVICE\_JSON",  
    "correlation\_id": "ORD-2026-9921"  
  },  
  "payload": {  
    "document\_info": {  
      "version": "1.2",  
      "doc\_type": "DESPATCH\_ADVICE",  
      "document\_number": "ASN-88421",  
      "related\_order": "ORD-2026-9921",  
      "status": "SHIPPED",  
      "dates": {  
        "issued\_at": "2026-02-28T09:00:00Z",  
        "estimated\_delivery": "2026-02-28T14:30:00Z"  
      }  
    },

    "parties": {  
      "shipper": {  
        "name": "Laboratorios Leti \- Almacen Central",  
        "rif": "J-00000000-1",  
        "gln": "7590000000001"  
      },  
      "ship\_to": {  
        "name": "Farmacia El Pueblo",  
        "rif": "J-22222222-3",  
        "sicm": "S-98765"  
      }  
    },

    "logistics": {  
      "carrier": {  
        "name": "Logistica Yummy Fleet",  
        "tracking\_reference": "YUM-8821-XX"  
      },  
      "driver": {  
        "name": "Pedro Perez",  
        "national\_id": "V-12345678",  
        "vehicle\_plate": "A12-BCD"  
      },  
      "packaging": {  
        "total\_packages": 2,  
        "sscc": "175912345678901234"   
      }  
    },

    "lines": \[  
      {  
        "line\_id": 1,  
        "related\_order\_line": 1,  
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
          "shipped": 50,  
          "ordered": 50  
        }  
      }  
    \]  
  }  
}

### 2\. The Invoice (Factura)

The Invoice is the fiscal and legal representation of the transaction. Because this document will be processed by the **FideX Government Compliance Layer**, it requires strict multi-currency summary blocks so the tax authorities (SENIAT) can extract the base amounts and tax totals in Bolívares (Bs) via the Merkle Rollup without exposing the line-item trade secrets 3, 4\.  
{  
  "kontext\_routing": {  
    "tenant\_id": "tenant-leti-01",  
    "receiver\_id": "partner-drogueria-x",  
    "document\_type": "GS1\_INVOICE\_JSON",  
    "correlation\_id": "ORD-2026-9921"  
  },  
  "payload": {  
    "document\_info": {  
      "version": "1.2",  
      "doc\_type": "INVOICE",  
      "document\_number": "INV-2026-00145",  
      "related\_order": "ORD-2026-9921",  
      "related\_asn": "ASN-88421",  
      "status": "ISSUED",  
      "currency\_base": "USD",  
      "dates": {  
        "issued\_at": "2026-02-28T10:00:00Z",  
        "due\_date": "2026-03-15T23:59:59Z"  
      }  
    },

    "parties": {  
      "biller": {  
        "name": "Laboratorios Leti",  
        "rif": "J-00000000-1",  
        "gln": "7590000000001"  
      },  
      "payer": {  
        "name": "Drogueria Distribuidora X",  
        "rif": "J-11111111-2"  
      }  
    },

    "payment\_terms": {  
      "method": "Transferencia",  
      "term\_type": "NET\_15",  
      "net\_days": 15,  
      "exchange\_rate\_pegged": 45.00  
    },

    "lines": \[  
      {  
        "line\_id": 1,  
        "related\_order\_line": 1,  
        "product": {  
          "gtin": "7591234567890",  
          "description": "Amoxicilina 500mg x 21 capsulas"  
        },  
        "qty": {  
          "uom": "Caja",  
          "invoiced": 50  
        },  
        "pricing": {  
          "unit\_price": 2.50,  
          "currency": "USD"  
        },  
        "taxes": \[  
          {  
            "type": "IVA",  
            "percentage": 16.00,  
            "amount\_bs": 720.00   
          }  
        \],  
        "line\_total\_net": 112.50  
      }  
    \],

    "summary": {  
      "total\_lines": 1,  
      "total\_net\_usd": 112.50,  
      "total\_discounts\_usd": 12.50,  
      "total\_taxes\_usd": 18.00,  
      "total\_gross\_usd": 130.50,  
      "fiscal\_totals\_ves": {  
        "exchange\_rate\_applied": 45.00,  
        "base\_imponible\_ves": 5062.50,  
        "total\_iva\_ves": 810.00,  
        "total\_igtf\_ves": 0.00,  
        "total\_gross\_ves": 5872.50  
      }  
    }  
  }  
}

### Architectural Highlights of These Formats:

1. **The Correlation Triangle:** By injecting related\_order and related\_asn into the document info, and linking correlation\_id in the routing envelope, you allow complex 3PL environments to seamlessly match 50 ASNs back to one massive Target PO without losing context 1, 5\.  
2. **SSCC for Logistics:** The Despatch Advice includes an sscc (Serial Shipping Container Code) in the packaging block. This is standard GS1 practice, allowing the receiving warehouse to simply scan one barcode on a pallet to instantly ingest the GTINs and lot numbers of the 5,000 boxes inside it without opening it.  
3. **FideX Extraction Block:** Notice the specific fiscal\_totals\_ves object in the Invoice summary. When the Hub processes this document, the Go Gateway can instantly extract this precise block to build the hourly **Targeted Tax Manifest** for the government's smart contract rollup, without ever needing to parse or expose the individual line items to the blockchain 3\.

