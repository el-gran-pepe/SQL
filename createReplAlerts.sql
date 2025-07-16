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


--------------------------------------------------------------------------------------------

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

---------------------------------------------------------------------------------------------

--si quisieramos ver la cantidad de alertas configurados anteriormente
SELECT 
    a.name AS alerta,
    o.name AS operador,
    n.notification_method
FROM 
    msdb.dbo.sysalerts a
JOIN 
    msdb.dbo.sysnotifications n ON a.id = n.alert_id
JOIN 
    msdb.dbo.sysoperators o ON n.operator_id = o.id
WHERE 
    a.name LIKE 'Replica error%';

--resultado
/*
 _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
|alerta                                               |  operador       |1    |
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
|Replica error 1105 - Sin espacio en disco	          |  OperadorAdmin	|1    |
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
|Replica error 35206 - Comunicación fallida	          |  OperadorAdmin	|1    |
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
|Replica error 35250 - Secundaria desconectada	      |  OperadorAdmin	|1    |
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
|Replica error 35264 - Cambio de rol	              |  OperadorAdmin	|1    |
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
|Replica error 35273 - Fallo de sincronización	      |  OperadorAdmin	|1    |
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
|Replica error 41066 - Estado del grupo inválido      |  OperadorAdmin	|1    |
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
|Replica error 41131 - No sincronizada	              |  OperadorAdmin	|1    |
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
|Replica error 976 - Base de datos inaccesible	      |  OperadorAdmin	|1    |
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
*/

--------------------------------------------------------------------------------

--si quisieramos modificar el operador y que tenga diferentes destinos

EXEC msdb.dbo.sp_update_operator
    @name = N'OperadorAdmin',
    @enabled = 1,
    @email_address = N'mail1@dominio1; mail2@dominio2';

--------------------------------------------------------------------------------

--y si quisieramos eliminar el alerta de prueba

EXEC msdb.dbo.sp_delete_alert @name = N'Alerta de prueba por severidad 16';


-------------------------------------------------------------------------------

--Otras alertas configurables, recomendadas para replicas transaccionales

-- ALERTA: Error 14151 - Falla general en agente de replicación
EXEC msdb.dbo.sp_add_alert
    @name = N'Replica TX - Error 14151: Agente fallido',
    @message_id = 14151,
    @severity = 0,
    @enabled = 1,
    @notification_message = N'Falla detectada en un agente de replicación (error 14151)',
    @include_event_description_in = 1;
GO

-- ALERTA: Error 14152 - Conexión fallida
EXEC msdb.dbo.sp_add_alert
    @name = N'Replica TX - Error 14152: Conexión fallida',
    @message_id = 14152,
    @severity = 0,
    @enabled = 1,
    @notification_message = N'Error de conexión con distribuidor o suscriptor (error 14152)',
    @include_event_description_in = 1;
GO

-- ALERTA: Error 20574 - Suscripción inválida
EXEC msdb.dbo.sp_add_alert
    @name = N'Replica TX - Error 20574: Suscripción inválida',
    @message_id = 20574,
    @severity = 0,
    @enabled = 1,
    @notification_message = N'Suscripción eliminada o inválida (error 20574)',
    @include_event_description_in = 1;
GO

-- ALERTA: Error 20557 - Error en sincronización
EXEC msdb.dbo.sp_add_alert
    @name = N'Replica TX - Error 20557: Falla de sincronización',
    @message_id = 20557,
    @severity = 0,
    @enabled = 1,
    @notification_message = N'Error de sincronización entre publicador y suscriptor (error 20557)',
    @include_event_description_in = 1;
GO

-- ALERTA: Error 14040 - Agente no se está ejecutando
EXEC msdb.dbo.sp_add_alert
    @name = N'Replica TX - Error 14040: Agente detenido',
    @message_id = 14040,
    @severity = 0,
    @enabled = 1,
    @notification_message = N'El agente de replicación está detenido o no inició (error 14040)',
    @include_event_description_in = 1;
GO

