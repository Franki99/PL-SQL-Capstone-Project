-- Enable DBMS_OUTPUT
SET SERVEROUTPUT ON SIZE 1000000;

-- Create a procedure to simulate different days for testing
CREATE OR REPLACE PROCEDURE test_day_restriction (
    p_day VARCHAR2, -- 'WEEKDAY', 'WEEKEND', 'HOLIDAY'
    p_test_name VARCHAR2
) AS
    v_original_day VARCHAR2(3) := TO_CHAR(SYSDATE, 'DY');
    v_success BOOLEAN := FALSE;
    
    -- Create a local function to override the package function for testing
    FUNCTION test_is_restricted_time RETURN BOOLEAN IS
    BEGIN
        IF p_day = 'WEEKDAY' THEN
            RETURN TRUE;  -- Simulate weekday restriction
        ELSIF p_day = 'HOLIDAY' THEN
            RETURN TRUE;  -- Simulate holiday restriction
        ELSE -- WEEKEND
            RETURN FALSE; -- Simulate weekend allowance
        END IF;
    END;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== Test: ' || p_test_name || ' =====');
    DBMS_OUTPUT.PUT_LINE('Original day: ' || v_original_day);
    DBMS_OUTPUT.PUT_LINE('Simulating a ' || p_day);
    
    -- Create or replace a temporary package for testing
    EXECUTE IMMEDIATE '
    CREATE OR REPLACE PACKAGE test_hr_audit_pkg AS
        FUNCTION is_restricted_time RETURN BOOLEAN;
    END test_hr_audit_pkg;
    ';
    
    EXECUTE IMMEDIATE '
    CREATE OR REPLACE PACKAGE BODY test_hr_audit_pkg AS
        FUNCTION is_restricted_time RETURN BOOLEAN IS
        BEGIN
            RETURN ' || CASE WHEN p_day IN ('WEEKDAY', 'HOLIDAY') THEN 'TRUE' ELSE 'FALSE' END || ';
        END is_restricted_time;
    END test_hr_audit_pkg;
    ';
    
    -- Test operations
    BEGIN
        -- Attempt to insert an applicant
        DBMS_OUTPUT.PUT_LINE('Attempting to insert an applicant...');
        
        -- For test purposes, we'll directly check our test function first
        IF test_is_restricted_time() THEN
            DBMS_OUTPUT.PUT_LINE('Would be DENIED in ' || p_day || ' condition');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Would be ALLOWED in ' || p_day || ' condition');
        END IF;
        
        -- Try the real operation (will use the actual hr_audit_pkg)
        BEGIN
            INSERT INTO applicants (
                applicant_id, first_name, last_name, email, phone, highest_degree, years_of_experience
            ) VALUES (
                applicants_seq.NEXTVAL, 'Test', 'User', 'test_user@example.com', 
                '+250789123456', 'Bachelor', 2
            );
            
            v_success := TRUE;
            DBMS_OUTPUT.PUT_LINE('INSERT successful.');
        EXCEPTION
            WHEN OTHERS THEN
                v_success := FALSE;
                DBMS_OUTPUT.PUT_LINE('INSERT failed: ' || SQLERRM);
        END;
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    
    BEGIN
        -- Attempt to update an existing applicant
        DBMS_OUTPUT.PUT_LINE('Attempting to update an applicant...');
        
        -- For test purposes, check test function
        IF test_is_restricted_time() THEN
            DBMS_OUTPUT.PUT_LINE('Would be DENIED in ' || p_day || ' condition');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Would be ALLOWED in ' || p_day || ' condition');
        END IF;
        
        -- Try the real operation
        BEGIN
            UPDATE applicants
            SET phone = '+250789999999'
            WHERE applicant_id = (
                SELECT MIN(applicant_id) FROM applicants
            );
            
            v_success := TRUE;
            DBMS_OUTPUT.PUT_LINE('UPDATE successful.');
        EXCEPTION
            WHEN OTHERS THEN
                v_success := FALSE;
                DBMS_OUTPUT.PUT_LINE('UPDATE failed: ' || SQLERRM);
        END;
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Drop the temporary test package
    EXECUTE IMMEDIATE 'DROP PACKAGE test_hr_audit_pkg';
    
    DBMS_OUTPUT.PUT_LINE('Test completed.');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
