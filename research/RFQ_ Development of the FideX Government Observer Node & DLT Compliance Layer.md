### RFQ: Development of the FideX Government Observer Node & DLT Compliance Layer

#### 1\. Project Overview and Strategic Objectives

The FideX Government Observer node represents the strategic infrastructure required to modernize the Latin American pharmaceutical supply chain, specifically bridging the gap between private B2B commerce and government regulatory oversight (SENIAT/SUDEBAN). The current landscape relies on legacy, high-latency methods such as SFTP and CSV file exchanges, which lack cryptographic non-repudiation and real-time visibility. By transitioning to the  **AS5 protocol** —a modernized successor to AS4 utilizing REST, JSON, and the JOSE framework—FideX enables a high-performance ecosystem for the secure exchange of GS1-compliant business documents.A central requirement of this project is solving the  **"Privacy Paradox"** : the inherent tension between a government’s mandate for transaction visibility and a private corporation’s need to protect trade secrets (e.g., unit margins and supplier lists). The proposed architecture solves this by decoupling logistical reality from fiscal and legal reality. While full business documents are transmitted point-to-point between partners, the Government Observer node extracts targeted fiscal metadata to be anchored on an immutable ledger.This document defines the technical requirements for the AS5 protocol implementation, the functional specifications for the Government Observer, and the DLT-based Continuous Transaction Control (CTC) layer.

#### 2\. Technical Foundation: The AS5 Protocol Specification

The developer MUST implement the FideX (AS5) protocol as a REST-based, asynchronous messaging standard that replaces legacy EDI protocols.

##### 2.1 Cryptographic Standards and Security Stack

* **Message Format:**  All payloads MUST be JSON-formatted.  
* **JOSE Framework:**  Implementations MUST utilize  **JWS (JSON Web Signature)**  for origin proof and  **JWE (JSON Web Encryption)**  for confidentiality.  
* **Sign-then-Encrypt Pattern:**  The node MUST implement the pattern JWE(JWS(payload)).  
* **JWS Signature:**  Mandate  **RS256**  (RSA Signature with SHA-256) for broad compatibility and  **ES256**  (ECDSA) for high-performance modern environments.  
* **JWE Encryption:**  Mandate  **RSA-OAEP-256**  for key encryption and  **A256GCM**  for content encryption to ensure forward secrecy.  
* **Forward Secrecy:**  Implementations SHOULD support  **ECDH-ES+A256KW**  as a recommended key agreement algorithm.

##### 2.2 J-MDN (JSON Message Disposition Notification)

The J-MDN serves as a legally binding, cryptographically signed receipt. The developer MUST ensure:

* **Canonical Serialization:**  Receipts must follow a strict serialization order to ensure consistent hashing.  
* **Hash Verification:**  The J-MDN MUST include a SHA-256 hash of the  **plaintext**  payload (different from the payload\_digest of the encrypted JWE).  
* **Status Codes:**  Support NETWORK\_DELIVERED (Technical) and FISCAL\_CLEARED (Fiscal) states.

##### 2.3 Partner Discovery and Onboarding

To eliminate manual certificate exchange, the node MUST support  **QR-based Auto-Discovery** :

* **Bootstrapper URL:**  Scanning a partner’s QR code must resolve to a standardized configuration endpoint: /.well-known/as5-configuration.  
* **Partner Discovery Document:**  This JSON object MUST contain the jwks\_uri, message\_endpoint, algorithms\_supported, and an issuer URN.  
* **4-Phase Handshake:**  An automated process where systems exchange Discovery URLs, fetch public keys via JWKS, and register webhooks via a POST request containing a short-lived  **Invite Token** .

#### 3\. Government Observer Node: Functional Requirements

The Government Observer Node is the gateway for real-time tax visibility, allowing regulatory bodies to index fiscal liabilities without accessing sensitive commercial line items.

##### 3.1 Implementation Options

The developer MUST deliver two implementation modes for the node:

* **Option A (Lightweight Observer):**  Metadata-only notifications (Sender GLN, Receiver GLN, Document Hash, Timestamp) transmitted to a government endpoint.  
* **Option B (High-Value Encrypted Manifest):**  Implementation of the  **"Tax Agency JWE."**  The node MUST extract specific fiscal data into a  **Targeted Tax Manifest** , which is then encrypted using the government’s public key. Only the tax authority, holding the private key, can decrypt this manifest.

##### 3.2 Targeted Tax Manifest Extraction Logic

The node MUST utilize  **JSONata translation maps**  to extract and flatten specific nested objects for the government gateway. The extraction MUST include:

