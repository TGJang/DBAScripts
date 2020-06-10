-- 파일 : Active Session Monitoring
-- 주요 칼럼 : WAIT_EVENT1(대기이벤트),  LCE1(last_call_et), SECONDS_IN_WAIT1(seconds_in_wait) 
-- SQL_ID           >> 현재 수행 중인 MAIN SQL_ID
-- LAST_CALL_ET     >> 현재 수행 중인 MAIN SQL_ID
-- SQL_EXEC_START   >> 현재 수행 중인 SQL 시작 시간 ( PROCEDURE 나 FUNCTION 등일 경우, 각각의 STATEMENT 에 수행 시점마다 UPDATE 됨 )
-- seconds_in_wait   >> STATE='WAITING' 일 경우, 현재 시점까지 대기 시간 // 대기 이벤트별로 변함 
SELECT -- Monitoring CLT
        s.inst_id as Inst 
       ,substr(s.username,1,12 )                   as  username1  
       ,s.type
       ,to_char(s.sid)||','||to_char(s.serial# )  as  sid1
       ,status
       ,state       -- WAITING - Session is currently waiting, WAITED UNKNOWN TIME ( TIMED_STATISTICS = FALSE ), WAITED SHORT TIME ( LAST WAIT < 1/100 S) , WAITED KNOWN TIME ( LAST WAIT -> WAIT_TIME)       
       -- ,WAIT_TIME  -- 34603470
       ,s.sql_id as sql_id2  -- add
       ,sql_exec_start
       ,sysdate as chk_dt        
       ,last_call_et as lce1      
       -- , ROUND( (( sysdate - nvl(sql_exec_start,SYSDATE ))*24*60*60) -1 ) AS "CUR_SQL_DURA(S)"      -- kill -9 264394
       ,substr(s.event,1,50)                      as wait_event1          
       ,s.seconds_in_wait                         as   S_in_wait 
       ,round(s.WAIT_TIME_MICRO/1000) as wait_time_ms
       -- ,substr(status,1,1)                        as  status1
--       ,decode(s.blocking_session,null,'',substr(s.blocking_session_status,1,13)||'('||s.blocking_instance||')'||(s.blocking_session) ) as blocking2 -- add  EPSADM.EPS_TIF_IF/-TABLE TTIADM.TED_EDI_CSTMS_RCV_LOG_DTL/-TABLE
--       ,S.WAIT_TIME_MICRO
--       ,S.TIME_SINCE_LAST_WAIT_MICRO   9vnkfzrw91sf6
--       ,s.seconds_in_wait                         as   S_in_wait2 -- add  77zzvsbys3vms
--       ,last_call_et                              as lce2   -- add
--       ,substr(s.event,1,50)                      as wait_event2  -- add
       
   --    ,substr(s.sql_trace,1,2)||'/'||substr(s.sql_trace_waits,1,1)||'/'||substr(s.sql_trace_binds,1,1) as sql_trace1 
       ,s.machine                                 as machine1
       ,trunc(p.pga_alloc_mem/1024/1024)          as  pga1
       ,substr(s.module,1,30) as module
       ,substr(s.action,1,  30)         as actions 
   -- ,substr(decode(sign(lengthb(s.program)-13),1,substr(s.program,1,13)||'..',s.program),1,4) as pgm1 LOGON1
       ,s.program    
       ,decode(s.blocking_session,null,'',substr(s.blocking_session_status,1,13)||'('||s.blocking_instance||')'||(s.blocking_session) ) as blocking1
     -- ,s.wait_time                               as wait_timedktoty
       --,round(s.WAIT_TIME_MICRO/1000) as wait_time_ms
      -- ,s.seconds_in_wait                         as   S_in_wait 
      -- ,last_call_et                              as lce1
      -- ,substr(s.event,1,50)                      as wait_event1   
       --, P1TEXT, P1, P2TEXT, P2, P3TEXT, P3      
       ,s.sql_id
       ,s.SQL_HASH_VALUE
       ,s.SQL_CHILD_NUMBER
       ,nvl(trim((select substr(sql_text,1,70) from v$sql sq where sq.sql_id  = s.sql_id and rownum= 1 )), ' --------------------------')                                as sql_text1       
       ,s.osuser                                  as osuser1
       ,s.terminal                                as user_info1
       ,to_char(logon_time,'yyyymmdd HH24:MI:SS') as logon1
       ,s.process                                 as cpid1
       ,p.spid                                    as spid1
       ,ROUND(p.PGA_USED_MEM/1024/1024) AS PGA_USED_MEM_MB, ROUND(p.PGA_ALLOC_MEM/1024/1024) AS PGA_ALLOC_MEM_MB, ROUND(p.PGA_FREEABLE_MEM/1024/1024) AS PGA_FREEABLE_MEM_MB, ROUND(p.PGA_MAX_MEM/1024/1024) AS PGA_MAX_MEM_MB       
       ,'kill -9 '||p.spid                        as kill1      
--       ,'alter system kill session '||''''||s.sid||','||s.serial#||''''||' immediate; ' as kill2
--       ,  'alter system kill session '''||sid||','||s.serial#||''';' AS KILL_NORMAL
       ,  'alter system kill session '''||sid||','||s.serial#||''' IMMEDIATE;' AS KILL_IMMEIDATE
       ,  'alter system kill session '''||sid||','||s.serial#||',@'||P.INST_ID||''';' AS KILL_IMMEIDATE
       ,  'alter system cancel sql '''||sid||','||s.serial#||',@'||P.INST_ID||''';' AS CANCEL_SQL_19C
       ,  ( SELECT OWNER||'.'||OBJECT_NAME||'/'||SUBOBJECT_NAME||'-'||OBJECT_TYPE FROM DBA_OBJECTS O WHERE O.OBJECT_ID = S.ROW_WAIT_OBJ# ) AS ROW_WAIT_OBJ_INFO
       ,  ( SELECT OWNER||'.'||OBJECT_NAME||'/'||SUBOBJECT_NAME||'-'||OBJECT_TYPE FROM DBA_OBJECTS O WHERE O.OBJECT_ID = S.PLSQL_ENTRY_OBJECT_ID  ) as pl_sql_object_info
       , 'Current : '||TO_CHAR(SQL_EXEC_START,'HH24MISS')||' - '||SQL_ID||', Before : '||TO_CHAR(PREV_EXEC_START,'HH24MISS')||' - '||PREV_SQL_ID AS C_B_SQL
       --, ' inst_id : '||s.inst_id||','||to_char(s.sid)||','||to_char(s.serial# )||', OS : '||p.spid as db_info
       --, 'EXEC DBMS_SYSTEM.SET_SQL_TRACE_IN_SESSION('||s.sid||','||s.serial#||', true );' as other_sql_trace 
--       , ' Sess Info :  1) inst_id : '||s.inst_id||', 2)sid, serial# : '||to_char(s.sid)||','||to_char(s.serial# )||', 3)OS : '||p.spid
--       ||chr(10)||' Trace File : '||p.tracefile
--       ||chr(10)||' Trace On : '||'EXEC DBMS_SYSTEM.SET_SQL_TRACE_IN_SESSION('||s.sid||','||s.serial#||', true );' 
--       ||chr(10)||' Trace Off : '||'EXEC DBMS_SYSTEM.SET_SQL_TRACE_IN_SESSION('||s.sid||','||s.serial#||', false );' as other_sql_trace        
FROM    gv$session         s                             
       ,gv$process         p    
WHERE  s.paddr   = p.addr
AND    s.inst_id = p.inst_id
AND    s.status  = 'ACTIVE'  -- Active Session Only direct path read   
--AND    s.event  not in ('queue messages','pipe get','jobq slave wait','Streams AQ: waiting for messages in the queue') 
AND    s.username is not null   -- User type Only = Exclude BACKGROUND 1sa1frcuqatxf
AND    type ='USER'   
order by  lce1 desc,  BLOCKING1 asc ,WAIT_EVENT1 desc, username1 desc ;  