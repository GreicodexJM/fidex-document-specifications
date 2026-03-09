### Especificación Técnica de Payloads JSON para la Industria Farmacéutica (Estándar AS5/FideX)

#### 1\. Fundamentos Arquitectónicos y la Capa de Enrutamiento

La modernización de la infraestructura EDI hacia el estándar  **AS5**  representa un imperativo estratégico para la cadena de suministro farmacéutica latinoamericana. La transición de archivos planos sobre SFTP hacia arquitecturas basadas en  **JSON/REST**  no es simplemente un cambio de formato; es una evolución hacia la agilidad operativa y la seguridad programática. Al eliminar el "overhead" de los sobres SOAP y la complejidad de las firmas XML-DSig de los sistemas legacy (AS2/AS4), permitimos una integración nativa con ecosistemas modernos como Odoo, Profit o Saint, garantizando que el flujo de información sea tan dinámico como el movimiento físico de los medicamentos.

* **El Envelope de Enrutamiento**  **kontext\_routing**  **:**  Implementamos un patrón de  **"Separación de Responsabilidades" (Separation of Concerns)** , donde los metadatos de transporte se desacoplan de la lógica de negocio. Esto permite que el Hub de integración (Kontext Systems) enrute mensajes sin necesidad de inspeccionar o descifrar el contenido sensible del payload, preservando el secreto comercial.  
* **Seguridad y No Repudio (JOSE):**  Utilizamos el marco  **JOSE**  (JSON Object Signing and Encryption) con un patrón  **"Sign-then-Encrypt"**  (JWE(JWS(payload))). El emisor firma el payload con su clave privada (proporcionando No Repudio de Origen \- NRO) y luego lo cifra con la clave pública del receptor. A diferencia de AS2, implementamos  **Rotación Automatizada de Claves con Zero-Downtime**  mediante el estándar JWKS, exponiendo las claves públicas en el endpoint .well-known/jwks.json.  
* **Racional de Diseño:**  Exigimos el uso de  **enums en inglés**  (e.g., PENDING, SHIPPED, DEBIT\_NOTE) para garantizar la interoperabilidad de las máquinas y la compatibilidad con librerías internacionales de procesamiento de datos, mientras que la localización al español queda relegada estrictamente a la capa de interfaz de usuario (UI).Este "interlock" criptográfico garantiza que cada mensaje sea íntegro y auténtico antes de ser admitido por la capa de traducción de datos (JSONata).

#### 2\. Gestión de Datos Maestros: Clientes y Catálogos

La sincronización de datos maestros es el pilar preventivo para el cumplimiento regulatorio, específicamente para el control del  **SICM (Sistema Integral de Control de Medicamentos)**  en Venezuela. Un error en los datos maestros no es solo un fallo logístico; es un riesgo legal que puede paralizar el despacho de medicamentos críticos.

* **Payload de Maestro de Clientes (GS1\_CUSTOMER\_MASTER\_JSON):**  Diseñado para mapear directamente al modelo res.partner de Odoo, el payload incluye el objeto health\_permit. Este actúa como un "hard-block" lógico: si el permit\_status es inválido o la expiration\_date ha pasado, el sistema bloquea automáticamente la generación de pedidos. Asimismo, el financial\_profile maneja límites de crédito multi-moneda para entornos hiperinflacionarios.  
* **Sincronización de Inventario Basada en Estado (Merkle Root):**  Para eliminar el "inventory drift", implementamos una lógica  **"Rsync-style"** . Cada actualización de inventario (DELTA\_UPDATE) incluye un previous\_merkle\_root y un current\_merkle\_root.  
* Si el hash local del receptor no coincide con el previous\_merkle\_root, el sistema detecta una desincronización de estado, rechaza el delta y dispara automáticamente un  **FULL\_SYNC**  para restablecer el baseline matemático de la existencia.  
* **Estructura de Precios y Descuentos:**  El array discounts\_charges permite una atribución granular de márgenes, especificando si el descuento es aplicado por el  **Laboratorio**  (ej. Leti) o el  **Distribuidor** , permitiendo un cálculo exacto de la rentabilidad antes de la facturación.

#### 3\. Ciclo Transaccional: Orden de Compra Farmacéutica (GS1\_ORDER\_JSON)

La Orden de Compra es el contrato digital inicial. Debe satisfacer los requisitos comerciales del ERP y los protocolos de trazabilidad sanitaria global.

