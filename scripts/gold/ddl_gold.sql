/*
=====================================================================================
DDL Script: Create Gold Tables

Script Purpose:
    This script creates all tables in the 'gold' schema used in the Data Warehouse
    project.

    The Gold layer stores business-ready data organized according to a dimensional
    model. It contains dimension and fact tables designed to support analytical
    queries, dashboards and reporting.

    Run this script to (re)create the structure of all Gold tables.
=====================================================================================
*/

-- =============================================================================
-- MACHINE DIMENSION
-- Stores information about Clover devices used during sales transactions.
-- =============================================================================

IF OBJECT_ID ('gold.dim_maquinas', 'U') IS NOT NULL
    DROP TABLE gold.dim_maquinas;
GO

CREATE TABLE gold.dim_maquinas (
    dispositivo_id      INT PRIMARY KEY,
    codigo_serie        VARCHAR(50),
    dispositivo_clover  VARCHAR(50)
);
GO


-- =============================================================================
-- PRODUCT DIMENSION
-- Stores product and category information.
-- =============================================================================

IF OBJECT_ID ('gold.dim_produtos', 'U') IS NOT NULL
    DROP TABLE gold.dim_produtos;
GO

CREATE TABLE gold.dim_produtos (
    produto_id  INT PRIMARY KEY,
    produto     VARCHAR(50),
    categoria   VARCHAR(50)
);
GO


-- =============================================================================
-- EVENT DIMENSION
-- Stores event information used for sales analysis.
-- =============================================================================

IF OBJECT_ID ('gold.dim_evento', 'U') IS NOT NULL
    DROP TABLE gold.dim_evento;
GO

CREATE TABLE gold.dim_evento (
    evento_id       INT PRIMARY KEY,
    data            DATE,
    horario_inicio  TIME(0),
    tipo_evento     VARCHAR(100),
    evento          VARCHAR(100),
    mandante        VARCHAR(200),
    visitante       VARCHAR(200),
    competicao      VARCHAR(200),
    resultado       VARCHAR(100)
);
GO


-- =============================================================================
-- SALES FACT TABLE
-- Stores sales transactions linked to the dimension tables.
-- =============================================================================

IF OBJECT_ID ('gold.fact_vendas', 'U') IS NOT NULL
    DROP TABLE gold.fact_vendas;
GO

CREATE TABLE gold.fact_vendas (
    evento_id               INT,
    numero_pedido           INT,
    hora                    TIME(0),
    total                   DECIMAL(10,2),
    produto_id              INT,
    quantidade              INT,
    preco_unitario          DECIMAL(10,2),
    total_produto           DECIMAL(10,2),
    identificacao_comprador VARCHAR(100),
    metodo_pagamento        VARCHAR(100),
    ultimos_digitos_cartao  VARCHAR(50),
    dispositivo_id          INT,
    estado                  INT
);
GO


-- =============================================================================
-- PAYMENTS FACT TABLE
-- Stores payment information for each sales order, including split payments.
-- =============================================================================

IF OBJECT_ID ('gold.fact_pagamentos', 'U') IS NOT NULL
    DROP TABLE gold.fact_pagamentos;
GO

CREATE TABLE gold.fact_pagamentos (
    pagamento_id        INT PRIMARY KEY,
    numero_pedido       INT,
    metodo_pagamento    VARCHAR(100),
    bandeira            VARCHAR(50),
    valor_pagamento     DECIMAL(10,2)
);
GO