-- ALERTA: Error 18854 - Error interno del agente
EXEC msdb.dbo.sp_add_alert
    @name = N'Replica TX - Error 18854: Error interno del agente',
    @message_id = 18854,
    @severity = 0,
    @enabled = 1,
    @notification_message = N'Error interno en el agente de distribución (error 18854)',
    @include_event_description_in = 1;
GO

-- ALERTA: Error 21074 - Falla en procedimiento replicado
EXEC msdb.dbo.sp_add_alert
    @name = N'Replica TX - Error 21074: Falla en procedimiento replicado',
    @message_id = 21074,
    @severity = 0,
    @enabled = 1,
    @notification_message = N'Error ejecutando procedimiento replicado en suscriptor (error 21074)',
    @include_event_description_in = 1;
GO

--Asociamos nuesto Operador a las alertas
DECLARE @alertName NVARCHAR(100);

DECLARE alerta_cursor CURSOR FOR
SELECT name FROM msdb.dbo.sysalerts
WHERE name LIKE 'Replica TX - Error%';

OPEN alerta_cursor;
FETCH NEXT FROM alerta_cursor INTO @alertName;

WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC msdb.dbo.sp_add_notification
        @alert_name = @alertName,
        @operator_name = N'OperadorAdmin',
        @notification_method = 1;

    FETCH NEXT FROM alerta_cursor INTO @alertName;
END

CLOSE alerta_cursor;
DEALLOCATE alerta_cursor;

-------------------------------------------------------------------------------------------------------

--Generar job que revise el estado de las replicas cada 5 minutos

--Creacion del job
EXEC msdb.dbo.sp_add_job
    @job_name = N'Monitoreo_Replicacion_TX',
    @enabled = 1,
    @description = N'Verifica si hay fallos o latencia crítica en la replicación transaccional';

--Agregamos el paso dentro del job para que verifique su funcionamiento
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'Monitoreo_Replicacion_TX',
    @step_name = N'VerificarEstadoReplicacion',
    @subsystem = N'TSQL',
    @database_name = N'distribution',
    @command = N'
IF EXISTS (
    SELECT 1
    FROM MSreplication_monitordata
    WHERE status != 2 OR delivery_latency > 300
)
BEGIN
    DECLARE @cuerpo NVARCHAR(MAX) = '''';

    SELECT @cuerpo = STRING_AGG(CONCAT(
        ''Publicador: '', publisher_db, 
        '' | Suscriptor: '', subscriber_db, 
        '' | Estado: '', 
            CASE status 
                WHEN 1 THEN ''Inactivo''
                WHEN 3 THEN ''Error''
                ELSE ''Desconocido''
            END,
        '' | Latencia: '', ISNULL(CONVERT(varchar, delivery_latency), ''NULL''), '' seg'',
        '' | Último sync: '', ISNULL(CONVERT(varchar, last_distsync_time, 120), ''NULL'')
    ), CHAR(13) + CHAR(10))
    FROM MSreplication_monitordata
    WHERE status != 2 OR delivery_latency > 300;

    EXEC msdb.dbo.sp_send_dbmail
        @profile_name = ''Repl Alerts'',
        @recipients = ''mail@dominio.com.ar; mail@dominio.com; ncorreos@dominio.com'',
        @subject = ''⚠️ Alerta: Problema en replicación transaccional'',
        @body = @cuerpo,
        @body_format = ''TEXT'';
END;
';

--agregamos una frecuencia de 5 minutos al job
EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'Cada5minutos',
    @enabled = 1,
    @freq_type = 4,  -- este parametro refiete a ser diariamente
    @freq_interval = 1,
    @freq_subday_type = 4,  -- definimos minutos
    @freq_subday_interval = 5, -- definimos 5 minutos
    @active_start_time = 0;  -- Desde 00:00
GO

--asociamos la frecuencia al job
EXEC msdb.dbo.sp_attach_schedule
    @job_name = N'Monitoreo_Replicacion_TX',
    @schedule_name = N'Cada5minutos';

