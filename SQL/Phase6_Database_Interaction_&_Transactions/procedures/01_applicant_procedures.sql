-- Procedure 1: Register new applicant
CREATE OR REPLACE PROCEDURE register_applicant (
    p_first_name IN VARCHAR2,
    p_last_name IN VARCHAR2,
    p_email IN VARCHAR2,
    p_phone IN VARCHAR2,
    p_highest_degree IN VARCHAR2,
    p_years_experience IN NUMBER,
    p_skills IN VARCHAR2,
    p_applicant_id OUT NUMBER
) AS
    v_count NUMBER;
BEGIN
    -- Check if applicant already exists
    SELECT COUNT(*) INTO v_count
    FROM applicants
    WHERE email = p_email;
    
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Applicant with this email already exists');
    END IF;
    
    -- Insert new applicant
    INSERT INTO applicants (
        applicant_id,
        first_name,
        last_name,
        email,
        phone,
        highest_degree,
        years_of_experience,
        skills,
        registration_date
    ) VALUES (
        applicants_seq.NEXTVAL,
        p_first_name,
        p_last_name,
        p_email,
        p_phone,
        p_highest_degree,
        p_years_experience,
        p_skills,
        SYSDATE
    ) RETURNING applicant_id INTO p_applicant_id;
    
    -- Log the activity
    INSERT INTO activity_logs (
        log_id,
        activity_type,
        activity_description,
        related_entity,
        related_entity_id
    ) VALUES (
        activity_logs_seq.NEXTVAL,
        'APPLICANT_REGISTRATION',
        'New applicant registered: ' || p_first_name || ' ' || p_last_name,
        'applicants',
        p_applicant_id
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Applicant registered successfully with ID: ' || p_applicant_id);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'Duplicate value found. Registration failed.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'Error registering applicant: ' || SQLERRM);
END register_applicant;
/

-- Procedure 2: Submit job application
CREATE OR REPLACE PROCEDURE submit_application (
    p_applicant_id IN NUMBER,
    p_posting_id IN NUMBER,
    p_cover_letter IN VARCHAR2, -- Changed from CLOB to VARCHAR2 to avoid delays
    p_additional_docs IN VARCHAR2,
    p_application_id OUT NUMBER
) AS
    v_applicant_exists NUMBER;
    v_posting_exists NUMBER;
    v_posting_status VARCHAR2(20);
    v_duplicate_application NUMBER;
    v_matching_score NUMBER;
    v_applicant_skills VARCHAR2(500);
    v_required_skills VARCHAR2(500);
BEGIN
    -- Check if applicant exists
    SELECT COUNT(*) INTO v_applicant_exists
    FROM applicants
    WHERE applicant_id = p_applicant_id;
    
    IF v_applicant_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Applicant ID does not exist');
    END IF;
    
    -- Check if posting exists and is published
    BEGIN
        SELECT COUNT(*), MAX(posting_status)
        INTO v_posting_exists, v_posting_status
        FROM job_postings
        WHERE posting_id = p_posting_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_posting_exists := 0;
            v_posting_status := NULL;
    END;
    
    IF v_posting_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Job posting does not exist');
    END IF;
    
    IF v_posting_status != 'Published' THEN
        RAISE_APPLICATION_ERROR(-20006, 'Job posting is not open for applications');
    END IF;
    
    -- Check for duplicate application
    SELECT COUNT(*) INTO v_duplicate_application
    FROM applications
    WHERE applicant_id = p_applicant_id AND posting_id = p_posting_id;
    
    IF v_duplicate_application > 0 THEN
        RAISE_APPLICATION_ERROR(-20007, 'You have already applied for this position');
    END IF;
    
    -- Calculate matching score (simplified algorithm)
    -- In real implementation, this would be more sophisticated
    SELECT skills INTO v_applicant_skills
    FROM applicants
    WHERE applicant_id = p_applicant_id;
    
    SELECT jr.required_skills INTO v_required_skills
    FROM job_postings jp
    JOIN job_requisitions jr ON jp.requisition_id = jr.requisition_id
    WHERE jp.posting_id = p_posting_id;
    
    -- Simple matching algorithm (would be more complex in real system)
    v_matching_score := 50; -- Base score
    
    -- Add points for skills match (simplified)
    IF v_applicant_skills IS NOT NULL AND v_required_skills IS NOT NULL THEN
        -- Check for major skill keywords
        FOR skill IN (
            SELECT REGEXP_SUBSTR(v_required_skills, '[^,]+', 1, LEVEL) AS skill
            FROM dual
            CONNECT BY REGEXP_SUBSTR(v_required_skills, '[^,]+', 1, LEVEL) IS NOT NULL
        ) LOOP
            IF INSTR(UPPER(v_applicant_skills), UPPER(TRIM(skill.skill))) > 0 THEN
                v_matching_score := v_matching_score + 10; -- 10 points per matching skill
            END IF;
        END LOOP;
    END IF;
    
    -- Cap the score at 100
    IF v_matching_score > 100 THEN
        v_matching_score := 100;
    END IF;
    
    -- Insert application
    INSERT INTO applications (
        application_id,
        posting_id,
        applicant_id,
        application_status,
        matching_score,
        cover_letter,
        additional_documents,
        submission_date,
        last_status_change
    ) VALUES (
        applications_seq.NEXTVAL,
        p_posting_id,
        p_applicant_id,
        'Submitted',
        v_matching_score,
        p_cover_letter,
        p_additional_docs,
        SYSDATE,
        SYSDATE
    ) RETURNING application_id INTO p_application_id;
    
    -- Log the activity
    INSERT INTO activity_logs (
        log_id,
        activity_type,
        activity_description,
        related_entity,
        related_entity_id
    ) VALUES (
        activity_logs_seq.NEXTVAL,
        'APPLICATION_SUBMISSION',
        'New application submitted for posting ID: ' || p_posting_id,
        'applications',
        p_application_id
    );
    
    -- Update application count for the posting (for analytics)
    UPDATE job_postings
    SET total_applications = NVL(total_applications, 0) + 1
    WHERE posting_id = p_posting_id;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Application submitted successfully with ID: ' || p_application_id);
    DBMS_OUTPUT.PUT_LINE('Matching score: ' || v_matching_score);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20008, 'Error submitting application: ' || SQLERRM);