END test_day_restriction;
/

-- Test weekday restriction
BEGIN
    test_day_restriction('WEEKDAY', 'Weekday Restriction');
END;
/

-- Test weekend allowance
BEGIN
    test_day_restriction('WEEKEND', 'Weekend Allowance');
END;
/

-- Test holiday restriction
BEGIN
    test_day_restriction('HOLIDAY', 'Holiday Restriction');
END;
/

-- Test the Audit Package functionality
DECLARE
    v_cursor SYS_REFCURSOR;
    v_audit_id NUMBER;
    v_username VARCHAR2(50);
    v_operation_type VARCHAR2(20);
    v_table_name VARCHAR2(50);
    v_record_id VARCHAR2(50);
    v_operation_date TIMESTAMP;
    v_operation_status VARCHAR2(20);
    v_denial_reason VARCHAR2(255);
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== Testing HR Audit Package =====');
    
    -- Test 1: Get denied operations
    DBMS_OUTPUT.PUT_LINE('Recent denied operations:');
    v_cursor := hr_audit_pkg.get_denied_operations(
        p_start_date => SYSDATE - 1,
        p_end_date => SYSDATE + 1
    );
    
    LOOP
        FETCH v_cursor INTO 
            v_audit_id, 
            v_username, 
            v_operation_type, 
            v_table_name, 
            v_record_id, 
            v_operation_date, 
            v_denial_reason;
            
        EXIT WHEN v_cursor%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE(
            'ID: ' || v_audit_id || 
            ', User: ' || v_username || 
            ', Operation: ' || v_operation_type || 
            ', Table: ' || v_table_name || 
            ', Status: DENIED' ||
            ', Reason: ' || v_denial_reason
        );
    END LOOP;
    
    CLOSE v_cursor;
    
    -- Test 2: Manually log an audit entry
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Testing manual audit logging:');
    
    hr_audit_pkg.log_audit(
        p_username => USER,
        p_operation_type => 'SECURITY_CHECK',
        p_table_name => 'SYSTEM',
        p_record_id => NULL,
        p_operation_status => 'ALLOWED',
        p_denial_reason => NULL
    );
    
    DBMS_OUTPUT.PUT_LINE('Manual audit entry logged successfully.');
    
    -- Test 3: Check current time restriction
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Testing time restriction check:');
    
    IF hr_audit_pkg.is_restricted_time() THEN
        DBMS_OUTPUT.PUT_LINE('Current time is RESTRICTED for database operations.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Current time is ALLOWED for database operations.');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
END;
/

-- Test the Compound Trigger
DECLARE
    v_success BOOLEAN := FALSE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== Testing Compound Trigger =====');
    
    -- Test updating salary information
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Attempting to update salary information...');
        
        UPDATE job_positions
        SET min_salary = min_salary * 1.05, -- 5% increase
            max_salary = max_salary * 1.05
        WHERE job_id = (
            SELECT MIN(job_id) FROM job_positions
        );
        
        v_success := TRUE;
        DBMS_OUTPUT.PUT_LINE('Salary update successful.');
    EXCEPTION
        WHEN OTHERS THEN
            v_success := FALSE;
            DBMS_OUTPUT.PUT_LINE('Salary update failed: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Query audit logs for salary changes
    DBMS_OUTPUT.PUT_LINE('Recent salary change audit logs:');
    
    FOR rec IN (
        SELECT audit_id, username, operation_type, table_name, 
               record_id, old_value, new_value, operation_status, denial_reason
        FROM hr_audit_log
        WHERE operation_type = 'SALARY_UPDATE'
          AND operation_date > SYSDATE - 1
        ORDER BY operation_date DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            'ID: ' || rec.audit_id || 
            ', User: ' || rec.username || 
            ', Operation: ' || rec.operation_type || 
            ', Status: ' || rec.operation_status ||
            ', Old Value: ' || rec.old_value ||
            ', New Value: ' || rec.new_value
        );
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
END;
/

-- Clean up test procedure
DROP PROCEDURE test_day_restriction;