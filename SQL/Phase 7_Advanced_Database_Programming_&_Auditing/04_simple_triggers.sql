-- Helper function to check if current time is within restricted hours
CREATE OR REPLACE FUNCTION is_restricted_time
RETURN BOOLEAN IS
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
END;
/

-- Create Simple Triggers for each critical HR table

-- 1. Applicants Table Trigger
CREATE OR REPLACE TRIGGER trg_restrict_applicants
BEFORE INSERT OR UPDATE OR DELETE ON applicants
FOR EACH ROW
DECLARE
    v_restricted BOOLEAN;
    v_operation VARCHAR2(10);
    v_record_id VARCHAR2(50);
    v_reason VARCHAR2(255);
BEGIN
    -- Determine operation type
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_record_id := :NEW.applicant_id;
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_record_id := :OLD.applicant_id;
    ELSE -- DELETING
        v_operation := 'DELETE';
        v_record_id := :OLD.applicant_id;
    END IF;
    
    -- Check if operation is restricted
    v_restricted := is_restricted_time();
    
    IF v_restricted THEN
        -- Determine specific reason
        IF TO_CHAR(SYSDATE, 'DY') IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
            v_reason := 'Operation restricted during weekdays (Monday-Friday)';
        ELSE
            v_reason := 'Operation restricted during public holidays';
        END IF;
        
        -- Log the denied operation
        INSERT INTO hr_audit_log (
            audit_id,
            username,
            operation_type,
            table_name,
            record_id,
            operation_date,
            operation_status,
            denial_reason,
            client_info,
            os_user
        ) VALUES (
            hr_audit_seq.NEXTVAL,
            USER,
            v_operation,
            'APPLICANTS',
            v_record_id,
            SYSTIMESTAMP,
            'DENIED',
            v_reason,
            SYS_CONTEXT('USERENV', 'CLIENT_INFO'),
            SYS_CONTEXT('USERENV', 'OS_USER')
        );
        
        -- Raise error to prevent the operation
        RAISE_APPLICATION_ERROR(-20001, v_reason);
    END IF;
END;
/

-- 2. Applications Table Trigger
CREATE OR REPLACE TRIGGER trg_restrict_applications
BEFORE INSERT OR UPDATE OR DELETE ON applications
FOR EACH ROW
DECLARE
    v_restricted BOOLEAN;
    v_operation VARCHAR2(10);
    v_record_id VARCHAR2(50);
    v_reason VARCHAR2(255);
BEGIN
    -- Determine operation type
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_record_id := :NEW.application_id;
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_record_id := :OLD.application_id;
    ELSE -- DELETING
        v_operation := 'DELETE';
        v_record_id := :OLD.application_id;
    END IF;
    
    -- Check if operation is restricted
    v_restricted := is_restricted_time();
    
    IF v_restricted THEN
        -- Determine specific reason
        IF TO_CHAR(SYSDATE, 'DY') IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
            v_reason := 'Operation restricted during weekdays (Monday-Friday)';
        ELSE
            v_reason := 'Operation restricted during public holidays';
        END IF;
        
        -- Log the denied operation
        INSERT INTO hr_audit_log (
            audit_id,
            username,
            operation_type,
            table_name,
            record_id,
            operation_date,
            operation_status,
            denial_reason,
            client_info,
            os_user
        ) VALUES (
            hr_audit_seq.NEXTVAL,
            USER,
            v_operation,
            'APPLICATIONS',
            v_record_id,
            SYSTIMESTAMP,
            'DENIED',
            v_reason,
            SYS_CONTEXT('USERENV', 'CLIENT_INFO'),
            SYS_CONTEXT('USERENV', 'OS_USER')
        );
        
        -- Raise error to prevent the operation
        RAISE_APPLICATION_ERROR(-20001, v_reason);
    END IF;
END;
/

-- 3. Employees Table Trigger
CREATE OR REPLACE TRIGGER trg_restrict_employees
BEFORE INSERT OR UPDATE OR DELETE ON employees
FOR EACH ROW
DECLARE
    v_restricted BOOLEAN;
    v_operation VARCHAR2(10);
    v_record_id VARCHAR2(50);
    v_reason VARCHAR2(255);
