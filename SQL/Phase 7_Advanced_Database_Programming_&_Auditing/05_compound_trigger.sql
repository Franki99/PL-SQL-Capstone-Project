-- Compound trigger for salary-related tables (job_positions, job_offers, employees)
CREATE OR REPLACE TRIGGER trg_salary_audit_compound
FOR UPDATE OR INSERT OR DELETE ON job_positions
COMPOUND TRIGGER
    -- Define variables that are available for all timing points
    v_restricted BOOLEAN;
    v_operation VARCHAR2(10);
    v_record_id VARCHAR2(50);
    v_reason VARCHAR2(255);
    v_allowed BOOLEAN;
    
    -- Before statement section
    BEFORE STATEMENT IS
    BEGIN
        -- Check if operation is restricted
        v_restricted := is_restricted_time();
        v_allowed := NOT v_restricted;
        
        -- Set reason if restricted
        IF v_restricted THEN
            IF TO_CHAR(SYSDATE, 'DY') IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
                v_reason := 'Operation restricted during weekdays (Monday-Friday)';
            ELSE
                v_reason := 'Operation restricted during public holidays';
            END IF;
        END IF;
    END BEFORE STATEMENT;
    
    -- Before each row section
    BEFORE EACH ROW IS
    BEGIN
        -- Replace RETURN with IF-THEN structure
        IF NOT v_allowed THEN
            -- Determine operation type and record ID
            IF INSERTING THEN
                v_operation := 'INSERT';
                v_record_id := :NEW.job_id;
            ELSIF UPDATING THEN
                v_operation := 'UPDATE';
                v_record_id := :OLD.job_id;
                
                -- Special audit for salary changes
                IF :OLD.min_salary != :NEW.min_salary OR :OLD.max_salary != :NEW.max_salary THEN
                    -- Log the salary change attempt
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
                        os_user
                    ) VALUES (
                        hr_audit_seq.NEXTVAL,
                        USER,
                        'SALARY_UPDATE',
                        'JOB_POSITIONS',
                        v_record_id,
                        'MIN_SALARY,MAX_SALARY',
                        :OLD.min_salary || ',' || :OLD.max_salary,
                        :NEW.min_salary || ',' || :NEW.max_salary,
                        SYSTIMESTAMP,
                        'DENIED',
                        v_reason,
                        SYS_CONTEXT('USERENV', 'CLIENT_INFO'),
                        SYS_CONTEXT('USERENV', 'OS_USER')
                    );
                END IF;
            ELSE -- DELETING
                v_operation := 'DELETE';
                v_record_id := :OLD.job_id;
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
                'JOB_POSITIONS',
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
    END BEFORE EACH ROW;
    
    -- After statement section (executes if statement is allowed)
    AFTER STATEMENT IS
    BEGIN
        -- Record that operations were allowed
        IF v_allowed THEN
            INSERT INTO hr_audit_log (
                audit_id,
                username,
                operation_type,
                table_name,
                operation_date,
                operation_status,
                client_info,
                os_user
            ) VALUES (
                hr_audit_seq.NEXTVAL,
                USER,
                'BATCH_OPERATION',
                'JOB_POSITIONS',
                SYSTIMESTAMP,
                'ALLOWED',
                SYS_CONTEXT('USERENV', 'CLIENT_INFO'),
                SYS_CONTEXT('USERENV', 'OS_USER')
            );
        END IF;
    END AFTER STATEMENT;
END trg_salary_audit_compound;
/