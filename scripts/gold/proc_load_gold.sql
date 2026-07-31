/*
=====================================================================================
Stored Procedure: Load Gold Layer

Script Purpose:
    This stored procedure loads data from the Silver layer into the Gold layer.

    During this process, the procedure:
        - Builds dimension tables.
        - Populates fact tables.
        - Creates surrogate keys.
        - Applies business rules required for analytical reporting.

    The Gold layer follows a dimensional model (Star Schema) designed for
    dashboards, reporting and business analysis.

    Run this procedure after successfully loading the Silver layer.
=====================================================================================
*/

CREATE OR ALTER PROCEDURE gold.load_gold AS
BEGIN

    DECLARE
        @start_time DATETIME,
        @end_time DATETIME,
        @batch_start_time DATETIME,
        @batch_end_time DATETIME;

    BEGIN TRY

        SET @batch_start_time = GETDATE();

        PRINT '=====================';
        PRINT 'Loading Gold Layer';
        PRINT '=====================';

        -- =========================================================================
        -- Load Machine Dimension
        -- =========================================================================

        SET @start_time = GETDATE();

        PRINT '>>> Truncating gold.dim_maquinas';
        TRUNCATE TABLE gold.dim_maquinas;

        PRINT '>>> Inserting data into gold.dim_maquinas';

        INSERT INTO gold.dim_maquinas (
            dispositivo_id,
            codigo_serie,
            dispositivo_clover
        )

        SELECT
            ROW_NUMBER() OVER (ORDER BY codigo_serie),
            codigo_serie,
            dispositivo_clover
        FROM (

            SELECT
                codigo_serie,
                MAX(dispositivo_clover) AS dispositivo_clover
            FROM silver.vendas
            WHERE
                (metodo_pagamento IS NULL OR metodo_pagamento <> 'Cortesía')
                AND
                (nome_comercio IS NULL OR nome_comercio <> 'Varanda')
            GROUP BY codigo_serie

        ) maquinas;

        SET @end_time = GETDATE();

        PRINT '>>> Load duration: '
            + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '-------------------------------------';


        -- =========================================================================
        -- Load Product Dimension
        -- =========================================================================

        SET @start_time = GETDATE();

        PRINT '>>> Truncating gold.dim_produtos';
        TRUNCATE TABLE gold.dim_produtos;

        PRINT '>>> Inserting data into gold.dim_produtos';

        INSERT INTO gold.dim_produtos (
            produto_id,
            produto,
            categoria
        )

        SELECT
            ROW_NUMBER() OVER (ORDER BY produto),
            produto,
            categoria

        FROM (

            SELECT DISTINCT
                produto,
                categoria
            FROM silver.vendas
            WHERE
                metodo_pagamento <> 'Cortesía'
                AND nome_comercio <> 'Varanda'

        ) produtos;

        SET @end_time = GETDATE();

        PRINT '>>> Load duration: '
            + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '-------------------------------------';


        -- =========================================================================
        -- Load Event Dimension
        -- =========================================================================

        SET @start_time = GETDATE();

        PRINT '>>> Truncating gold.dim_evento';
        TRUNCATE TABLE gold.dim_evento;

        PRINT '>>> Inserting data into gold.dim_evento';

        INSERT INTO gold.dim_evento (
            evento_id,
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
            id_evento,
            data,
            horario_inicio,
            tipo_evento,
            evento,
            mandante,
            visitante,
            competicao,
            resultado

        FROM silver.eventos;

        SET @end_time = GETDATE();

        PRINT '>>> Load duration: '
            + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '-------------------------------------';


        -- =========================================================================
        -- Load Sales Fact Table
        -- =========================================================================

        SET @start_time = GETDATE();

        PRINT '>>> Truncating gold.fact_vendas';
        TRUNCATE TABLE gold.fact_vendas;

        PRINT '>>> Inserting data into gold.fact_vendas';

        INSERT INTO gold.fact_vendas (
            evento_id,
            numero_pedido,
            hora,
            total,
            produto_id,
            quantidade,
            preco_unitario,
            total_produto,
            identificacao_comprador,
            metodo_pagamento,
            ultimos_digitos_cartao,
            dispositivo_id,
            estado
        )

        SELECT
            e.evento_id,
            v.numero_pedido,
            v.hora,
            v.total,
            p.produto_id,
            v.quantidade,
            v.preco_unitario,
            v.total_produto,
            v.identificacao_comprador,
            v.metodo_pagamento,
            v.ultimos_digitos_cartao,
            m.dispositivo_id,
            v.estado

        FROM silver.vendas v

        LEFT JOIN gold.dim_evento e
            ON v.data_evento = e.data

        LEFT JOIN gold.dim_maquinas m
            ON v.codigo_serie = m.codigo_serie

        LEFT JOIN gold.dim_produtos p
            ON v.produto = p.produto
           AND v.categoria = p.categoria

        WHERE
            (v.metodo_pagamento IS NULL OR v.metodo_pagamento <> 'Cortesía')
            AND
            (v.nome_comercio IS NULL OR v.nome_comercio <> 'Varanda');

        SET @end_time = GETDATE();

        PRINT '>>> Load duration: '
            + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '-------------------------------------';


        -- =========================================================================
        -- Load Payment Fact Table
        -- =========================================================================

        SET @start_time = GETDATE();

        PRINT '>>> Truncating gold.fact_pagamentos';
        TRUNCATE TABLE gold.fact_pagamentos;

        PRINT '>>> Inserting data into gold.fact_pagamentos';

        WITH pedidos AS (

            SELECT
                *,
                ROW_NUMBER() OVER (
                    PARTITION BY numero_pedido
                    ORDER BY numero_pedido
                ) AS rn

            FROM silver.vendas

        )

        INSERT INTO gold.fact_pagamentos (
            pagamento_id,
            numero_pedido,
            metodo_pagamento,
            bandeira,
            valor_pagamento
        )

        SELECT

            ROW_NUMBER() OVER (
                ORDER BY numero_pedido, produto
            ),

            numero_pedido,

            CASE
                WHEN TRIM(s.value) LIKE '%Credi%' THEN 'Cartão de crédito'
                WHEN TRIM(s.value) LIKE '%Debi%' THEN 'Cartão de débito'
                WHEN TRIM(s.value) LIKE '%Amex%' THEN 'Cartão'
                WHEN TRIM(s.value) LIKE 'QR%' THEN 'Pix'
                WHEN TRIM(s.value) LIKE 'Efectivo%' THEN 'Dinheiro'
                ELSE TRIM(s.value)
            END,

            CASE
                WHEN TRIM(s.value) LIKE '%Visa%' THEN 'Visa'
                WHEN TRIM(s.value) LIKE '%Mastercard%' THEN 'Mastercard'
                WHEN TRIM(s.value) LIKE '%Amex%' THEN 'Amex'
                WHEN TRIM(s.value) LIKE '%Elo%' THEN 'Elo'
                ELSE TRIM(s.value)
            END,

            CASE
                WHEN TRIM(s.value) LIKE '%$%'
                THEN CAST(
                        REPLACE(
                            SUBSTRING(
                                s.value,
                                CHARINDEX('$', s.value),
                                LEN(s.value)
                            ),
                            '$',
                            ''
                        ) AS DECIMAL(10,2)
                    )
                ELSE CAST(total AS DECIMAL(10,2))
            END

        FROM pedidos p

        CROSS APPLY STRING_SPLIT(metodo_pagamento, ',') s

        WHERE
            rn = 1
            AND
            (metodo_pagamento IS NULL OR metodo_pagamento <> 'Cortesía')
            AND
            (nome_comercio IS NULL OR nome_comercio <> 'Varanda');

        SET @end_time = GETDATE();

        PRINT '>>> Load duration: '
            + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '-------------------------------------';


        SET @batch_end_time = GETDATE();

        PRINT '=====================================';
        PRINT '>>> Gold layer loading is complete';
        PRINT '=====================================';
        PRINT '>>> Total load duration: '
            + CAST(DATEDIFF(second,@batch_start_time,@batch_end_time) AS NVARCHAR)
            + ' seconds';

    END TRY

    BEGIN CATCH

        PRINT 'An error occurred while loading the Gold layer.';
        PRINT 'Error message: ' + ERROR_MESSAGE();
        PRINT 'Error number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error state: ' + CAST(ERROR_STATE() AS NVARCHAR);

    END CATCH

END;
GO
