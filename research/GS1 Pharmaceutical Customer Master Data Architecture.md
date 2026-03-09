Following the exact same philosophy—separating the machine-readable English enums from the localized UI, utilizing the kontext\_routing envelope, and integrating GS1/LATAM pharmaceutical traceability—we can design the **Customer Master Data** document 1, 2\.  
In the context of Odoo, this document maps directly to the res.partner model 3\. For Leti and their distributors (Droguerías), this payload is critical for syncing customer lists down to the **Kontext Pedidos** offline mobile app, ensuring sales agents have up-to-date credit limits, active addresses, and valid health permits before placing an order 4, 5\.  
Here is the canonical **GS1\_CUSTOMER\_MASTER\_JSON** structure:  
{  
  "kontext\_routing": {  
    "tenant\_id": "tenant-leti-01",  
    "receiver\_id": "partner-drogueria-x",  
    "document\_type": "GS1\_CUSTOMER\_MASTER\_JSON",  
    "correlation\_id": "CUST-J222222223"  
  },  
  "payload": {  
    "document\_info": {  
      "version": "1.1",  
      "doc\_type": "CUSTOMER\_MASTER",  
      "document\_number": "C-10045",  
      "status": "ACTIVE",  
      "dates": {  
        "created\_at": "2024-01-15T08:30:00Z",  
        "updated\_at": "2026-02-27T10:00:00Z"  
      }  
    },  
      
    "customer\_details": {  
      "internal\_id": "C-10045",  
      "name": "Farmacia El Pueblo, C.A.",  
      "commercial\_name": "Farmacia El Pueblo",  
      "tax\_id": "J-22222222-3",  
      "gln": "7590000000001",  
      "customer\_type": "PHARMACY\_INDEPENDENT",  
      "health\_permit": {  
        "sicm": "S-98765",  
        "permit\_status": "VALID",  
        "expiration\_date": "2027-12-31"  
      }  
    },

    "contact\_info": {  
      "primary\_contact\_name": "Dra. Maria Gonzalez",  
      "email": "compras@farmaciaelpueblo.com",  
      "phone": "+584141234567"  
    },

    "financial\_profile": {  
      "credit\_status": "APPROVED",  
      "credit\_limit": {  
        "amount": 5000.00,  
        "currency": "USD"  
      },  
      "payment\_terms": {  
        "method": "Transferencia / PagoMovil",  
        "term\_type": "NET\_15",  
        "net\_days": 15  
      },  
      "tax\_profile": {  
        "is\_retention\_agent\_iva": true,  
        "retention\_percentage": 75.00  
      }  
    },

    "sales\_routing": {  
      "assigned\_agent": {  
        "name": "Juan Perez",  
        "employee\_id": "VEN-042"  
      },  
      "delivery\_route": "CARACAS-ESTE-02"  
    },

    "addresses": \[  
      {  
        "address\_type": "BILLING",  
        "street": "Av. Principal, Edif. Central, Piso 1",  
        "city": "Caracas",  
        "state": "Distrito Capital",  
        "zip": "1010",  
        "country\_code": "VE",  
        "is\_default": true  
      },  
      {  
        "address\_type": "SHIPPING",  
        "location\_id": "LOC-01",  
        "street": "Calle 4, Local A, Sector Comercial",  
        "city": "Caracas",  
        "state": "Distrito Capital",  
        "zip": "1010",  
        "country\_code": "VE",  
        "is\_default": true  
      }  
    \]  
  }  
}

### Key Architectural Features of the Customer Data Model:

1. **doc\_type: CUSTOMER\_MASTER**By defining this distinctly, the Hub's Translation Engine and the Odoo adapter instantly know to upsert (update or insert) a res.partner record rather than a purchase.order 3, 6\.  
2. **The health\_permit Object (SICM Control)**In the Venezuelan pharma industry, you cannot legally dispatch medicines to a pharmacy whose SICM (Sistema Integral de Control de Medicamentos) permit is expired 1\. By nesting permit\_status and expiration\_date directly into the master data, the Kontext Pedidos offline app can automatically block a sales agent from generating a quote for a non-compliant client 5\.  
3. **The financial\_profile (Multi-Currency Credit)**Because Leti and the Droguerías operate in a multi-currency environment, explicitly stating the credit\_limit currency (USD) ensures that local ERPs (Profit, Saint, Odoo) synchronize the correct baseline before approving orders offline 5, 7\. We also include the tax\_profile to indicate if the customer is a special taxpayer (*Agente de Retención*), which dynamically alters how the final invoice calculates IVA retention 8, 9\.  
4. **Separation of addresses**Large pharmacy chains use a single Tax ID (RIF) and Billing address but have dozens of Shipping addresses. The array structure allows Leti to transmit a single customer record with multiple SHIPPING nodes, ensuring the logistics providers (like Yummy or LTL fleets) get precise destination data for the specific branch 10\.  
5. **sales\_routing Integration**Passing the assigned\_agent and delivery\_route means that as soon as this JSON hits the AS5 Hub and pushes down to the distributor's ERP, the offline Kontext Pedidos app instantly updates its territory routing, ensuring the right agent sees the right pharmacies on their tablet 5\.

