-- 06_audit_package.sql
-- Connect to your database
CONNECT Divanni/Aguerokun10@localhost:1521/B_25312_Divanni_IhuzoHR_DB

-- Create Audit Package Specification
CREATE OR REPLACE PACKAGE hr_audit_pkg AS
    -- Constants
    c_max_value_length CONSTANT NUMBER := 4000;
    
    -- Types
    TYPE audit_record IS RECORD (
        username VARCHAR2(50),
        operation_type VARCHAR2(20),
        table_name VARCHAR2(50),
        record_id VARCHAR2(50),
        column_name VARCHAR2(50),
        old_value VARCHAR2(4000),
        new_value VARCHAR2(4000),
        operation_date TIMESTAMP,
        operation_status VARCHAR2(20),
        denial_reason VARCHAR2(255)
    );
    
    -- Public Procedures and Functions
    
    -- Log an audit record
    PROCEDURE log_audit (
        p_username IN VARCHAR2,
        p_operation_type IN VARCHAR2,
        p_table_name IN VARCHAR2,
        p_record_id IN VARCHAR2 DEFAULT NULL,
        p_column_name IN VARCHAR2 DEFAULT NULL,
        p_old_value IN VARCHAR2 DEFAULT NULL,
        p_new_value IN VARCHAR2 DEFAULT NULL,
        p_operation_status IN VARCHAR2 DEFAULT 'ALLOWED',
        p_denial_reason IN VARCHAR2 DEFAULT NULL
    );
    
    -- Log a detailed change
    PROCEDURE log_data_change (
        p_table_name IN VARCHAR2,
        p_record_id IN VARCHAR2,
        p_column_name IN VARCHAR2,
        p_old_value IN VARCHAR2,
        p_new_value IN VARCHAR2
    );
    
    -- Check if current time is restricted
    FUNCTION is_restricted_time RETURN BOOLEAN;
    
    -- Get audit records for a specific table
    FUNCTION get_table_audit_logs (
        p_table_name IN VARCHAR2,
        p_start_date IN DATE DEFAULT TRUNC(SYSDATE) - 30,
        p_end_date IN DATE DEFAULT SYSDATE + 1
    ) RETURN SYS_REFCURSOR;
    
    -- Get denied operations report
    FUNCTION get_denied_operations (
        p_start_date IN DATE DEFAULT TRUNC(SYSDATE) - 30,
        p_end_date IN DATE DEFAULT SYSDATE + 1
    ) RETURN SYS_REFCURSOR;
    
    -- Get user activity report
    FUNCTION get_user_activity (
        p_username IN VARCHAR2,
        p_start_date IN DATE DEFAULT TRUNC(SYSDATE) - 30,
        p_end_date IN DATE DEFAULT SYSDATE + 1
    ) RETURN SYS_REFCURSOR;
    
END hr_audit_pkg;
/

