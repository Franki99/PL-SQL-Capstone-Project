-- DML Example 1: INSERT operation
-- Add a new job position
INSERT INTO job_positions (
    job_id, job_title, job_description, min_salary, max_salary
) VALUES (
    job_positions_seq.NEXTVAL, 'AI Specialist', 
    'Responsible for developing and implementing artificial intelligence solutions. Experience with machine learning frameworks and natural language processing required.',
    1500000, 2300000
);
COMMIT;

-- DML Example 2: UPDATE operation
-- Update salary range for an existing position
UPDATE job_positions
SET min_salary = 1300000, max_salary = 2100000
WHERE job_title = 'Software Developer' AND ROWNUM = 1;
COMMIT;

-- DML Example 3: DELETE operation (only if you have applications to delete)
-- First check if applicant with ID 26 has applications
SELECT * FROM applications WHERE applicant_id = 26;

-- Then delete if it exists
DELETE FROM applications
WHERE application_id = 
    (SELECT MAX(application_id) FROM applications WHERE applicant_id = 26);
COMMIT;

-- DML Example 4: Transaction with COMMIT
-- Create a new department and assign a manager
BEGIN
    -- Insert new department
    INSERT INTO departments (
        department_id, department_name, location
    ) VALUES (
        departments_seq.NEXTVAL, 'Research & Development', 'Kigali, Floor 4'
    );
    
    -- Get the new department ID
    DECLARE
        v_dept_id NUMBER;
    BEGIN
        SELECT MAX(department_id) INTO v_dept_id FROM departments;
        
        -- Create a new user as department manager
        INSERT INTO users (
            user_id, username, password_hash, first_name, last_name, 
            email, department_id, user_role
        ) VALUES (
            users_seq.NEXTVAL, 'rkagame', 'hashed_password', 'Robert', 'Kagame',
            'rkagame@ihuzo.com', v_dept_id, 'Department Manager'
        );
        
        -- Update department with manager ID
        UPDATE departments
        SET manager_id = (SELECT MAX(user_id) FROM users)
        WHERE department_id = v_dept_id;
    END;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Transaction completed successfully.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Transaction failed: ' || SQLERRM);
END;
/

-- DML Example 5: Transaction with SAVEPOINT
-- Process a candidate through multiple stages
BEGIN
    -- Create a new applicant
    INSERT INTO applicants (
        applicant_id, first_name, last_name, email, phone,
        highest_degree, years_of_experience
    ) VALUES (
        applicants_seq.NEXTVAL, 'Jacques', 'Munezero', 'jmunezero@email.com', '+250789123456',
        'Master in Data Science', 5
    );
    
    SAVEPOINT applicant_created;
    
    -- Submit an application
    DECLARE
        v_applicant_id NUMBER;
        v_posting_id NUMBER;
    BEGIN
        -- Get the new applicant ID
        SELECT MAX(applicant_id) INTO v_applicant_id FROM applicants WHERE last_name = 'Munezero';
        
        -- Get an existing posting ID
        SELECT MIN(posting_id) INTO v_posting_id FROM job_postings;
        
        INSERT INTO applications (
            application_id, posting_id, applicant_id, application_status, matching_score,
            submission_date
        ) VALUES (
            applications_seq.NEXTVAL, v_posting_id, v_applicant_id, 'Submitted', 82.5,
            SYSDATE
        );
    END;
    
    SAVEPOINT application_submitted;
    
    -- Schedule an interview
    DECLARE
        v_application_id NUMBER;
    BEGIN
        -- Get the new application ID
        SELECT MAX(application_id) INTO v_application_id FROM applications;
        
        INSERT INTO interviews (
            interview_id, application_id, interview_type, interview_date, 
            interview_location, interviewer_id, interview_status
        ) VALUES (
            interviews_seq.NEXTVAL, v_application_id, 'Technical', 
            SYSDATE + 7, 'Ihuzo Office, Room 305', 21, 'Scheduled'
        );
    END;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Full recruitment process initiated successfully.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO applicant_created;
        DBMS_OUTPUT.PUT_LINE('Process failed: ' || SQLERRM);
END;
/