* **Fiscal Totals:**  TaxBase, TaxAmount, ExemptAmount, IGTFAmount, and GrandTotal.  
* **Venezuelan Specifics:**  fiscal\_totals\_ves (all amounts converted to Bolívares using the BCV exchange rate at the time of transaction).  
* **Third-Party Billing:**  If present, the node MUST aggregate ExemptAmountThird, TaxBaseThird, and TaxAmountThird.  
* **Exclusion:**  Line-item descriptions, unit prices, and proprietary SKU data MUST be excluded from the manifest.

#### 4\. Distributed Ledger & Smart Contract Architecture

To ensure Continuous Transaction Controls (CTC), FideX requires an immutable ledger to prevent "double-invoicing" and retrospective tampering.

##### 4.1 Solidity Smart Contract Requirements

The contract MUST be deployed on an EVM-compatible network (Polygon Edge or Hyperledger Besu) and include:

* **Authorization Whitelisting:**  Admin-controlled mapping of authorized FideX node addresses.  
* **anchorHourlyRollup**  **Function:**  This function MUST store a bytes32 merkleRoot and a string manifestURI (pointing to the encrypted Tax Manifest in S3/Vault).  
* **Immutability:**  A mapping of the Document Hash to the block timestamp to prevent replay attacks.

##### 4.2 Merkle Batching (L2 Style Rollups)

To maintain  **1.4-second B2B transmission speeds** , the system MUST utilize  **Merkle Batching** :

* **Asynchronous Rollup:**  A background worker MUST aggregate all transaction hashes into a Merkle Tree once per hour.  
* **Master Hash:**  Only the hourly Merkle Root is pushed to the blockchain, minimizing gas costs and consensus latency.

##### 4.3 Two-Stage Receipt State Machine

The developer MUST implement a two-stage acknowledgment process:

1. **Technical J-MDN:**  Immediate network delivery confirmation (Target \< 2s) to allow logistics/forklift operations to proceed.  
2. **Fiscal J-MDN:**  A subsequent confirmation issued once the transaction’s Merkle Proof is anchored on the DLT. This receipt MUST contain the  **Merkle Proof**  (the mathematical path) so the receiver can verify the transaction against the anchored root.

#### 5\. Pharmaceutical Supply Chain Data Models

All data models MUST be GS1-compliant and utilize English machine-readable enums with multi-currency tax decoupling.| Document Type | Key Data Components | Strategic Impact || \------ | \------ | \------ || **GS1\_ORDER\_JSON** | SICM numbers, GTINs, GLNs, applied\_payments (including bank\_code, payer\_phone, confirmation\_number). | Enables  **Zero-Touch Bank Reconciliation**  for PagoMovil/Zelle. || **GS1\_INVOICE\_JSON** | fiscal\_control (Series/Letters), fiscal\_totals\_ves (IVA/IGTF),  **Correlation Triangle**  (related\_order, related\_asn). | Facilitates "Three-Way Match" (Order \= Receipt \= Invoice) for 3PL. || **GS1\_CATALOG\_JSON** | sync\_state (previous\_merkle\_root, current\_merkle\_root), msrp\_usd, is\_exempt. | Prevents  **Inventory Drift** ; enables self-healing "Rsync-style" synchronization. || **GS1\_CUSTOMER\_MASTER** | health\_permit (SICM status/expiration), financial\_profile (USD credit limits). | Prevents illegal dispatches to pharmacies with expired permits. |

##### 5.1 Merkle Root State Vector

The sync\_state object is MANDATORY for Catalog and Inventory documents. If the receiver’s local hash does not match the previous\_merkle\_root, the node MUST reject the update and trigger an automated FULL\_SYNC request.

#### 6\. Ecosystem Integration: Odoo & Reference Implementations

The FideX technology MUST be deployable at the "Edge" (Laboratory/Distributor level) using a serverless-ready, event-driven architecture.

##### 6.1 Odoo AS5 Plugin Requirements

* **Document Mixin Architecture:**  A Python-based mixin allowing any Odoo model (PO, Invoice, Picking) to inherit AS5 capabilities.  
* **AS5 Message Ledger:**  A centralized ledger in Odoo’s PostgreSQL to track message status (Queued ➔ Transmitted ➔ Delivered) and store cryptographic J-MDN signatures.  
* **Batching/De-batching:**  Support the  **Scatter-Gather Pattern** . The plugin MUST handle  **Inbound De-batching**  (exploding legacy CSVs into individual JSON webhooks) and  **Outbound Consolidation**  (batching multiple invoices into a single X12/CSV for legacy partners).

##### 6.2 AWS-based Multi-Tenant SaaS Hub

* **AWS KMS Isolation:**  Tenant private keys MUST be  **Hardware-Secured** . Cryptographic operations MUST happen within the KMS boundary; keys must never be exported in plaintext.  
* **Usage-Based Billing:**  Integrated with Stripe to meter as5\_messages\_processed, network\_transmission\_attempts, and data\_processed\_mb.

