-- Connect as SYSDBA
CONNECT sys/Aguerokun10@localhost:1521/XE AS SYSDBA;

-- Make sure Enterprise Manager is running
EXEC DBMS_XDB.SETLISTENERLOCALACCESS(FALSE);

-- First go to the root container (CDB$ROOT)
ALTER SESSION SET CONTAINER = CDB$ROOT;

-- Unlock DBSNMP user at the root level
ALTER USER DBSNMP ACCOUNT UNLOCK;

-- Set password for DBSNMP user at all container levels
ALTER USER DBSNMP IDENTIFIED BY dbsnmp CONTAINER=ALL;

-- Now go to your PDB
ALTER SESSION SET CONTAINER = B_25312_Divanni_IhuzoHR_DB;

-- Try using a different port if 5500 is already in use
EXEC DBMS_XDB_CONFIG.SETHTTPSPORT(5501);

-- Output connection string for OEM
SELECT 'https://' || SYS_CONTEXT('USERENV', 'SERVER_HOST') || ':5501/em' AS OEM_URL FROM DUAL;