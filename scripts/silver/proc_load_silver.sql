/*
=====================================================================================
Stored Procedure: Load Silver Layer

Script Purpose:
    This stored procedure loads data from the Bronze layer into the Silver layer.

    During this process, the procedure:
        - Cleans and standardizes raw data.
        - Converts data types.
        - Applies business rules.
        - Renames and normalizes categorical values.
        - Derives additional attributes.
        - Loads supporting tables required for the Gold layer.

    Run this procedure after successfully loading the Bronze layer.
=====================================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN

    DECLARE
        @start_time DATETIME,
        @end_time DATETIME,
        @batch_start_time DATETIME,
        @batch_end_time DATETIME;

    BEGIN TRY

        SET @batch_start_time = GETDATE();

        PRINT '=====================';
        PRINT 'Loading Silver Layer';
        PRINT '=====================';

        -- =========================================================================
        -- Load Sales Table
        -- =========================================================================

        SET @start_time = GETDATE();

        PRINT '>>> Truncating silver.vendas';
        TRUNCATE TABLE silver.vendas;

        PRINT '>>> Inserting data into silver.vendas';

        INSERT INTO silver.vendas (
            numero_pedido,
            nome_comercio,
            data,
            hora,
            total,
            produto,
            categoria,
            quantidade,
            preco_unitario,
            total_produto,
            identificacao_comprador,
            metodo_pagamento,
            ultimos_digitos_cartao,
            dispositivo_clover,
            codigo_serie,
            estado,
            es_pre_compra,
            data_evento,
            arquivo_fonte,
            data_ingestao
        )

        SELECT

            CAST(Numero_de_orden AS INT),

            CASE Nombre_del_comercio
                WHEN 'GB - Ilha 1' THEN 'Ilha 1'
                WHEN 'GB - Ilha 2' THEN 'Ilha 2'
                WHEN 'GB - Ilha 3' THEN 'Ilha 3'
                WHEN 'GB - Ilha 4' THEN 'Ilha 4'
                WHEN 'GB - HAMBURGUERIA' THEN 'Hamburgueria'
                WHEN 'GB - TERRAÇO' THEN 'Terraço'
                WHEN 'Grand Bares - Bahia Varanda' THEN 'Varanda'
                WHEN 'GB - KIDS' THEN 'Espaço Kids'
                ELSE TRIM(Nombre_del_comercio)
            END,

            CAST(Fecha AS DATE),

            CAST(Fecha AS TIME(0)),

            Total,

            CASE Producto
                WHEN 'Cerveja Itaipava Pilsen 350ml' THEN 'Itaipava Pilsen 350ml'
                WHEN 'Black Princess' THEN 'Black Princess 350ml'
                ELSE TRIM(Producto)
            END,

            TRIM(Categoria),

            Cantidad,

            Precio_Unitario,

            Total_Producto,

            CASE N_de_identificacion_del_Comprador
                WHEN '-' THEN NULL
                ELSE N_de_identificacion_del_Comprador
            END,

            REPLACE(TRIM(Metodo_de_pago), '· ', ''),

            CASE Ultimos_digitos_de_la_tarjeta
                WHEN ' ' THEN NULL
                ELSE Ultimos_digitos_de_la_tarjeta
            END,

            CASE
                WHEN LEN(Dispositivo_Clover) > 14
                    THEN SUBSTRING(Dispositivo_Clover,1,7)
                ELSE NULL
            END,

            CASE
                WHEN LEN(Dispositivo_Clover) < 15
                    THEN Dispositivo_Clover
                ELSE SUBSTRING(Dispositivo_Clover,18,LEN(Dispositivo_Clover))
            END,

            Estado,

            Es_pre_compra,

            CAST(
                STUFF(
                    STUFF(
                        SUBSTRING(arquivo_fonte,35,6),
                        3,0,'/'
                    ),
                    6,0,'/'
                ) AS DATE
            ),

            arquivo_fonte,

            data_ingestao

        FROM bronze.vendas b

        WHERE NOT EXISTS (
            SELECT 1
            FROM silver.vendas s
            WHERE s.arquivo_fonte = b.arquivo_fonte
        );

        SET @end_time = GETDATE();

        PRINT '>>> Load duration: '
            + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '-------------------------------------';


        -- =========================================================================
        -- Load Load-Control Table
        -- =========================================================================

        SET @start_time = GETDATE();

        PRINT '>>> Truncating silver.controle_carga';
        TRUNCATE TABLE silver.controle_carga;

        PRINT '>>> Inserting data into silver.controle_carga';

        INSERT INTO silver.controle_carga (
            arquivo,
            data_carga,
            linhas_carregadas
        )

        SELECT
            arquivo,
            data_carga,
            linhas_carregadas
        FROM bronze.controle_carga;

        SET @end_time = GETDATE();

        PRINT '>>> Load duration: '
            + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '-------------------------------------';


        -- =========================================================================
        -- Load Events Table
        -- =========================================================================

        SET @start_time = GETDATE();

        PRINT '>>> Truncating silver.eventos';
        TRUNCATE TABLE silver.eventos;

        PRINT '>>> Inserting data into silver.eventos';

        INSERT INTO silver.eventos (
            id_evento,
            data,
            horario_inicio,
            tipo_evento,
            evento,
            mandante,
            visitante,
            competicao,
            resultado
        )

        SELECT
            CAST(id_evento AS INT),
            CAST(data AS DATE),
            CAST(horario_inicio AS TIME(0)),
            tipo_evento,
            evento,
            mandante,
            visitante,
            competicao,
            resultado
        FROM bronze.eventos;

        SET @end_time = GETDATE();

        PRINT '>>> Load duration: '
            + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)
            + ' seconds';


        SET @batch_end_time = GETDATE();

        PRINT '=====================================';
        PRINT '>>> Silver layer loading is complete';
        PRINT '=====================================';
        PRINT '>>> Total load duration: '
            + CAST(DATEDIFF(second,@batch_start_time,@batch_end_time) AS NVARCHAR)
            + ' seconds';

    END TRY

    BEGIN CATCH

        PRINT 'An error occurred while loading the Silver layer.';
        PRINT 'Error message: ' + ERROR_MESSAGE();
        PRINT 'Error number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error state: ' + CAST(ERROR_STATE() AS NVARCHAR);

    END CATCH

END;
GO
