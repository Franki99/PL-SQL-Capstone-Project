-- 1. Add a test holiday for today's date to test restriction functionality
INSERT INTO public_holidays (
    holiday_id, holiday_date, holiday_name, description
) VALUES (
    public_holidays_seq.NEXTVAL, 
    TRUNC(SYSDATE),
    'Test Holiday',
    'Temporary holiday for testing restrictions'
);
COMMIT;

-- 2. Verify the holiday was added
SELECT holiday_id, 
       TO_CHAR(holiday_date, 'YYYY-MM-DD') AS holiday_date, 
       holiday_name, 
       description
FROM public_holidays
WHERE holiday_date = TRUNC(SYSDATE);

-- 3. Debug function to check if the system now sees today as restricted
CREATE OR REPLACE FUNCTION debug_is_restricted_time RETURN VARCHAR2 IS
    v_current_day VARCHAR2(3);
    v_is_holiday NUMBER;
    v_result BOOLEAN;
    v_debug VARCHAR2(4000);
BEGIN
    -- Get current day of week (MON, TUE, WED, THU, FRI, SAT, SUN)
    v_current_day := TO_CHAR(SYSDATE, 'DY');
    v_debug := 'Current day: ' || v_current_day || '. ';
    
    -- Check if today is a public holiday
    SELECT COUNT(*) INTO v_is_holiday
    FROM public_holidays
    WHERE holiday_date = TRUNC(SYSDATE);
    
    v_debug := v_debug || 'Holiday count: ' || v_is_holiday || '. ';
    
    -- Original function logic
    v_result := (v_current_day IN ('MON', 'TUE', 'WED', 'THU', 'FRI') OR v_is_holiday > 0);
    
    v_debug := v_debug || 'Final result: ' || CASE WHEN v_result THEN 'RESTRICTED' ELSE 'ALLOWED' END;
    
    RETURN v_debug;
END;
/

-- 4. Check if today is now restricted
SELECT debug_is_restricted_time FROM dual;

-- 5. Test if operations are now blocked
BEGIN
    -- Test with a dummy update to see if the trigger blocks it
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Attempting to update an applicant on a simulated holiday...');
        
        UPDATE applicants
        SET phone = '+250789999000'
        WHERE ROWNUM = 1;
        
        DBMS_OUTPUT.PUT_LINE('Update succeeded - trigger did not block operation');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Update blocked with error: ' || SQLERRM);
    END;
END;
/

-- 6. Clean up after testing - remove the test holiday
DELETE FROM public_holidays
WHERE holiday_date = TRUNC(SYSDATE)
AND holiday_name = 'Test Holiday';
COMMIT;

-- 7. Verify the cleanup
SELECT COUNT(*) AS remaining_test_holidays
FROM public_holidays
WHERE holiday_date = TRUNC(SYSDATE)
AND holiday_name = 'Test Holiday';

-- 8. Verify we're back to normal (unrestricted) on Saturday
SELECT debug_is_restricted_time FROM dual;