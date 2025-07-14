--como requisito previo debemos tener un Profile y una Database Mail configurado

--creamos un operador
EXEC msdb.dbo.sp_add_operator
    @name = N'OperadorAdmin',
    @email_address = N'correo@dominio.com';

--email_address refiere a los destinatarios


--creamos un alerta para cada error
-- Error 35206 - Red no disponible entre réplicas
EXEC msdb.dbo.sp_add_alert
    @name = N'Replica error 35206 - Comunicación fallida',
    @message_id = 35206,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 60,
    @include_event_description_in = 1,
    @notification_message = N'Error 35206: Comunicación con la réplica fallida.',
    @job_id = '00000000-0000-0000-0000-000000000000';
GO

-- Error 35250 - Desconexión de réplica secundaria
EXEC msdb.dbo.sp_add_alert
    @name = N'Replica error 35250 - Secundaria desconectada',
    @message_id = 35250,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 60,
    @include_event_description_in = 1,
    @notification_message = N'Error 35250: Una réplica secundaria está desconectada.',
    @job_id = '00000000-0000-0000-0000-000000000000';
GO

-- Error 35264 - Cambio inesperado de rol
EXEC msdb.dbo.sp_add_alert
    @name = N'Replica error 35264 - Cambio de rol',
    @message_id = 35264,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 60,
    @include_event_description_in = 1,
    @notification_message = N'Error 35264: Se detectó un cambio de rol inesperado.',
    @job_id = '00000000-0000-0000-0000-000000000000';
GO

-- Error 35273 - Falla de sincronización
EXEC msdb.dbo.sp_add_alert
    @name = N'Replica error 35273 - Fallo de sincronización',
    @message_id = 35273,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 60,
    @include_event_description_in = 1,
    @notification_message = N'Error 35273: La base no se sincroniza correctamente.',
    @job_id = '00000000-0000-0000-0000-000000000000';
GO

-- Error 41066 - Grupo de disponibilidad en estado inválido
EXEC msdb.dbo.sp_add_alert
    @name = N'Replica error 41066 - Estado del grupo inválido',
    @message_id = 41066,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 60,
    @include_event_description_in = 1,
    @notification_message = N'Error 41066: El grupo de disponibilidad está en estado inválido.',
    @job_id = '00000000-0000-0000-0000-000000000000';
GO

-- Error 41131 - Base de datos fuera de sincronización
EXEC msdb.dbo.sp_add_alert
    @name = N'Replica error 41131 - No sincronizada',
    @message_id = 41131,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 60,
    @include_event_description_in = 1,
    @notification_message = N'Error 41131: Base de datos fuera de sincronización.',
    @job_id = '00000000-0000-0000-0000-000000000000';
GO

-- Error 976 - La base no está disponible
EXEC msdb.dbo.sp_add_alert
    @name = N'Replica error 976 - Base de datos inaccesible',
    @message_id = 976,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 60,
    @include_event_description_in = 1,
    @notification_message = N'Error 976: La base de datos no está accesible.',
    @job_id = '00000000-0000-0000-0000-000000000000';
GO

-- Error 1105 - Espacio insuficiente
EXEC msdb.dbo.sp_add_alert
    @name = N'Replica error 1105 - Sin espacio en disco',
    @message_id = 1105,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 300,
    @include_event_description_in = 1,
    @notification_message = N'Error 1105: Sin espacio en disco.',
    @job_id = '00000000-0000-0000-0000-000000000000';
GO


--las asignamos a nuestro operador
DECLARE @Errores TABLE (NombreAlerta NVARCHAR(100));
INSERT INTO @Errores (NombreAlerta) VALUES
(N'Replica error 35206 - Comunicación fallida'),
(N'Replica error 35250 - Secundaria desconectada'),
(N'Replica error 35264 - Cambio de rol'),
(N'Replica error 35273 - Fallo de sincronización'),
(N'Replica error 41066 - Estado del grupo inválido'),
(N'Replica error 41131 - No sincronizada'),
(N'Replica error 976 - Base de datos inaccesible'),
(N'Replica error 1105 - Sin espacio en disco');

DECLARE @nombreAlerta NVARCHAR(100);
DECLARE alerta_cursor CURSOR FOR SELECT NombreAlerta FROM @Errores;
OPEN alerta_cursor;
FETCH NEXT FROM alerta_cursor INTO @nombreAlerta;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC msdb.dbo.sp_add_notification
        @alert_name = @nombreAlerta,
        @operator_name = N'OperadorAdmin',
        @notification_method = 1; -- Email

    FETCH NEXT FROM alerta_cursor INTO @nombreAlerta;
END
CLOSE alerta_cursor;
DEALLOCATE alerta_cursor;


-------------------------------------------------------------------------------

--si quisieramos crear un alerta de prueba para poder probar el funcionamiento del trigger

EXEC msdb.dbo.sp_add_alert
    @name = N'Alerta de prueba por severidad 16',
    @severity = 16,
    @enabled = 1,
    @include_event_description_in = 1,
    @notification_message = N'Prueba de alerta por error de severidad 16';
GO

EXEC msdb.dbo.sp_add_notification
    @alert_name = N'Alerta de prueba por severidad 16',
    @operator_name = N'OperadorAdmin',
    @notification_method = 1;
GO

RAISERROR('Simulación de error de severidad 16 para prueba de alerta n2', 16, 1) WITH LOG;