* **Identificación GS1:**  Es mandatorio el uso de  **GLN**  (Global Location Number) para identificar depósitos físicos y  **GTIN**  (Global Trade Item Number) para cada SKU. Esto elimina la ambigüedad en la dispensación de productos con nombres similares pero diferentes concentraciones.  
* **Captura de Pagos Multi-Moneda:**  Para lograr una conciliación bancaria  **"Zero-Touch"** , el array applied\_payments debe capturar campos específicos de  **PagoMóvil** : bank\_code (ej. 0102), payer\_phone y el confirmation\_number. Esto permite que el sistema asocie automáticamente el cobro en el banco con la factura en Odoo o Profit.  
* **Lógica de Impuestos Desacoplados:**  Para mitigar errores de redondeo decimal en entornos multi-moneda, desacoplamos la base comercial del monto fiscal. La base se mantiene en USD, pero el campo amount\_bs (Bolívares) se transmite explícitamente según la tasa oficial, asegurando que ambos ERPs registren pasivos fiscales idénticos.

#### 4\. Logística de Despacho: Advance Ship Notice (ASN)

El ASN (Despatch Advice) es la herramienta fundamental para eliminar cuellos de botella en los muelles de carga de las droguerías.

* **Serial Shipping Container Code (SSCC):**  El uso de SSCC en el bloque de empaque es el "masterstroke" logístico. Permite que el receptor escanee un  **único código de barras en el palé**  para ingerir masivamente miles de unidades de inventario, expandiendo instantáneamente el contenido detallado de las cajas sin abrirlas.  
* **Control de Lotes y Vencimientos:**  Cumpliendo con la farmacovigilancia, el payload exige lot\_number y expiration\_date a nivel de línea. Esto garantiza que el sistema pueda rastrear cualquier unidad en caso de un "recall" sanitario.  
* **Triángulo de Correlación:**  Utilizamos la interconexión entre related\_order, related\_asn y el correlation\_id para lograr el  **"Three-Way Match"**  (Orden \= Recepción \= Factura). En entornos 3PL complejos, esto asegura que cada movimiento físico esté respaldado por una instrucción comercial válida.

#### 5\. Capa Fiscal y Cumplimiento FideX (Invoice/Factura)

La Factura bajo el protocolo FideX no solo es un documento legal, sino una prueba inmutable de cumplimiento tributario reportada en tiempo real.

1. **Targeted Tax Manifest:**  Para resolver la paradoja entre privacidad y transparencia, el Gateway FideX extrae el bloque fiscal\_totals\_ves y lo cifra específicamente para la clave pública de la Autoridad Tributaria. Esto permite que el gobierno audite los montos totales sin exponer los márgenes comerciales o ítems de línea (secretos industriales) en la blockchain.  
2. **Integración FideX y Hash Anchoring:**  Publicamos únicamente el hash SHA-256 del documento en el ledger notarial. Esto crea una prueba de existencia inmutable: si el documento es alterado posteriormente, el hash no coincidirá con el anclaje en la red.  
3. **El MDN Fiscal (J-MDN de dos etapas):**  Para no ralentizar la operación física, separamos la confirmación en dos etapas:  
4. **MDN Técnico (1.4 segundos):**  Confirmación de recepción y validación criptográfica para que el camión pueda salir.  
5. **MDN Fiscal (Latencia \< 1 hora):**  Confirmación del anclaje en el ledger de cumplimiento tras el procesamiento del rollup Merkle.

#### 6\. Apéndices de Implementación

##### Validación de Esquemas (3-Tier Funnel)

Implementamos un embudo de validación para proteger el ERP:

1. **Tier 1 (Estructural):**  Verificación de integridad del archivo y formato JSON.  
2. **Tier 2 (Schema):**  Validación estricta mediante  **JSON Schema**  (utilizando Ajv en Node.js) para asegurar campos obligatorios como GTIN, RIF y códigos postales.  
3. **Tier 3 (Lógica de Negocio):**  Verificación de existencia de SKUs y validez de permisos sanitarios contra la base de datos del ERP.

##### Manejo de Errores y Cuarentena (Data Steward UI)

Adoptamos el patrón  **"Partial Processing"** . Si una orden en un lote de 5,000 tiene un error (ej. código postal malformado), esa orden se desvía a una  **"Quarantine DLQ"** . A través de una  **Data Steward UI (Human-in-the-Loop)** , un operador puede corregir el dato puntualmente y ejecutar un "Save & Replay", reinyectando la transacción al flujo logístico sin detener el resto de la flota.Esta arquitectura transforma la integración B2B de un simple intercambio de datos en un ecosistema de confianza mutua, legalidad absoluta y trazabilidad farmacéutica total.  