END submit_application;
/

-- Procedure 3: Fetch applicant details using cursor
CREATE OR REPLACE PROCEDURE get_applicant_details (
    p_applicant_id IN NUMBER
) AS
    v_applicant_exists NUMBER;
    
    -- Cursor for applicant basic info
    CURSOR c_applicant IS
        SELECT 
            a.applicant_id,
            a.first_name,
            a.last_name,
            a.email,
            a.phone,
            a.highest_degree,
            a.years_of_experience,
            a.skills,
            a.registration_date
        FROM 
            applicants a
        WHERE 
            a.applicant_id = p_applicant_id;
    
    -- Cursor for applications
    CURSOR c_applications IS
        SELECT 
            a.application_id,
            jp.posting_title,
            a.application_status,
            a.matching_score,
            a.submission_date
        FROM 
            applications a
        JOIN 
            job_postings jp ON a.posting_id = jp.posting_id
        WHERE 
            a.applicant_id = p_applicant_id
        ORDER BY 
            a.submission_date DESC;
    
    -- Cursor for interviews
    CURSOR c_interviews IS
        SELECT 
            i.interview_id,
            i.interview_type,
            i.interview_date,
            i.interview_status,
            i.overall_rating,
            i.recommendation
        FROM 
            interviews i
        JOIN 
            applications a ON i.application_id = a.application_id
        WHERE 
            a.applicant_id = p_applicant_id
        ORDER BY 
            i.interview_date DESC;
    
    -- Variables for cursor data
    v_applicant c_applicant%ROWTYPE;
BEGIN
    -- Check if applicant exists
    SELECT COUNT(*) INTO v_applicant_exists
    FROM applicants
    WHERE applicant_id = p_applicant_id;
    
    IF v_applicant_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20009, 'Applicant ID does not exist');
    END IF;
    
    -- Fetch and display applicant details
    OPEN c_applicant;
    FETCH c_applicant INTO v_applicant;
    CLOSE c_applicant;
    
    DBMS_OUTPUT.PUT_LINE('==== APPLICANT DETAILS ====');
    DBMS_OUTPUT.PUT_LINE('ID: ' || v_applicant.applicant_id);
    DBMS_OUTPUT.PUT_LINE('Name: ' || v_applicant.first_name || ' ' || v_applicant.last_name);
    DBMS_OUTPUT.PUT_LINE('Email: ' || v_applicant.email);
    DBMS_OUTPUT.PUT_LINE('Phone: ' || v_applicant.phone);
    DBMS_OUTPUT.PUT_LINE('Education: ' || v_applicant.highest_degree);
    DBMS_OUTPUT.PUT_LINE('Experience: ' || v_applicant.years_of_experience || ' years');
    DBMS_OUTPUT.PUT_LINE('Skills: ' || v_applicant.skills);
    DBMS_OUTPUT.PUT_LINE('Registered: ' || TO_CHAR(v_applicant.registration_date, 'DD-MON-YYYY'));
    
    -- Display applications
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('==== APPLICATIONS ====');
    
    FOR app_rec IN c_applications LOOP
        DBMS_OUTPUT.PUT_LINE('Application ID: ' || app_rec.application_id);
        DBMS_OUTPUT.PUT_LINE('Position: ' || app_rec.posting_title);
        DBMS_OUTPUT.PUT_LINE('Status: ' || app_rec.application_status);
        DBMS_OUTPUT.PUT_LINE('Match Score: ' || app_rec.matching_score);
        DBMS_OUTPUT.PUT_LINE('Submitted: ' || TO_CHAR(app_rec.submission_date, 'DD-MON-YYYY'));
        DBMS_OUTPUT.PUT_LINE('---');
    END LOOP;
    
    -- Display interviews
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('==== INTERVIEWS ====');
    
    FOR int_rec IN c_interviews LOOP
        DBMS_OUTPUT.PUT_LINE('Interview ID: ' || int_rec.interview_id);
        DBMS_OUTPUT.PUT_LINE('Type: ' || int_rec.interview_type);
        DBMS_OUTPUT.PUT_LINE('Date: ' || TO_CHAR(int_rec.interview_date, 'DD-MON-YYYY'));
        DBMS_OUTPUT.PUT_LINE('Status: ' || int_rec.interview_status);
        
        IF int_rec.interview_status = 'Completed' THEN
            DBMS_OUTPUT.PUT_LINE('Rating: ' || int_rec.overall_rating);
            DBMS_OUTPUT.PUT_LINE('Recommendation: ' || int_rec.recommendation);
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('---');
    END LOOP;
    
    -- Log the activity
    INSERT INTO activity_logs (
        log_id,
        activity_type,
        activity_description,
        related_entity,
        related_entity_id
    ) VALUES (
        activity_logs_seq.NEXTVAL,
        'APPLICANT_DETAILS_VIEW',
        'Applicant details viewed for ID: ' || p_applicant_id,
        'applicants',
        p_applicant_id
    );
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error retrieving applicant details: ' || SQLERRM);
END get_applicant_details;
/