# Data Dictionary

## Overview

This document describes the tables created throughout the Data Warehouse project.

The warehouse follows a **Bronze → Silver → Gold** architecture:

- **Bronze:** raw data ingestion.
- **Silver:** cleaned and standardized data.
- **Gold:** dimensional model for analytics.

---

# Bronze Layer

## bronze.stg_vendas

Temporary staging table used during the ingestion process.

| Column | Data Type | Description |
|---------|-----------|-------------|
| Numero_de_orden | VARCHAR(50) | Order number from source system |
| Palco | VARCHAR(50) | Venue area |
| Nombre_del_comercio | VARCHAR(50) | Point of sale |
| Evento | VARCHAR(50) | Event description |
| Fecha | VARCHAR(50) | Transaction timestamp |
| Total | VARCHAR(50) | Order total |
| Producto | VARCHAR(50) | Product name |
| Categoria | VARCHAR(50) | Product category |
| Talle | VARCHAR(50) | Product size |
| Cantidad | VARCHAR(50) | Quantity sold |
| Precio_Unitario | VARCHAR(50) | Unit price |
| Total_Producto | VARCHAR(50) | Product total |
| Correo_del_Comprador | VARCHAR(100) | Customer email |
| Telefono_del_Comprador | VARCHAR(50) | Customer phone |
| N_de_identificacion_del_Comprador | VARCHAR(50) | Customer identifier |
| Cantidad_restante_de_beneficio | VARCHAR(50) | Remaining customer benefit |
| Metodo_de_pago | VARCHAR(100) | Payment method |
| Ultimos_digitos_de_la_tarjeta | VARCHAR(50) | Last card digits |
| Dispositivo_Clover | VARCHAR(100) | POS device information |
| Delivery | VARCHAR(50) | Delivery indicator |
| Estado_de_facturacion | VARCHAR(50) | Billing status |
| Es_pre_compra | VARCHAR(50) | Pre-sale flag |
| Estado | VARCHAR(50) | Transaction status |

---

## bronze.vendas

Stores raw sales data after ingestion.

| Column | Data Type | Description |
|---------|-----------|-------------|
| All source columns | Various | Original data imported from source files |
| arquivo_fonte | VARCHAR(500) | Source filename |
| data_ingestao | DATETIME | Data ingestion timestamp |

---

## bronze.controle_carga

Tracks loaded files.

| Column | Data Type | Description |
|---------|-----------|-------------|
| arquivo | VARCHAR(500) | Imported filename |
| data_carga | DATETIME | Load timestamp |
| linhas_carregadas | INT | Number of imported rows |

---

## bronze.eventos

Stores event metadata.

| Column | Data Type | Description |
|---------|-----------|-------------|
| id_evento | VARCHAR(10) | Event identifier |
| data | VARCHAR(20) | Event date |
| horario_inicio | VARCHAR(20) | Event start time |
| tipo_evento | VARCHAR(100) | Event type |
| evento | VARCHAR(100) | Event description |
| mandante | VARCHAR(200) | Home team or organizer |
| visitante | VARCHAR(200) | Away team |
| competicao | VARCHAR(200) | Competition |
| resultado | VARCHAR(100) | Final score |

---

# Silver Layer

## silver.vendas

Cleaned and standardized sales table.

| Column | Data Type | Description |
|---------|-----------|-------------|
| numero_pedido | INT | Order number |
| nome_comercio | VARCHAR(50) | Standardized point of sale |
| data | DATE | Transaction date |
| hora | TIME | Transaction time |
| total | DECIMAL(10,2) | Order total |
| produto | VARCHAR(50) | Standardized product |
| categoria | VARCHAR(50) | Product category |
| quantidade | INT | Quantity sold |
| preco_unitario | DECIMAL(10,2) | Unit price |
| total_produto | DECIMAL(10,2) | Product total |
| identificacao_comprador | VARCHAR(100) | Customer identifier |
| metodo_pagamento | VARCHAR(500) | Payment method(s) |
| ultimos_digitos_cartao | VARCHAR(50) | Last card digits |
| dispositivo_clover | VARCHAR(50) | POS device |
| codigo_serie | VARCHAR(50) | Device serial number |
| estado | INT | Transaction status |
| es_pre_compra | VARCHAR(50) | Pre-sale flag |
| data_evento | DATE | Event date extracted from filename |
| arquivo_fonte | VARCHAR(1000) | Source filename |
| data_ingestao | DATETIME2 | Ingestion timestamp |

---

## silver.controle_carga

Copy of Bronze load control table.

| Column | Data Type | Description |
|---------|-----------|-------------|
| arquivo | VARCHAR(500) | Imported filename |
| data_carga | DATETIME | Load timestamp |
| linhas_carregadas | INT | Number of loaded rows |

---

## silver.eventos

Cleaned event dimension source.

| Column | Data Type | Description |
|---------|-----------|-------------|
| id_evento | INT | Event identifier |
| data | DATE | Event date |
| horario_inicio | TIME | Start time |
| tipo_evento | VARCHAR(100) | Event type |
| evento | VARCHAR(100) | Event description |
| mandante | VARCHAR(200) | Home team |
| visitante | VARCHAR(200) | Away team |
| competicao | VARCHAR(200) | Competition |
| resultado | VARCHAR(100) | Match result |

---

# Gold Layer

## gold.dim_maquinas

Machine dimension.

| Column | Data Type | Description |
|---------|-----------|-------------|
| dispositivo_id | INT | Surrogate key |
| codigo_serie | VARCHAR(50) | Device serial number |
| dispositivo_clover | VARCHAR(50) | POS device |

---

## gold.dim_produtos

Product dimension.

| Column | Data Type | Description |
|---------|-----------|-------------|
| produto_id | INT | Surrogate key |
| produto | VARCHAR(50) | Product name |
| categoria | VARCHAR(50) | Product category |

---

## gold.dim_evento

Event dimension.

| Column | Data Type | Description |
|---------|-----------|-------------|
| evento_id | INT | Event identifier |
| data | DATE | Event date |
| horario_inicio | TIME | Start time |
| tipo_evento | VARCHAR(100) | Event type |
| evento | VARCHAR(100) | Event description |
| mandante | VARCHAR(200) | Home team |
| visitante | VARCHAR(200) | Away team |
| competicao | VARCHAR(200) | Competition |
| resultado | VARCHAR(100) | Final score |

---

## gold.fact_vendas

Sales fact table.

| Column | Data Type | Description |
|---------|-----------|-------------|
| evento_id | INT | Event foreign key |
| numero_pedido | INT | Order number |
| hora | TIME | Transaction time |
| total | DECIMAL(10,2) | Order total |
| produto_id | INT | Product foreign key |
| quantidade | INT | Quantity sold |
| preco_unitario | DECIMAL(10,2) | Unit price |
| total_produto | DECIMAL(10,2) | Product total |
| identificacao_comprador | VARCHAR(100) | Customer identifier |
| metodo_pagamento | VARCHAR(100) | Payment method |
| ultimos_digitos_cartao | VARCHAR(50) | Last card digits |
| dispositivo_id | INT | Machine foreign key |
| estado | INT | Transaction status |

---

## gold.fact_pagamentos

Payment fact table.

| Column | Data Type | Description |
|---------|-----------|-------------|
| pagamento_id | INT | Surrogate key |
| numero_pedido | INT | Order number |
| metodo_pagamento | VARCHAR(100) | Standardized payment method |
| bandeira | VARCHAR(50) | Card brand |
| valor_pagamento | DECIMAL(10,2) | Payment amount |