BEGIN
    -- Determine operation type
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_record_id := :NEW.employee_id;
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_record_id := :OLD.employee_id;
    ELSE -- DELETING
        v_operation := 'DELETE';
        v_record_id := :OLD.employee_id;
    END IF;
    
    -- Check if operation is restricted
    v_restricted := is_restricted_time();
    
    IF v_restricted THEN
        -- Determine specific reason
        IF TO_CHAR(SYSDATE, 'DY') IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
            v_reason := 'Operation restricted during weekdays (Monday-Friday)';
        ELSE
            v_reason := 'Operation restricted during public holidays';
        END IF;
        
        -- Log the denied operation
        INSERT INTO hr_audit_log (
            audit_id,
            username,
            operation_type,
            table_name,
            record_id,
            operation_date,
            operation_status,
            denial_reason,
            client_info,
            os_user
        ) VALUES (
            hr_audit_seq.NEXTVAL,
            USER,
            v_operation,
            'EMPLOYEES',
            v_record_id,
            SYSTIMESTAMP,
            'DENIED',
            v_reason,
            SYS_CONTEXT('USERENV', 'CLIENT_INFO'),
            SYS_CONTEXT('USERENV', 'OS_USER')
        );
        
        -- Raise error to prevent the operation
        RAISE_APPLICATION_ERROR(-20001, v_reason);
    END IF;
END;
/

-- 4. Job Offers Table Trigger
CREATE OR REPLACE TRIGGER trg_restrict_job_offers
BEFORE INSERT OR UPDATE OR DELETE ON job_offers
FOR EACH ROW
DECLARE
    v_restricted BOOLEAN;
    v_operation VARCHAR2(10);
    v_record_id VARCHAR2(50);
    v_reason VARCHAR2(255);
BEGIN
    -- Determine operation type
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_record_id := :NEW.offer_id;
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_record_id := :OLD.offer_id;
    ELSE -- DELETING
        v_operation := 'DELETE';
        v_record_id := :OLD.offer_id;
    END IF;
    
    -- Check if operation is restricted
    v_restricted := is_restricted_time();
    
    IF v_restricted THEN
        -- Determine specific reason
        IF TO_CHAR(SYSDATE, 'DY') IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
            v_reason := 'Operation restricted during weekdays (Monday-Friday)';
        ELSE
            v_reason := 'Operation restricted during public holidays';
        END IF;
        
        -- Log the denied operation
        INSERT INTO hr_audit_log (
            audit_id,
            username,
            operation_type,
            table_name,
            record_id,
            operation_date,
            operation_status,
            denial_reason,
            client_info,
            os_user
        ) VALUES (
            hr_audit_seq.NEXTVAL,
            USER,
            v_operation,
            'JOB_OFFERS',
            v_record_id,
            SYSTIMESTAMP,
            'DENIED',
            v_reason,
            SYS_CONTEXT('USERENV', 'CLIENT_INFO'),
            SYS_CONTEXT('USERENV', 'OS_USER')
        );
        
        -- Raise error to prevent the operation
        RAISE_APPLICATION_ERROR(-20001, v_reason);
    END IF;
END;
/

-- 5. Users Table Trigger
CREATE OR REPLACE TRIGGER trg_restrict_users
BEFORE INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW
DECLARE
    v_restricted BOOLEAN;
    v_operation VARCHAR2(10);
    v_record_id VARCHAR2(50);
    v_reason VARCHAR2(255);
BEGIN
    -- Determine operation type
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_record_id := :NEW.user_id;
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_record_id := :OLD.user_id;
    ELSE -- DELETING
        v_operation := 'DELETE';
        v_record_id := :OLD.user_id;
    END IF;
    
    -- Check if operation is restricted
    v_restricted := is_restricted_time();
    
    IF v_restricted THEN
        -- Determine specific reason
        IF TO_CHAR(SYSDATE, 'DY') IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
            v_reason := 'Operation restricted during weekdays (Monday-Friday)';
        ELSE
            v_reason := 'Operation restricted during public holidays';
        END IF;
        
        -- Log the denied operation
        INSERT INTO hr_audit_log (
            audit_id,
            username,
            operation_type,
            table_name,
            record_id,
            operation_date,
            operation_status,
            denial_reason,
            client_info,
            os_user
        ) VALUES (
            hr_audit_seq.NEXTVAL,
            USER,
            v_operation,
            'USERS',
            v_record_id,
            SYSTIMESTAMP,
            'DENIED',
            v_reason,
            SYS_CONTEXT('USERENV', 'CLIENT_INFO'),
            SYS_CONTEXT('USERENV', 'OS_USER')
        );
        
        -- Raise error to prevent the operation
        RAISE_APPLICATION_ERROR(-20001, v_reason);
    END IF;
END;
/