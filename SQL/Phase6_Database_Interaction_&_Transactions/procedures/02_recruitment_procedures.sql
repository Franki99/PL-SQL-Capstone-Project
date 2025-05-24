-- Procedure 1: Create job requisition
CREATE OR REPLACE PROCEDURE create_job_requisition (
    p_department_id IN NUMBER,
    p_job_id IN NUMBER,
    p_requested_by IN NUMBER,
    p_number_of_positions IN NUMBER,
    p_required_skills IN VARCHAR2,
    p_required_experience IN NUMBER,
    p_education_requirements IN VARCHAR2,
    p_special_requirements IN VARCHAR2,
    p_priority IN VARCHAR2,
    p_target_hire_date IN DATE,
    p_requisition_id OUT NUMBER
) AS
    v_dept_exists NUMBER;
    v_job_exists NUMBER;
    v_user_exists NUMBER;
    v_user_role VARCHAR2(30);
BEGIN
    -- Validate department
    SELECT COUNT(*) INTO v_dept_exists
    FROM departments
    WHERE department_id = p_department_id;
    
    IF v_dept_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Department ID does not exist');
    END IF;
    
    -- Validate job
    SELECT COUNT(*) INTO v_job_exists
    FROM job_positions
    WHERE job_id = p_job_id;
    
    IF v_job_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'Job ID does not exist');
    END IF;
    
    -- Validate user and role
    SELECT COUNT(*), MAX(user_role) INTO v_user_exists, v_user_role
    FROM users
    WHERE user_id = p_requested_by;
    
    IF v_user_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20012, 'User ID does not exist');
    END IF;
    
    IF v_user_role != 'Department Manager' THEN
        RAISE_APPLICATION_ERROR(-20013, 'Only Department Managers can create job requisitions');
    END IF;
    
    -- Create requisition
    INSERT INTO job_requisitions (
        requisition_id,
        department_id,
        job_id,
        requested_by,
        approval_status,
        number_of_positions,
        required_skills,
        required_experience,
        education_requirements,
        special_requirements,
        priority,
        request_date,
        target_hire_date
    ) VALUES (
        job_requisitions_seq.NEXTVAL,
        p_department_id,
        p_job_id,
        p_requested_by,
        'Pending', -- Initial status is Pending
        p_number_of_positions,
        p_required_skills,
        p_required_experience,
        p_education_requirements,
        p_special_requirements,
        p_priority,
        SYSDATE,
        p_target_hire_date
    ) RETURNING requisition_id INTO p_requisition_id;
    
    -- Log the activity
    INSERT INTO activity_logs (
        log_id,
        activity_type,
        activity_description,
        user_id,
        related_entity,
        related_entity_id
    ) VALUES (
        activity_logs_seq.NEXTVAL,
        'REQUISITION_CREATION',
        'New job requisition created for department ID: ' || p_department_id,
        p_requested_by,
        'job_requisitions',
        p_requisition_id
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Job requisition created successfully with ID: ' || p_requisition_id);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20014, 'Error creating job requisition: ' || SQLERRM);
END create_job_requisition;
/

-- Procedure 2: Process job applications (bulk processing with cursor)
CREATE OR REPLACE PROCEDURE process_applications (
    p_posting_id IN NUMBER,
    p_processed_count OUT NUMBER,
    p_shortlisted_count OUT NUMBER
) AS
    v_posting_exists NUMBER;
    v_min_matching_score NUMBER := 75; -- Threshold for automatic shortlisting
    
    -- Cursor for pending applications
    CURSOR c_applications IS
        SELECT 
            a.application_id,
            a.applicant_id,
            a.matching_score,
            ap.years_of_experience,
            ap.highest_degree
        FROM 
            applications a
        JOIN 
            applicants ap ON a.applicant_id = ap.applicant_id
        WHERE 
            a.posting_id = p_posting_id AND
            a.application_status = 'Submitted'
        ORDER BY 
            a.matching_score DESC;
            
    -- Variables to store requisition requirements
    v_required_experience NUMBER;
    v_education_requirements VARCHAR2(200);
    v_job_title VARCHAR2(100);
    
BEGIN
    -- Check if posting exists
    SELECT COUNT(*) INTO v_posting_exists
    FROM job_postings
    WHERE posting_id = p_posting_id;
    
    IF v_posting_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20015, 'Job posting does not exist');
    END IF;
    
    -- Get job requirements
    BEGIN
        SELECT 
            jr.required_experience,
            jr.education_requirements,
            jp.job_title
        INTO 
            v_required_experience,
            v_education_requirements,
            v_job_title
        FROM 
            job_postings jpo
        JOIN 
            job_requisitions jr ON jpo.requisition_id = jr.requisition_id
        JOIN 
            job_positions jp ON jr.job_id = jp.job_id
        WHERE 
            jpo.posting_id = p_posting_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_required_experience := 0;
            v_education_requirements := NULL;
            v_job_title := 'Unknown Position';
    END;
    
    -- Initialize counters
    p_processed_count := 0;
    p_shortlisted_count := 0;
    
    -- Process applications
    FOR app_rec IN c_applications LOOP
        -- Update to 'Screening' status initially
        UPDATE applications
        SET 
            application_status = 'Screening',
            last_status_change = SYSDATE
        WHERE 
            application_id = app_rec.application_id;
            
        p_processed_count := p_processed_count + 1;
        
        -- Automatic shortlisting logic
        IF app_rec.matching_score >= v_min_matching_score AND
           app_rec.years_of_experience >= v_required_experience THEN
            
            -- Shortlist the candidate
            UPDATE applications
            SET 
                application_status = 'Shortlisted',
                last_status_change = SYSDATE
            WHERE 
                application_id = app_rec.application_id;
                
            p_shortlisted_count := p_shortlisted_count + 1;
            
            -- Log the shortlisting
            INSERT INTO activity_logs (
                log_id,
                activity_type,
                activity_description,
                related_entity,
                related_entity_id
            ) VALUES (
                activity_logs_seq.NEXTVAL,
                'APPLICATION_SHORTLISTED',
                'Application automatically shortlisted for ' || v_job_title,
                'applications',
                app_rec.application_id
            );
        END IF;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Processed ' || p_processed_count || ' applications');
    DBMS_OUTPUT.PUT_LINE('Shortlisted ' || p_shortlisted_count || ' candidates');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20016, 'Error processing applications: ' || SQLERRM);