##### 6.3 Reference Implementations

Bidders MUST deliver three reference nodes:

1. **Go (High-Performance):**  The primary engine for the SaaS backend and government validators.  
2. **NodeJS (Modern API):**  Focused on developer adoption and Serverless (Lambda) deployment.  
3. **PHP (Long-Tail Deployment):**  Optimized for shared-hosting environments to onboard small LATAM pharmacies.

#### 7\. Submission Requirements & Selection Criteria

Bidders MUST demonstrate a proven track record in DLT architecture and B2B protocols. All code MUST be "Production-Ready" and include comprehensive test vectors.

##### 7.1 Required Deliverables

1. **FideX Go Binary:**  Functional Government Observer node binary.  
2. **Solidity Smart Contract:**  Source code, deployment scripts, and unit tests for EVM deployment.  
3. **Reference Implementations:**  Complete source for Go, Node, and PHP implementations.  
4. **Integration Artifacts:**   **Postman Collections**  and  **OpenAPI/Swagger**  specs for the /as5-configuration and /messages endpoints.  
5. **Translation Maps:**  JSONata maps for Odoo-to-GS1 and GS1-to-SENIAT transformations.

##### 7.2 Evaluation Metrics

* **Cryptographic Correctness:**  Strict adherence to RSA-OAEP-256 and Sign-then-Encrypt standards.  
* **Latency Targets:**  Technical J-MDN MUST be issued in  **\< 2 seconds** .  
* **Consensus Latency:**  Smart contracts MUST be tested for sub-second block finality or efficient hourly batching.  
* **Regulatory Compliance:**  Full alignment with Venezuelan fiscal regulations (IVA/IGTF/SICM).FideX is the vision for the "Internet of Invoices" in Latin America. We require partners capable of building a robust, cryptographically secure infrastructure that moves the pharmaceutical industry from legacy silos into a unified, transparent, and compliant ecosystem.

# Annex A \- Game Theory

From a Game Theory perspective, the battle between B2B protocols (like your AS5/FideX standard versus legacy AS2 or SFTP/CSV) is fundamentally a **Coordination Game** heavily influenced by network effects.

Here is how the FideX protocol performs against its alternatives through the lens of game theory, and the strategic mechanisms you can use to force its adoption.

### **1\. Performance Against Alternatives: The Coordination Trap**

In a Coordination Game, multiple Nash equilibria can exist, meaning players are best off doing whatever everyone else is doing. Legacy protocols like AS2 persist not because they are technically superior, but because of their massive installed base—they represent an entrenched, historically contingent Nash equilibrium.

* **The AS2/SFTP Equilibrium (Risk-Dominant but Inefficient):** Using legacy systems requires immense coordination costs (weeks of IT meetings, manual PGP key exchanges, and rigid EDI schemas). However, it is a "safe" choice because large networks already use it.  
* **The AS5/FideX Equilibrium (Pareto-Dominant):** Your protocol represents a significantly better outcome for all players. By utilizing JSON REST APIs and automated QR-code handshakes, the cost of establishing a connection drops to near zero, taking only seconds.

The game-theoretic problem is that migrating an entire industry from an inefficient equilibrium to a Pareto-superior one requires a coordinated leap; otherwise, early adopters are left with a great protocol but no one to talk to.

### **2\. Incentivizing Adoption: Strategic Game Mechanics**

To drive adoption and ensure compliance, you must manipulate the payoff matrix using principles from **Evolutionary Game Theory** and **Mechanism Design**.

**A. Breaking the Trap via an "Anchor Partner" (Evolutionary Tipping Point)** In evolutionary game theory, if a population has even a slight bias or historical contingency in one direction, it can trigger a self-reinforcing process that moves the entire system toward a new "evolutionary attractor".

* **The Strategy:** You do not need to convince the whole market at once. You leverage your "Anchor Partner," Laboratorios LETI, to unilaterally change the payoff matrix for the rest of the supply chain. Because LETI holds massive market power, if they mandate AS5 for their distributors (Droguerías), the distributors' "best response" instantly shifts from resisting change to adopting AS5 to maintain their revenue.

**B. Lowering the "Cost of Cooperation"** In games like the Prisoner’s Dilemma, cooperation is hard to sustain if the cost of cooperating is too high. You must make the transition to AS5 frictionless.

* **The Strategy:** By providing open-source reference implementations (like a PHP node that runs on a $1/month VPS) and utilizing point-and-shoot QR code onboarding, you eliminate the massive IT integration costs that usually deter small pharmacies. By making the cost of cooperation near zero, adopting AS5 becomes a dominant strategy.

