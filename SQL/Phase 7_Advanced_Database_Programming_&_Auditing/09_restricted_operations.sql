-- Create a BEFORE trigger to prevent operations during restricted times
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