END process_applications;
/

-- Procedure 3: Schedule interviews for shortlisted candidates
CREATE OR REPLACE PROCEDURE schedule_interviews (
    p_posting_id IN NUMBER,
    p_interviewer_id IN NUMBER,
    p_interview_type IN VARCHAR2,
    p_start_date IN DATE,
    p_interview_duration IN NUMBER, -- in minutes
    p_daily_slots IN NUMBER, -- number of interviews per day
    p_scheduled_count OUT NUMBER
) AS
    v_posting_exists NUMBER;
    v_interviewer_exists NUMBER;
    v_current_date DATE := p_start_date;
    v_slot_counter NUMBER := 0;
    v_interview_location VARCHAR2(200) := 'Ihuzo Office, Room 305';
    
    -- Cursor for shortlisted applications without interviews
    CURSOR c_shortlisted IS
        SELECT 
            a.application_id,
            a.applicant_id,
            ap.first_name || ' ' || ap.last_name AS applicant_name
        FROM 
            applications a
        JOIN 
            applicants ap ON a.applicant_id = ap.applicant_id
        LEFT JOIN 
            interviews i ON a.application_id = i.application_id
        WHERE 
            a.posting_id = p_posting_id AND
            a.application_status = 'Shortlisted' AND
            i.interview_id IS NULL
        ORDER BY 
            a.matching_score DESC;
            
BEGIN
    -- Check if posting exists
    SELECT COUNT(*) INTO v_posting_exists
    FROM job_postings
    WHERE posting_id = p_posting_id;
    
    IF v_posting_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20017, 'Job posting does not exist');
    END IF;
    
    -- Check if interviewer exists
    SELECT COUNT(*) INTO v_interviewer_exists
    FROM users
    WHERE user_id = p_interviewer_id;
    
    IF v_interviewer_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20018, 'Interviewer ID does not exist');
    END IF;
    
    -- Initialize counter
    p_scheduled_count := 0;
    
    -- Schedule interviews
    FOR candidate IN c_shortlisted LOOP
        -- Calculate interview date and time
        IF v_slot_counter >= p_daily_slots THEN
            v_current_date := v_current_date + 1; -- Move to next day
            v_slot_counter := 0; -- Reset slot counter
        END IF;
        
        -- Skip weekends
        WHILE TO_CHAR(v_current_date, 'DY') IN ('SAT', 'SUN') LOOP
            v_current_date := v_current_date + 1;
        END LOOP;
        
        -- Schedule the interview
        INSERT INTO interviews (
            interview_id,
            application_id,
            interview_type,
            interview_date,
            interview_location,
            interviewer_id,
            interview_status
        ) VALUES (
            interviews_seq.NEXTVAL,
            candidate.application_id,
            p_interview_type,
            v_current_date + (v_slot_counter * p_interview_duration / (24*60)), -- Convert minutes to day fraction
            v_interview_location,
            p_interviewer_id,
            'Scheduled'
        );
        
        -- Update application status
        UPDATE applications
        SET 
            application_status = 'Interviewed',
            last_status_change = SYSDATE
        WHERE 
            application_id = candidate.application_id;
            
        -- Log the scheduling
        INSERT INTO activity_logs (
            log_id,
            activity_type,
            activity_description,
            user_id,
            related_entity,
            related_entity_id
        ) VALUES (
            activity_logs_seq.NEXTVAL,
            'INTERVIEW_SCHEDULED',
            'Interview scheduled for ' || candidate.applicant_name,
            p_interviewer_id,
            'interviews',
            interviews_seq.CURRVAL
        );
        
        p_scheduled_count := p_scheduled_count + 1;
        v_slot_counter := v_slot_counter + 1;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Scheduled ' || p_scheduled_count || ' interviews');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20019, 'Error scheduling interviews: ' || SQLERRM);
END schedule_interviews;
/