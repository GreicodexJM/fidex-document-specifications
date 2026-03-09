To bridge the gap between Unidigital's hyper-localized SENIAT fiscal schema and our universal, enterprise-grade FideX (AS5) architecture, we must use an **"Extensible Object" philosophy**.  
Instead of flattening and bloating the core B2B supply chain document with hundreds of local Venezuelan edge-case fields, we introduce dedicated nested objects. This allows the format to accommodate strict fiscal requirements without breaking compatibility for international or non-fiscal B2B transmissions.  
Here are the specific, structural improvements to our FideX JSON formats to accommodate the lacking features:

### 1\. The fiscal\_control Object (Series, Letters, and Notes)

To accommodate Unidigital's digital receipt books (Talonarios Digitales), string formatting for PDFs, and tips 1-4, we introduce a fiscal\_control object inside the payload. This object holds all the metadata exclusively required by the local tax authority or digital printer.  
"fiscal\_control": {  
  "fiscal\_series\_id": "123e4567-e89b-12d3-a456-426614174000", // Maps to Unidigital's SerieStrongId  
  "amount\_in\_letters\_ves": "Ciento sesenta y cuatro", // AmountLettersVES  
  "bcv\_message": "Tasa BCV: 36.50",   
  "printable\_notes": \[  
    "Nota importante 1: Mercancía revisada.",  
    "Nota importante 2: Sin derecho a devolución."  
  \]  
}

### 2\. Upgrading summary for Debt and Tips

Unidigital requires tracking of PreviousBalance (Deuda) and Tip (Propina) to calculate the GrandTotal correctly 3\. We can add these to our existing FideX summary block seamlessly while keeping the multi-currency decoupling intact.  
"summary": {  
  "total\_net\_usd": 112.50,  
  "previous\_balance\_usd": 10.00,   
  "tip\_usd": 5.00,  
  "total\_gross\_usd": 145.50,  
  "fiscal\_totals\_ves": {  
    "exchange\_rate\_applied": 36.50,  
    "tip\_ves": 182.50,  
    "previous\_balance\_ves": 365.00,  
    "total\_gross\_ves": 5310.75  
  }  
}

### 3\. Strict Fiscal Linking for Credit/Debit Notes (related\_documents)

For Credit and Debit notes, Unidigital requires strict historical linking—especially if the note affects an invoice issued *before* the digital printing system was adopted 5\. We upgrade our document\_info by converting simple string references into a related\_documents array.  
"document\_info": {  
  "doc\_type": "CREDIT\_NOTE",  
  "related\_documents": \[  
    {  
      "doc\_type": "INVOICE",  
      "document\_number": "157240",  
      "fiscal\_series": "A",  
      "currency\_base": "VES",  
      "emission\_date": "2023-01-01T00:00:00Z", // AffectedDocumentDate  
      "total\_amount": 100.00 // AffectedDocumentAmount  
    }  
  \]  
}

### 4\. Third-Party Billing (third\_party\_beneficiary)

To support Facturación a Terceros 4, 6, we inject an optional third\_party\_beneficiary object into the specific line items. The FideX hub (or the Edge Node) will then dynamically aggregate the ExemptAmountThird, TaxBaseThird, and TaxAmountThird required by Unidigital 6 during the JSONata translation to the SENIAT gateway.  
"lines": \[  
  {  
    "line\_id": 1,  
    "product": { ... },  
    "third\_party\_beneficiary": {  
      "is\_third\_party": true,  
      "name": "Juan Perez",  
      "fiscal\_registry\_type": "V", // FiscalRegistryCodeThird  
      "fiscal\_registry": "87654321" // FiscalRegistryThird  
    }  
  }  
\]

### 5\. New Document Types for Tax Withholding (Retenciones)

Instead of forcing Retenciones into standard Invoices, we define two new FideX doc\_type enums specifically for this workflow: RETENTION\_IVA 7 and RETENTION\_ISLR 8\.  
We introduce a retention\_details object to capture the highly specific Venezuelan perceiver profiles, concept codes, and subtrahends 9, 10\.  
{  
  "kontext\_routing": {  
    "document\_type": "GS1\_RETENTION\_JSON"  
  },  
  "payload": {  
    "document\_info": {  
      "doc\_type": "RETENTION\_ISLR",  
      "document\_number": "157241"  
    },  
    "retention\_details": {  
      "perceiver\_type": "PN-RESIDENTE",   
      "concept\_code": "002", // e.g., Honorarios Profesionales  
      "subtrahend\_ves": 1.00 // SubtrahendPN  
    },  
    "affected\_documents": \[  
      {  
        "document\_number": "1",  
        "control\_number": "1",  
        "doc\_type": "INVOICE",  
        "tax\_base\_ves": 100.00,  
        "retention\_percentage": 75.00,  
        "amount\_retained\_ves": 16.00  
      }  
    \]  
  }  
}

### 6\. Industry-Specific Extensibility (The Travel Module)

To support non-pharma verticals like travel agencies 11 without bloating the pharmaceutical standard, we implement a modular industry\_data wrapper. If the client is a travel agency, they simply append this block:  
"industry\_data": {  
  "industry\_type": "TRAVEL",  
  "travel\_details": {  
    "passenger\_name": "MARIA GONZALEZ",  
    "ticket\_number": "TK123456",  
    "port\_name": "Aeropuerto Internacional",  
    "departure\_point": "Caracas",  
    "arrival\_point": "Miami",  
    "departure\_date": "2024-04-01T08:00:00Z"  
  }  
}

### The Strategic Advantage of this Approach

By isolating SENIAT's rigid requirements (fiscal\_control, retention\_details, multi-currency fiscal\_totals) into nested objects, the core **FideX format remains an internationally viable GS1/AS5 protocol**.  
When Odoo sends this enriched JSON to the Kontext AS5 Hub, the AI-generated JSONata translation map will effortlessly extract the nested fields and flatten them to exactly match Unidigital's strict API requirements 2, 12 before submission, satisfying both enterprise B2B routing logic and local government compliance simultaneously.  
