-- Check trigger status
SELECT trigger_name, table_name, status, triggering_event
FROM user_triggers
WHERE trigger_name = 'TRG_PREVENT_RESTRICTED_OPERATIONS';

-- Check if the trigger is called by manually raising an error inside it
CREATE OR REPLACE TRIGGER trg_prevent_restricted_operations
BEFORE INSERT OR UPDATE OR DELETE ON applicants
BEGIN
    -- Add debug output to see if trigger is firing
    DBMS_OUTPUT.PUT_LINE('*** TRIGGER FIRED - WOULD CHECK RESTRICTION ***');
    
    -- Always raise an error to confirm the trigger is running
    RAISE_APPLICATION_ERROR(-20099, 'Test error - trigger is executing');
    
    -- Original logic (won't run due to the above error)
    IF hr_audit_pkg.is_restricted_time() THEN
        IF TO_CHAR(SYSDATE, 'DY') IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
            RAISE_APPLICATION_ERROR(-20001, 'Operation restricted during weekdays (Monday-Friday)');
        ELSE
            RAISE_APPLICATION_ERROR(-20002, 'Operation restricted during public holidays');
        END IF;
    END IF;
END;
/

-- Now test if the trigger fires
BEGIN
    -- Try a simple update
    BEGIN
        UPDATE applicants
        SET phone = '+250789555555'
        WHERE ROWNUM = 1;
        
        DBMS_OUTPUT.PUT_LINE('Update succeeded - trigger did not fire');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    END;
END;
/

-- Restore the original trigger
CREATE OR REPLACE TRIGGER trg_prevent_restricted_operations
BEFORE INSERT OR UPDATE OR DELETE ON applicants
BEGIN
    IF hr_audit_pkg.is_restricted_time() THEN
        -- Determine the reason
        IF TO_CHAR(SYSDATE, 'DY') IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
            RAISE_APPLICATION_ERROR(-20001, 'Operation restricted during weekdays (Monday-Friday)');
        ELSE
            RAISE_APPLICATION_ERROR(-20002, 'Operation restricted during public holidays');
        END IF;
    END IF;
END;
/