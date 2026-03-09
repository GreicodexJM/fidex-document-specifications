Here is what the **FULL\_SYNC** payload looks like.  
When the Droguería's system detects a Merkle Root mismatch (meaning a delta update was dropped or corrupted), it automatically requests a baseline reset. Laboratorios Leti’s ERP responds by generating a complete snapshot of the entire active database.  
Because this payload contains every single SKU (potentially tens of thousands of items), the AS5 Hub securely stores the heavy JSON payload in its Amazon S3 Vault, while the lightweight transmission relies on the same standard JOSE cryptography 1\.

### The FULL\_SYNC JSON Payload

{  
  "kontext\_routing": {  
    "tenant\_id": "tenant-leti-01",  
    "receiver\_id": "partner-drogueria-x",  
    "document\_type": "GS1\_CATALOG\_JSON",  
    "correlation\_id": "SYNC-FULL-1043"  
  },  
  "payload": {  
    "document\_info": {  
      "version": "1.3",  
      "doc\_type": "CATALOG",  
      "document\_number": "SYNC-FULL-1043",  
      "status": "PUBLISHED",  
      "currency\_base": "USD"  
    },  
      
    "catalog\_metadata": {  
      "catalog\_name": "Re-Sincronización Maestra de Inventario \- Leti",  
      "catalog\_type": "FULL\_SYNC",  
      "includes\_inventory": true,  
      "sync\_state": {  
        "sequence\_id": 1043,  
        "previous\_merkle\_root": null,   
        "current\_merkle\_root": "m5n6o7p8q9r0s1t2u3v4",  
        "total\_active\_skus": 1450  
      }  
    },

    "items": \[  
      {  
        "action": "UPSERT",  
        "product": {  
          "vendor\_part": "LETI-AMOX-500",  
          "gtin": "7591234567890",  
          "brand\_name": "Leti",  
          "description": "Amoxicilina 500mg x 21 capsulas"  
        },  
        "pricing\_tiers": \[  
          {  
            "tier\_code": "WHOLESALE\_STD",  
            "currency": "USD",  
            "unit\_price\_net": 2.50  
          }  
        \],  
        "inventory": {  
          "status": "IN\_STOCK",  
          "available\_qty": 14950,  
          "last\_updated": "2026-02-27T11:50:00Z"  
        }  
      },  
      {  
        "action": "UPSERT",  
        "product": {  
          "vendor\_part": "LETI-IBUP-400",  
          "gtin": "7590987654321",  
          "brand\_name": "Leti",  
          "description": "Ibuprofeno 400mg x 10 tabletas"  
        },  
        "pricing\_tiers": \[  
          {  
            "tier\_code": "WHOLESALE\_STD",  
            "currency": "USD",  
            "unit\_price\_net": 1.20  
          }  
        \],  
        "inventory": {  
          "status": "OUT\_OF\_STOCK",  
          "available\_qty": 0,  
          "last\_updated": "2026-02-27T11:50:00Z"  
        }  
      }  
      // ... Contains all 1,450 active SKUs ...  
    \]  
  }  
}

### Key Differences in the FULL\_SYNC State Machine

**1\. The previous\_merkle\_root is Nullified**In a DELTA\_UPDATE, the previous root must perfectly match the receiver's database hash. In a FULL\_SYNC, the previous\_merkle\_root is explicitly set to null (or ignored) because the receiver is instructed to overwrite their existing state entirely.  
**2\. The UPSERT Action**Instead of INSERT, UPDATE, or DELETE, every single item in the array is flagged as an UPSERT (Update or Insert).

* When the Droguería's ERP processes this file, it checks if 7591234567890 exists. If yes, it overwrites the exact quantity and price. If no, it creates the product.  
* Any product currently in the Droguería's database that is *not* included in this payload of 1,450 items is automatically archived or marked OUT\_OF\_STOCK.

**3\. Establishing the New Baseline**Once the Droguería's system finishes processing all 1,450 items, it runs a SHA-256 hash over its newly updated local database table.

* If the local hash matches the payload's current\_merkle\_root (m5n6o7p8...), the crisis is resolved.  
* The Droguería's system acknowledges the payload with a J-MDN receipt 2\.  
* From that moment on, Leti resumes sending tiny DELTA\_UPDATE payloads referencing sequence\_id: 1044, and the supply chain continues running smoothly.

