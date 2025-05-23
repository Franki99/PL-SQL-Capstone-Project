-- Connect as SYSDBA
CONNECT sys/Aguerokun10@localhost:1521/XE AS SYSDBA;

-- Define variables for customization
DEFINE group_name = "B"
DEFINE student_id = "25312"
DEFINE first_name = "Divanni"
DEFINE db_password = "Aguerokun10"

-- Create full database name
DEFINE db_name = "&group_name._&student_id._&first_name._IhuzoHR_DB"

-- Create the pluggable database
CREATE PLUGGABLE DATABASE &db_name
ADMIN USER &first_name IDENTIFIED BY &db_password
ROLES = (DBA)
DEFAULT TABLESPACE users
DATAFILE 'C:\APP\DIVANNI\PRODUCT\21C\ORADATA\&db_name\users01.dbf' SIZE 250M AUTOEXTEND ON
FILE_NAME_CONVERT = ('C:\APP\DIVANNI\PRODUCT\21C\ORADATA\XE\pdbseed\',
                     'C:\APP\DIVANNI\PRODUCT\21C\ORADATA\&db_name\');

-- Open the pluggable database
ALTER PLUGGABLE DATABASE &db_name OPEN;

-- Set the pluggable database to auto-start
ALTER PLUGGABLE DATABASE &db_name SAVE STATE;

-- Connect to the new pluggable database
ALTER SESSION SET CONTAINER = &db_name;

-- Grant privileges to the admin user
GRANT ALL PRIVILEGES TO &first_name;
GRANT UNLIMITED TABLESPACE TO &first_name;

-- Show the new PDB
SELECT name, open_mode FROM v$pdbs WHERE name = UPPER('&db_name');