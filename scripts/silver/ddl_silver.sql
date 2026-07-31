/*
=====================================================================================
DDL Script: Create Silver Tables

Script Purpose:
    This script creates all tables in the 'silver' schema used in the Data Warehouse
    project.

    The Silver layer stores cleaned, standardized and transformed data from the
    Bronze layer. During this stage, data types are converted, business rules are
    applied, unnecessary columns are removed and additional attributes are derived
    to support dimensional modeling in the Gold layer.

    Run this script to (re)create the structure of all Silver tables.
=====================================================================================
*/

-- =============================================================================
-- SALES TABLE
-- Stores cleaned and standardized sales transactions.
-- =============================================================================

IF OBJECT_ID ('silver.vendas', 'U') IS NOT NULL
    DROP TABLE silver.vendas;
GO

CREATE TABLE silver.vendas (
    numero_pedido               INT,
    nome_comercio               VARCHAR(50),
    data                        DATE,
    hora                        TIME(0),
    total                       DECIMAL(10,2),
    produto                     VARCHAR(50),
    categoria                   VARCHAR(50),
    quantidade                  INT,
    preco_unitario              DECIMAL(10,2),
    total_produto               DECIMAL(10,2),
    identificacao_comprador     VARCHAR(100),
    metodo_pagamento            VARCHAR(500),
    ultimos_digitos_cartao      VARCHAR(50),
    dispositivo_clover          VARCHAR(50),
    codigo_serie                VARCHAR(50),
    estado                      INT,
    es_pre_compra               VARCHAR(50),
    data_evento                 DATE,
    arquivo_fonte               VARCHAR(1000),
    data_ingestao               DATETIME2
);
GO


-- =============================================================================
-- LOAD CONTROL TABLE
-- Stores metadata about processed source files.
-- =============================================================================

IF OBJECT_ID ('silver.controle_carga', 'U') IS NOT NULL
    DROP TABLE silver.controle_carga;
GO

CREATE TABLE silver.controle_carga (
    arquivo             VARCHAR(500),
    data_carga          DATETIME,
    linhas_carregadas   INT
);
GO


-- =============================================================================
-- EVENTS TABLE
-- Stores event information used to enrich sales data during the ETL process.
-- =============================================================================

IF OBJECT_ID ('silver.eventos', 'U') IS NOT NULL
    DROP TABLE silver.eventos;
GO

CREATE TABLE silver.eventos (
    id_evento       VARCHAR(10),
    data            VARCHAR(20),
    horario_inicio  VARCHAR(20),
    tipo_evento     VARCHAR(100),
    evento          VARCHAR(100),
    mandante        VARCHAR(200),
    visitante       VARCHAR(200),
    competicao      VARCHAR(200),
    resultado       VARCHAR(100)
);
GO