-- Create Audit Package Body
CREATE OR REPLACE PACKAGE BODY hr_audit_pkg AS

    -- Private helper procedures and functions
    
    -- Truncate value to maximum length
    FUNCTION truncate_value (p_value IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        IF p_value IS NULL THEN
            RETURN NULL;
        ELSIF LENGTH(p_value) <= c_max_value_length THEN
            RETURN p_value;
        ELSE
            RETURN SUBSTR(p_value, 1, c_max_value_length - 3) || '...';
        END IF;
    END truncate_value;
    
    -- Format value for display
    FUNCTION format_value (
        p_value IN VARCHAR2,
        p_data_type IN VARCHAR2 DEFAULT 'VARCHAR2'
    ) RETURN VARCHAR2 IS
    BEGIN
        IF p_value IS NULL THEN
            RETURN 'NULL';
        ELSIF p_data_type = 'DATE' THEN
            RETURN 'TO_DATE(''' || p_value || ''', ''YYYY-MM-DD HH24:MI:SS'')';
        ELSIF p_data_type IN ('NUMBER', 'INTEGER', 'DECIMAL') THEN
            RETURN p_value;
        ELSE
            RETURN '''' || REPLACE(p_value, '''', '''''') || '''';
        END IF;
    END format_value;
    
    -- Public procedures and functions
    
    -- Log an audit record
    PROCEDURE log_audit (
        p_username IN VARCHAR2,
        p_operation_type IN VARCHAR2,
        p_table_name IN VARCHAR2,
        p_record_id IN VARCHAR2 DEFAULT NULL,
        p_column_name IN VARCHAR2 DEFAULT NULL,
        p_old_value IN VARCHAR2 DEFAULT NULL,
        p_new_value IN VARCHAR2 DEFAULT NULL,
        p_operation_status IN VARCHAR2 DEFAULT 'ALLOWED',
        p_denial_reason IN VARCHAR2 DEFAULT NULL
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        -- Variables to hold truncated values
        v_old_value VARCHAR2(4000);
        v_new_value VARCHAR2(4000);
    BEGIN
        -- Truncate values before using them in SQL
        IF p_old_value IS NULL THEN
            v_old_value := NULL;
        ELSIF LENGTH(p_old_value) <= c_max_value_length THEN
            v_old_value := p_old_value;
        ELSE
            v_old_value := SUBSTR(p_old_value, 1, c_max_value_length - 3) || '...';
        END IF;
        
        IF p_new_value IS NULL THEN
            v_new_value := NULL;
        ELSIF LENGTH(p_new_value) <= c_max_value_length THEN
            v_new_value := p_new_value;
        ELSE
            v_new_value := SUBSTR(p_new_value, 1, c_max_value_length - 3) || '...';
        END IF;
        
        INSERT INTO hr_audit_log (
            audit_id,
            username,
            operation_type,
            table_name,
            record_id,
            column_name,
            old_value,
            new_value,
            operation_date,
            operation_status,
            denial_reason,
            client_info,
            ip_address,
            os_user
        ) VALUES (
            hr_audit_seq.NEXTVAL,
            NVL(p_username, USER),
            p_operation_type,
            p_table_name,
            p_record_id,
            p_column_name,
            v_old_value,
            v_new_value,
            SYSTIMESTAMP,
            p_operation_status,
            p_denial_reason,
            SYS_CONTEXT('USERENV', 'CLIENT_INFO'),
            SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
            SYS_CONTEXT('USERENV', 'OS_USER')
        );
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            -- Silent exception to prevent main transaction from failing
            NULL;
    END log_audit;
    
    -- Log a detailed change
    PROCEDURE log_data_change (
        p_table_name IN VARCHAR2,
        p_record_id IN VARCHAR2,
        p_column_name IN VARCHAR2,
        p_old_value IN VARCHAR2,
        p_new_value IN VARCHAR2
    ) IS
    BEGIN
        log_audit(
            p_username => USER,
            p_operation_type => 'UPDATE',
            p_table_name => p_table_name,
            p_record_id => p_record_id,
            p_column_name => p_column_name,
            p_old_value => p_old_value,
            p_new_value => p_new_value,
            p_operation_status => 'ALLOWED'
        );
    END log_data_change;
    
    -- Check if current time is restricted
    FUNCTION is_restricted_time RETURN BOOLEAN IS
        v_current_day VARCHAR2(3);
        v_is_holiday NUMBER;
        v_month_start DATE;
        v_month_end DATE;
    BEGIN
        -- Get current day of week (MON, TUE, WED, THU, FRI, SAT, SUN)
        v_current_day := TO_CHAR(SYSDATE, 'DY');
        
        -- Calculate next month's date range
        v_month_start := TRUNC(ADD_MONTHS(SYSDATE, 1), 'MM');
        v_month_end := LAST_DAY(v_month_start);
        
        -- Check if today is a public holiday for the upcoming month
        SELECT COUNT(*) INTO v_is_holiday
        FROM public_holidays
        WHERE holiday_date = TRUNC(SYSDATE)
          AND holiday_date BETWEEN v_month_start AND v_month_end;
        
        -- Return TRUE if it's a weekday (Mon-Fri) OR it's a holiday in the upcoming month
        RETURN (v_current_day IN ('MON', 'TUE', 'WED', 'THU', 'FRI') OR v_is_holiday > 0);
    END is_restricted_time;
    
    -- Get audit records for a specific table
    FUNCTION get_table_audit_logs (
        p_table_name IN VARCHAR2,
        p_start_date IN DATE DEFAULT TRUNC(SYSDATE) - 30,
        p_end_date IN DATE DEFAULT SYSDATE + 1
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT 
                audit_id,
                username,
                operation_type,
                table_name,
                record_id,
                column_name,
                old_value,
                new_value,
                operation_date,
                operation_status,
                denial_reason
            FROM 
                hr_audit_log
            WHERE 
                table_name = UPPER(p_table_name) AND
                operation_date BETWEEN p_start_date AND p_end_date
            ORDER BY 
                operation_date DESC;
                
        RETURN v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            IF v_cursor%ISOPEN THEN
                CLOSE v_cursor;
            END IF;
            
            -- Return empty cursor
            OPEN v_cursor FOR
                SELECT 
                    NULL AS audit_id,
                    NULL AS username,
                    NULL AS operation_type,
                    NULL AS table_name,
                    NULL AS record_id,
                    NULL AS column_name,
                    NULL AS old_value,
                    NULL AS new_value,
                    NULL AS operation_date,
                    NULL AS operation_status,
                    NULL AS denial_reason
                FROM 
                    dual
                WHERE 
                    1 = 0;
                    
            RETURN v_cursor;
    END get_table_audit_logs;
    
    -- Get denied operations report
    FUNCTION get_denied_operations (
        p_start_date IN DATE DEFAULT TRUNC(SYSDATE) - 30,
        p_end_date IN DATE DEFAULT SYSDATE + 1
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT 
                audit_id,
                username,
                operation_type,
                table_name,
                record_id,
                operation_date,
                denial_reason
            FROM 
                hr_audit_log
            WHERE 
                operation_status = 'DENIED' AND
                operation_date BETWEEN p_start_date AND p_end_date
            ORDER BY 
                operation_date DESC;
                
        RETURN v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            IF v_cursor%ISOPEN THEN
                CLOSE v_cursor;
            END IF;
            
            -- Return empty cursor
            OPEN v_cursor FOR
                SELECT 
                    NULL AS audit_id,
                    NULL AS username,
                    NULL AS operation_type,
                    NULL AS table_name,
                    NULL AS record_id,
                    NULL AS operation_date,
                    NULL AS denial_reason
                FROM 
                    dual
                WHERE 
                    1 = 0;
                    
            RETURN v_cursor;
    END get_denied_operations;
    
    -- Get user activity report
    FUNCTION get_user_activity (
        p_username IN VARCHAR2,
        p_start_date IN DATE DEFAULT TRUNC(SYSDATE) - 30,
        p_end_date IN DATE DEFAULT SYSDATE + 1
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT 
                username,
                operation_type,
                table_name,
                COUNT(*) AS operation_count,
                COUNT(CASE WHEN operation_status = 'ALLOWED' THEN 1 END) AS allowed_count,
                COUNT(CASE WHEN operation_status = 'DENIED' THEN 1 END) AS denied_count,
                MIN(operation_date) AS first_operation,
                MAX(operation_date) AS last_operation
            FROM 
                hr_audit_log
            WHERE 
                username = p_username AND
                operation_date BETWEEN p_start_date AND p_end_date
            GROUP BY 
                username, operation_type, table_name
            ORDER BY 
                table_name, operation_type;
                
        RETURN v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            IF v_cursor%ISOPEN THEN
                CLOSE v_cursor;
            END IF;
            
            -- Return empty cursor
            OPEN v_cursor FOR
                SELECT 
                    NULL AS username,
                    NULL AS operation_type,
                    NULL AS table_name,
                    NULL AS operation_count,
                    NULL AS allowed_count,
                    NULL AS denied_count,
                    NULL AS first_operation,
                    NULL AS last_operation
                FROM 
                    dual
                WHERE 
                    1 = 0;
                    
            RETURN v_cursor;
    END get_user_activity;
    
END hr_audit_pkg;
/