**C. Receiver-Driven Enforcement (Mechanism Design)** Since FideX is an open-source protocol featuring a decentralized tax ledger, a rogue participant could theoretically fork the code, bypass the government observer node, and send private P2P messages to evade taxes. To prevent this, FideX relies on **Mechanism Design** to ensure "incentive compatibility" (where acting truthfully or complying is in the player's own best interest).

* **The Strategy:** You weaponize the receiver's incentives. In B2B transactions, the sender desperately needs a Proof of Delivery (the J-MDN receipt) to legally demand payment. FideX hardcodes a rule: *the receiver's node will not issue a J-MDN unless it can independently verify the document's hash on the FideX ledger*. If a sender tries to cheat the ledger, the receiver drops the payload, and the sender does not get paid. Thus, ledger compliance becomes the sender's strictly dominant strategy.

**D. Eliminating Mutual Defection via External Payoffs (Tax Deductibility)** What if both the sender and receiver collude to modify their software and bypass the ledger together? Game theory requires an external penalty to break this mutual defection.

* **The Strategy:** You align the protocol with government tax incentives (like VAT or Continuous Transaction Controls). If a buyer accepts an "off-ledger" invoice from a rogue supplier, the government will not allow the buyer to claim a tax deduction for that expense, forcing the buyer to pay the tax penalty out of pocket. By introducing the government as an external enforcer, it becomes economically suicidal for buyers to collude, cementing FideX as the only rational B2B standard.

# ANNEX B \- Bootstrapping

Having Laboratorios LETI and Droguería BLV as your initial customers is actually the perfect beachhead. In B2B protocol adoption, you do not need 100 random customers to start; you need one massive "Anchor Partner" to create a network effect.

Because Laboratorios LETI is one of the largest pharmaceutical laboratories in Venezuela, their success story can force a natural top-down adoption across their entire downstream supply chain.

Here is a 4-step strategic roadmap to bootstrap your AS5/FideX format into a nationwide Venezuelan standard, leveraging your current position:

### **1\. Build the "Poster Child" Proof of Concept (Months 1-3)**

Your immediate goal is to make Laboratorios LETI and Droguería BLV your ultimate success story.

* **The Execution:** Deploy your Go-based reference implementation between LETI and BLV to process real, live B2B transactions using your `GS1_ORDER_JSON` and `GS1_INVOICE_JSON` formats.  
* **The Deliverable:** Document this implementation as a case study. Show exactly how LETI and BLV upgraded from sending legacy CSV files over SFTP to achieving instant, cryptographically secure AS5 connections.

### **2\. Secure the Institutional Moat: GS1 Venezuela (Months 3-6)**

Your AS5 format is already deeply integrated with GS1 pharmaceutical traceability standards (utilizing GLNs, GTINs, and SSCCs). This is your strongest asset for industry-wide adoption.

* **The Pitch:** Take the successful LETI-BLV case study directly to GS1 Venezuela and GS1 LATAM.  
* **The Goal:** Pitch FideX as the recommended B2B interchange protocol for LATAM pharma. If an organization like GS1 formally recommends or endorses your standard to ensure pharmaceutical traceability and cold-chain compliance, your format becomes the default industry standard.

### **3\. Capture the "Long Tail" with Frictionless Tech (Months 6-12)**

Once LETI is on board, they will want to connect with dozens of other smaller distributors and thousands of independent pharmacies. These smaller players often run legacy local ERPs (Saint, Profit) on cheap infrastructure. You must remove all technical friction for them:

* **The PHP Reference Implementation:** While your core Hub uses Go or Node.js, release an open-source PHP reference implementation. This allows small pharmacies to host a FideX node on cheap cPanel shared hosting or $1 VPS servers.  
* **QR Code Onboarding:** Utilize your "Point-and-Shoot" QR onboarding. Leti's sales reps can walk into a pharmacy, have the pharmacy scan a QR code, and instantly establish a secure cryptographic handshake without needing an IT team.  
* **The "Red Hat" Business Model:** Keep the protocol open-source (Free/OSS), but sell your **Kontext Hub** as a low-cost SaaS ($10-$29/mo) to small pharmacies that don't want to deal with hosting.

### **4\. The "Nuclear Option": Government Visibility (Year 2\)**

The final step to cementing wide adoption is leveraging the heavy fiscal compliance requirements in Venezuela (SENIAT).

* **The Pitch to SENIAT:** Present the FideX Government Observer node to tax authorities. Show them how FideX provides real-time, immutable tax visibility using Merkle Trees and Targeted Tax Manifests, giving them what they need without exposing LETI's or BLV's commercial trade secrets to the public.  
* **The Result:** If the government sees the value in this real-time continuous transaction control (CTC) and decides to mandate or heavily incentivize the FideX protocol for pharma traceability (similar to Brazil's NF-e system), adoption across the entire Venezuelan industry will become compulsory.

