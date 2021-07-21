SET ANSI_NULLS ON;
GO


SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sp_what')
	EXEC ('CREATE PROC dbo.sp_what AS SELECT ''stub version, to be replaced''')
GO

/*******************************************************************************

Name:sp_what                                        

Purpose: Returns detailed memory grant information for active user processes                                                              
Input:@spid                                                             
Output:All sessions with active memory grant requests
Rules:Valid username or SPID                                                   

Created for: www.SavantSoftwareSolutions.com                                  
Created by: Mike Fuller                                               
Last Update:07/15/2021                                           

********************************************************************************/


ALTER PROCEDURE sp_what 
	   @loginame sysname = NULL 
AS
DECLARE  @spidlow	int,
		 @spidhigh	int,
		 @spid		int,
		 @sid		varbinary(85)




if (@loginame is not NULL)
BEGIN
	if (@loginame like '[0-9]%')	-- is numeric
	BEGIN
		SELECT @spid = convert(int, @loginame)
	SELECT 
		s.host_name, 
		s.program_name, 
		DB_NAME(er.database_id) AS DatabaseName,
		s.client_interface_name, 
		s.login_name, 
		s.nt_domain,   
		s.nt_user_name, 
		s.original_login_name,
		er.session_id,
		SUBSTRING(st.text, (er.statement_start_offset/2)+1,
		((CASE er.statement_end_offset
		WHEN -1 THEN DATALENGTH(st.text)
		ELSE er.statement_end_offset
		END - er.statement_start_offset)/2) + 1) AS statement_text,
		st.text AS OuterSQLText,
		er.wait_type, er.wait_time,
		mg.requested_memory_kb/1024 AS requested_memory_mb,
		mg.granted_memory_kb/1024 AS granted_memory_mb,
			--addtional @memcounters
		mg.required_memory_kb/1024 as required_memory_mb,
		mg.used_memory_kb/1024  as used_memory_mb,
		mg.max_used_memory_kb/1024 max_used_memory_mb,
		mg.dop,
		CAST(mg.query_cost AS NUMERIC(13,2)) as QueryCost,
		CONVERT(XML, qp.query_plan) AS query_plan 
	FROM 
		sys.dm_exec_requests er 
	CROSS APPLY 
		sys.dm_exec_sql_text(er.sql_handle) st
	CROSS APPLY 
		sys.dm_exec_text_query_plan(er.plan_handle, er.statement_start_offset, er.statement_end_offset) qp
	INNER JOIN 
		sys.dm_exec_query_memory_grants mg 
	ON 
		er.session_id = mg.session_id
	AND     er.request_id=md.request_id
	INNER join 
		sys.dm_exec_connections c  
	ON 
		mg.session_id=c.session_id
	INNER JOIN 
		sys.dm_exec_sessions s     
	ON 
		c.session_id = s.session_id 
	WHERE 
		s.session_id=@spid
	ORDER BY mg.requested_memory_kb DESC
	END
	ELSE
	BEGIN
	SELECT @sid = suser_sid(@loginame)
	IF (@sid is null)
	BEGIN
		RAISERROR(15007,-1,-1,@loginame)
		return (1)
	END
	SELECT 
		s.host_name, 
		s.program_name, 
		DB_NAME(er.database_id) AS DatabaseName,
		s.client_interface_name, 
		s.login_name, 
		s.nt_domain,   
		s.nt_user_name, 
		s.original_login_name,
		er.session_id,
		SUBSTRING(st.text, (er.statement_start_offset/2)+1,
		((CASE er.statement_end_offset
		WHEN -1 THEN DATALENGTH(st.text)
		ELSE er.statement_end_offset
		END - er.statement_start_offset)/2) + 1) AS statement_text,
		st.text AS OuterSQLText,
		er.wait_type, er.wait_time,
		mg.requested_memory_kb/1024 AS requested_memory_mb,
		mg.granted_memory_kb/1024 AS granted_memory_mb,
			--addtional @memcounters
		mg.required_memory_kb/1024 as required_memory_mb,
		mg.used_memory_kb/1024  as used_memory_mb,
		mg.max_used_memory_kb/1024 max_used_memory_mb,
		mg.dop,
		CAST(mg.query_cost AS NUMERIC(13,2)) as QueryCost,
		CONVERT(XML, qp.query_plan) AS query_plan 
	FROM 
		sys.dm_exec_requests er  
	CROSS APPLY 
		sys.dm_exec_sql_text(er.sql_handle) st
	CROSS APPLY 
		sys.dm_exec_text_query_plan(er.plan_handle, er.statement_start_offset, er.statement_end_offset) qp
	INNER JOIN 
		sys.dm_exec_query_memory_grants mg 
	ON 
		er.session_id = mg.session_id
	INNER join 
		sys.dm_exec_connections c 
	ON 
		mg.session_id=c.session_id
        AND     er.request_id=md.request_id
	INNER JOIN 
		sys.dm_exec_sessions s    
	ON 
		c.session_id = s.session_id 
	WHERE 
		s.session_id=@spid
	ORDER BY mg.requested_memory_kb DESC
	END
	RETURN (0)
END
--otherwise return all active sessions with memory grants
SELECT 
	s.host_name, 
	s.program_name, 
	DB_NAME(er.database_id) AS DatabaseName,
	s.client_interface_name, 
	s.login_name, 
	s.nt_domain,   
	s.nt_user_name, 
	s.original_login_name,
	er.session_id,
	SUBSTRING(st.text, (er.statement_start_offset/2)+1,
	((CASE er.statement_end_offset
	WHEN -1 THEN DATALENGTH(st.text)
	ELSE er.statement_end_offset
	END - er.statement_start_offset)/2) + 1) AS statement_text,
	st.text AS OuterSQLText,
	er.wait_type, er.wait_time,
	mg.requested_memory_kb/1024 as requested_memory_mb,
	mg.granted_memory_kb/1024  as granted_memory_mb,
	--addtional @memcounters
	mg.required_memory_kb/1024 as required_memory_mb,
	mg.used_memory_kb/1024  as used_memory_mb,
	mg.max_used_memory_kb/1024 max_used_memory_mb,
	mg.dop,
	CAST(mg.query_cost AS NUMERIC(13,2)) as QueryCost,
	CONVERT(XML, qp.query_plan) AS query_plan 
FROM 
	sys.dm_exec_requests er 
CROSS APPLY 
	sys.dm_exec_sql_text(er.sql_handle) st
CROSS APPLY 
	sys.dm_exec_text_query_plan(er.plan_handle, er.statement_start_offset, er.statement_end_offset) qp
INNER JOIN 
	sys.dm_exec_query_memory_grants mg 
ON 
	er.session_id = mg.session_id
AND     er.request_id=md.request_id
INNER join 
	sys.dm_exec_connections c 
ON 
	mg.session_id=c.session_id
INNER JOIN 
	sys.dm_exec_sessions s    
ON 
	c.session_id = s.session_id 

ORDER BY mg.requested_memory_kb DESC
