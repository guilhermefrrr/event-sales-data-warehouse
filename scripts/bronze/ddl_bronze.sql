/*
=====================================================================================
DDL Script: Create Bronze Tables

Script Purpose:
    This script creates all tables in the 'bronze' schema used in the data warehouse.

    The Bronze layer stores raw data ingested from the source systems with minimal
    transformations. It also includes supporting tables used during the ingestion
    process, such as the staging table, load control table and event reference table.

    Run this script before executing the Bronze loading procedure.
=====================================================================================
*/

-- ==========================================================================
-- STAGING TABLE
-- ==========================================================================

-- Temporary table used during the ingestion process.
-- Data is loaded here first through BULK INSERT before being moved
-- to the permanent Bronze table.

IF OBJECT_ID ('bronze.stg_vendas', 'U') IS NOT NULL
    DROP TABLE bronze.stg_vendas;
GO

CREATE TABLE bronze.stg_vendas (
    Numero_de_orden                     VARCHAR(50),
    Palco                               VARCHAR(50),
    Nombre_del_comercio                 VARCHAR(50),
    Evento                              VARCHAR(50),
    Fecha                               VARCHAR(50),
    Total                               VARCHAR(50),
    Producto                            VARCHAR(50),
    Categoria                           VARCHAR(50),
    Talle                               VARCHAR(50),
    Cantidad                            VARCHAR(50),
    Precio_Unitario                     VARCHAR(50),
    Total_Producto                      VARCHAR(50),
    Correo_del_Comprador                VARCHAR(100),
    Telefono_del_Comprador              VARCHAR(50),
    N_de_identificacion_del_Comprador   VARCHAR(50),
    Cantidad_restante_de_beneficio      VARCHAR(50),
    Metodo_de_pago                      VARCHAR(100),
    Ultimos_digitos_de_la_tarjeta       VARCHAR(50),
    Dispositivo_Clover                  VARCHAR(100),
    Delivery                            VARCHAR(50),
    Estado_de_facturacion               VARCHAR(50),
    Es_pre_compra                       VARCHAR(50),
    Estado                              VARCHAR(50)
);
GO

-- ==========================================================================
-- SALES TABLE
-- ==========================================================================

-- Permanent Bronze table.
-- Stores the raw data exactly as received from the source files, preserving
-- the original structure. Additional metadata columns are included to track
-- the source file and ingestion timestamp.

IF OBJECT_ID ('bronze.vendas', 'U') IS NOT NULL
    DROP TABLE bronze.vendas;
GO

CREATE TABLE bronze.vendas (
    Numero_de_orden                     VARCHAR(50),
    Palco                               VARCHAR(50),
    Nombre_del_comercio                 VARCHAR(50),
    Evento                              VARCHAR(50),
    Fecha                               VARCHAR(50),
    Total                               VARCHAR(50),
    Producto                            VARCHAR(50),
    Categoria                           VARCHAR(50),
    Talle                               VARCHAR(50),
    Cantidad                            VARCHAR(50),
    Precio_Unitario                     VARCHAR(50),
    Total_Producto                      VARCHAR(50),
    Correo_del_Comprador                VARCHAR(100),
    Telefono_del_Comprador              VARCHAR(50),
    N_de_identificacion_del_Comprador   VARCHAR(50),
    Cantidad_restante_de_beneficio      VARCHAR(50),
    Metodo_de_pago                      VARCHAR(100),
    Ultimos_digitos_de_la_tarjeta       VARCHAR(50),
    Dispositivo_Clover                  VARCHAR(100),
    Delivery                            VARCHAR(50),
    Estado_de_facturacion               VARCHAR(50),
    Estado                              VARCHAR(50),
    arquivo_fonte                       VARCHAR(500),
    data_ingestao                       DATETIME DEFAULT GETDATE()
);
GO

-- ==========================================================================
-- LOAD CONTROL TABLE
-- ==========================================================================

-- Stores information about every processed file.
-- Used to prevent duplicate loads and to monitor the ingestion process.

IF OBJECT_ID ('bronze.controle_carga', 'U') IS NOT NULL
    DROP TABLE bronze.controle_carga;
GO

CREATE TABLE bronze.controle_carga (
    arquivo             VARCHAR(500),
    data_carga          DATETIME DEFAULT GETDATE(),
    linhas_carregadas   INT
);
GO

-- ==========================================================================
-- EVENTS TABLE
-- ==========================================================================

-- Stores the event reference data used later in the Silver and Gold layers.
-- Loaded from a separate CSV file.

IF OBJECT_ID ('bronze.eventos', 'U') IS NOT NULL
    DROP TABLE bronze.eventos;
GO

CREATE TABLE bronze.eventos (
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
