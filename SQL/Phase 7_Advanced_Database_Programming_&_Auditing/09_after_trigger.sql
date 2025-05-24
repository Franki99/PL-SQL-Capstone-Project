-- 07_after_trigger.sql
-- Connect to your database
CONNECT Divanni/Aguerokun10@localhost:1521/B_25312_Divanni_IhuzoHR_DB

-- Create an AFTER trigger to automatically log allowed operations
CREATE OR REPLACE TRIGGER trg_audit_allowed_operations
AFTER INSERT OR UPDATE OR DELETE ON applicants
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
    v_record_id VARCHAR2(50);
BEGIN
    -- Skip if operation is during restricted time (will be handled by BEFORE trigger)
    IF hr_audit_pkg.is_restricted_time() THEN
        RETURN;
    END IF;
    
    -- Determine operation type
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_record_id := :NEW.applicant_id;
        
        -- Log the allowed operation
        hr_audit_pkg.log_audit(
            p_username => USER,
            p_operation_type => v_operation,
            p_table_name => 'APPLICANTS',
            p_record_id => v_record_id,
            p_operation_status => 'ALLOWED'
        );
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_record_id := :OLD.applicant_id;
        
        -- Check which columns changed and log each change
        IF :OLD.first_name != :NEW.first_name OR
           (:OLD.first_name IS NULL AND :NEW.first_name IS NOT NULL) OR
           (:OLD.first_name IS NOT NULL AND :NEW.first_name IS NULL) THEN
            hr_audit_pkg.log_data_change(
                p_table_name => 'APPLICANTS',
                p_record_id => v_record_id,
                p_column_name => 'FIRST_NAME',
                p_old_value => :OLD.first_name,
                p_new_value => :NEW.first_name
            );
        END IF;
        
        IF :OLD.last_name != :NEW.last_name OR
           (:OLD.last_name IS NULL AND :NEW.last_name IS NOT NULL) OR
           (:OLD.last_name IS NOT NULL AND :NEW.last_name IS NULL) THEN
            hr_audit_pkg.log_data_change(
                p_table_name => 'APPLICANTS',
                p_record_id => v_record_id,
                p_column_name => 'LAST_NAME',
                p_old_value => :OLD.last_name,
                p_new_value => :NEW.last_name
            );
        END IF;
        
        IF :OLD.email != :NEW.email OR
           (:OLD.email IS NULL AND :NEW.email IS NOT NULL) OR
           (:OLD.email IS NOT NULL AND :NEW.email IS NULL) THEN
            hr_audit_pkg.log_data_change(
                p_table_name => 'APPLICANTS',
                p_record_id => v_record_id,
                p_column_name => 'EMAIL',
                p_old_value => :OLD.email,
                p_new_value => :NEW.email
            );
        END IF;
        
        -- Additional sensitive fields could be added here
    ELSE -- DELETING
        v_operation := 'DELETE';
        v_record_id := :OLD.applicant_id;
        
        -- Log the allowed operation
        hr_audit_pkg.log_audit(
            p_username => USER,
            p_operation_type => v_operation,
            p_table_name => 'APPLICANTS',
            p_record_id => v_record_id,
            p_operation_status => 'ALLOWED'
        );
    END IF;
END;
/