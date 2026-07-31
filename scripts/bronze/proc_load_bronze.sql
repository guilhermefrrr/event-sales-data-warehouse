/*
=====================================================================================
Stored Procedure: bronze.load_bronze

Script Purpose:
    This stored procedure loads raw sales data into the Bronze layer.

    The procedure performs the following tasks:
        1. Checks whether the source file has already been processed.
        2. Loads the source file into the staging table using BULK INSERT.
        3. Moves the data from the staging table to the Bronze sales table.
        4. Registers the processed file in the load control table.
        5. Reloads the events reference table.

Parameters:
    @file_path
        Full path of the source file to be loaded.

Usage Example:
    EXEC bronze.load_bronze 'C:\Temp\gb\reporte_limpo_010426.csv';
=====================================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze
    @file_path VARCHAR(500)
AS
BEGIN

    DECLARE
        @start_time DATETIME,
        @end_time DATETIME,
        @batch_start_time DATETIME,
        @batch_end_time DATETIME,
        @rows_loaded INT;

    BEGIN TRY

        SET @batch_start_time = GETDATE();

        PRINT '=====================';
        PRINT 'Loading bronze layer';
        PRINT '=====================';

        -------------------------------------------------------------------------
        -- Check whether the source file has already been loaded
        -------------------------------------------------------------------------

        IF EXISTS (
            SELECT 1
            FROM bronze.controle_carga
            WHERE arquivo = @file_path
        )
        BEGIN
            PRINT 'File already loaded previously: ' + @file_path;
            RETURN;
        END;

        -------------------------------------------------------------------------
        -- Load source file into the staging table
        -------------------------------------------------------------------------

        SET @start_time = GETDATE();

        PRINT '>>> Truncating staging table';
        TRUNCATE TABLE bronze.stg_vendas;

        PRINT '>>> Inserting data into bronze.stg_vendas';

        DECLARE @load_vendas NVARCHAR(MAX) = '
            BULK INSERT bronze.stg_vendas
            FROM ''' + @file_path + '''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ''|'',
                ROWTERMINATOR = ''0x0a'',
                CODEPAGE = ''65001''
            )';

        EXEC sp_executesql @load_vendas;

        -------------------------------------------------------------------------
        -- Move data from staging to the Bronze sales table
        -------------------------------------------------------------------------

        PRINT '>>> Moving data from staging to bronze.vendas';

        INSERT INTO bronze.vendas (
            Numero_de_orden,
            Palco,
            Nombre_del_comercio,
            Evento,
            Fecha,
            Total,
            Producto,
            Categoria,
            Talle,
            Cantidad,
            Precio_Unitario,
            Total_Producto,
            Correo_del_Comprador,
            Telefono_del_Comprador,
            N_de_identificacion_del_Comprador,
            Cantidad_restante_de_beneficio,
            Metodo_de_pago,
            Ultimos_digitos_de_la_tarjeta,
            Dispositivo_Clover,
            Delivery,
            Estado_de_facturacion,
            Estado,
            arquivo_fonte,
            Es_pre_compra
        )
        SELECT
            Numero_de_orden,
            Palco,
            Nombre_del_comercio,
            Evento,
            Fecha,
            Total,
            Producto,
            Categoria,
            Talle,
            Cantidad,
            Precio_Unitario,
            Total_Producto,
            Correo_del_Comprador,
            Telefono_del_Comprador,
            N_de_identificacion_del_Comprador,
            Cantidad_restante_de_beneficio,
            Metodo_de_pago,
            Ultimos_digitos_de_la_tarjeta,
            Dispositivo_Clover,
            Delivery,
            Estado_de_facturacion,
            Estado,
            @file_path,
            Es_pre_compra
        FROM bronze.stg_vendas;

        SET @rows_loaded = @@ROWCOUNT;

        SET @end_time = GETDATE();

        PRINT '>>> Load duration: '
            + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '-------------------------------------';

        -------------------------------------------------------------------------
        -- Register the processed file in the load control table
        -------------------------------------------------------------------------

        SET @start_time = GETDATE();

        PRINT '>>> Inserting data into bronze.controle_carga';

        INSERT INTO bronze.controle_carga (
            arquivo,
            linhas_carregadas
        )
        VALUES (
            @file_path,
            @rows_loaded
        );

        PRINT 'File updated successfully: ' + @file_path;

        SET @end_time = GETDATE();

        PRINT '>>> Load duration: '
            + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '-------------------------------------';

        -------------------------------------------------------------------------
        -- Reload the events reference table
        -------------------------------------------------------------------------

        SET @start_time = GETDATE();

        PRINT '>>> Truncating bronze.eventos';

        TRUNCATE TABLE bronze.eventos;

        PRINT '>>> Inserting data into bronze.eventos';

        BULK INSERT bronze.eventos
        FROM 'C:\Temp\gb\eventos.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            CODEPAGE = '65001'
        );

        SET @end_time = GETDATE();

        PRINT '>>> Load duration: '
            + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        -------------------------------------------------------------------------
        -- End of load process
        -------------------------------------------------------------------------

        SET @batch_end_time = GETDATE();

        PRINT '=====================================';
        PRINT '>>> Bronze layer loading is complete';
        PRINT '=====================================';
        PRINT '>>> Total load duration: '
            + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR)
            + ' seconds';

    END TRY

    BEGIN CATCH

        PRINT 'An error occurred while loading the bronze layer';

        PRINT 'Error message: ' + ERROR_MESSAGE();
        PRINT 'Error number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error state: ' + CAST(ERROR_STATE() AS NVARCHAR);

    END CATCH

END;
GO
