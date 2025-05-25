-- Enable DBMS_OUTPUT
SET SERVEROUTPUT ON SIZE 1000000;

-- Test 1: Register a new applicant
DECLARE
    v_applicant_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== Test 1: Register New Applicant =====');
    
    BEGIN
        register_applicant(
            p_first_name => 'Charles',
            p_last_name => 'Nkusi',
            p_email => 'cnkusi@email.com',
            p_phone => '+250788123321',
            p_highest_degree => 'Bachelor in Computer Science',
            p_years_experience => 4,
            p_skills => 'Java, Python, SQL, Git, Jenkins',
            p_applicant_id => v_applicant_id
        );
        
        DBMS_OUTPUT.PUT_LINE('Success! Applicant registered with ID: ' || v_applicant_id);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    END;
END;
/

-- Test 2: Submit a job application
DECLARE
    v_application_id NUMBER;
    v_applicant_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== Test 2: Submit Job Application =====');
    
    -- Get the most recently created applicant
    SELECT MAX(applicant_id) INTO v_applicant_id
    FROM applicants;
    
    BEGIN
        submit_application(
            p_applicant_id => v_applicant_id,
            p_posting_id => 21, -- Use an existing posting ID
            p_cover_letter => 'I am excited to apply for this position at Ihuzo. With my skills in Java and Python, I believe I would be a great addition to your team.',
            p_additional_docs => '/documents/tnkusi_certificate.pdf',
            p_application_id => v_application_id
        );
        
        DBMS_OUTPUT.PUT_LINE('Success! Application submitted with ID: ' || v_application_id);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    END;
END;
/

-- Test 3: Process applications using cursor
DECLARE
    v_processed_count NUMBER;
    v_shortlisted_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== Test 3: Process Applications =====');
    
    BEGIN
        process_applications(
            p_posting_id => 1, -- Use an existing posting ID
            p_processed_count => v_processed_count,
            p_shortlisted_count => v_shortlisted_count
        );
        
        DBMS_OUTPUT.PUT_LINE('Success! Processed ' || v_processed_count || ' applications');
        DBMS_OUTPUT.PUT_LINE('Shortlisted ' || v_shortlisted_count || ' applications');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    END;
END;
/

-- Test 4: Get applicant details using cursor
DECLARE
    v_applicant_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== Test 4: Get Applicant Details =====');
    
    -- Get a random applicant ID
    SELECT applicant_id INTO v_applicant_id
    FROM applicants
    WHERE ROWNUM = 1;
    
    BEGIN
        get_applicant_details(v_applicant_id);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    END;
END;
/

-- Test 5: Calculate matching score (function)
DECLARE
    v_applicant_id NUMBER;
    v_job_id NUMBER;
    v_score NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== Test 5: Calculate Matching Score =====');
    
    -- Get a random applicant and job
    SELECT MIN(applicant_id) INTO v_applicant_id FROM applicants;
    SELECT MIN(job_id) INTO v_job_id FROM job_positions;
    
    v_score := calculate_matching_score(v_applicant_id, v_job_id);
    
    DBMS_OUTPUT.PUT_LINE('Matching score for applicant ' || v_applicant_id || 
                         ' and job ' || v_job_id || ': ' || v_score);
END;
/

-- Test 6: Check time to fill function
DECLARE
    v_requisition_id NUMBER;
    v_days NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== Test 6: Calculate Time to Fill =====');
    
    -- Get a random requisition
    SELECT requisition_id INTO v_requisition_id
    FROM job_requisitions
    WHERE ROWNUM = 1;
    
    v_days := calculate_time_to_fill(v_requisition_id);
    
    IF v_days IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('Time to fill requisition ' || v_requisition_id || ': ' || v_days || ' days');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Requisition ' || v_requisition_id || ' is not yet filled');
    END IF;
END;
/

-- Test 7: Get top candidates using the function
DECLARE
    v_candidates SYS_REFCURSOR;
    v_applicant_id NUMBER;
    v_candidate_name VARCHAR2(101);
    v_email VARCHAR2(100);
    v_years_experience NUMBER;
    v_matching_score NUMBER;
    v_overall_rating NUMBER;
    v_recommendation VARCHAR2(30);
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== Test 7: Get Top Candidates =====');
    
    v_candidates := get_top_candidates(1, 3); -- Get top 3 candidates for posting ID 1
    
    DBMS_OUTPUT.PUT_LINE('Top candidates for posting ID 1:');
    LOOP
        FETCH v_candidates INTO 
            v_applicant_id, 
            v_candidate_name, 
            v_email, 
            v_years_experience, 
            v_matching_score, 
            v_overall_rating, 
            v_recommendation;
            
        EXIT WHEN v_candidates%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE(
            'Name: ' || v_candidate_name || 
            ', Match: ' || v_matching_score || 
            ', Rating: ' || NVL(TO_CHAR(v_overall_rating), 'N/A') || 
            ', Recommendation: ' || NVL(v_recommendation, 'N/A')
        );
    END LOOP;
    
    CLOSE v_candidates;
EXCEPTION
    WHEN OTHERS THEN
        IF v_candidates%ISOPEN THEN
            CLOSE v_candidates;
        END IF;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Test 8: Test HR Recruitment Package
DECLARE
    v_applicant_id NUMBER;
    v_application_id NUMBER;
    v_matching_score NUMBER;
    v_processed_count NUMBER;
    v_shortlisted_count NUMBER;
    v_candidate_list hr_recruitment_pkg.candidate_tab;
    v_requisition_stats hr_recruitment_pkg.requisition_stats_rec;
    v_performance_score NUMBER;
    v_meets_requirements BOOLEAN;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== Test 8: HR Recruitment Package =====');
    
    -- Get existing data for testing
    SELECT MAX(applicant_id) INTO v_applicant_id FROM applicants;
    
    -- Test process_new_application
    BEGIN
        hr_recruitment_pkg.process_new_application(
            p_applicant_id => v_applicant_id,
            p_posting_id => 2, -- Use a different posting ID
            p_cover_letter => 'I am applying for this database position at Ihuzo.',
            p_additional_docs => NULL,
            p_application_id => v_application_id,
            p_matching_score => v_matching_score
        );
        
        DBMS_OUTPUT.PUT_LINE('Application submitted with ID: ' || v_application_id || ', Score: ' || v_matching_score);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error in process_new_application: ' || SQLERRM);
    END;
    
    -- Test review_applications
    BEGIN
        hr_recruitment_pkg.review_applications(
            p_posting_id => 2,
            p_reviewer_id => 2, -- HR user
            p_processed_count => v_processed_count,
            p_shortlisted_count => v_shortlisted_count
        );
        
        DBMS_OUTPUT.PUT_LINE('Processed ' || v_processed_count || ' applications, Shortlisted ' || v_shortlisted_count);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error in review_applications: ' || SQLERRM);
    END;
    
    -- Test get_top_candidates_list
    BEGIN
        v_candidate_list := hr_recruitment_pkg.get_top_candidates_list(1, 2); -- Get top 2 for posting ID 1
        
        DBMS_OUTPUT.PUT_LINE('Top candidates for posting ID 1:');
        FOR i IN 1..v_candidate_list.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE(
                i || '. ' || v_candidate_list(i).applicant_name || 
                ', Score: ' || v_candidate_list(i).matching_score
            );
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error in get_top_candidates_list: ' || SQLERRM);
    END;
    
    -- Test get_requisition_stats
    BEGIN
        v_requisition_stats := hr_recruitment_pkg.get_requisition_stats(1); -- Use requisition ID 1
        
        DBMS_OUTPUT.PUT_LINE('Stats for requisition ID 1:');
        DBMS_OUTPUT.PUT_LINE('Job: ' || v_requisition_stats.job_title);
        DBMS_OUTPUT.PUT_LINE('Department: ' || v_requisition_stats.department_name);
        DBMS_OUTPUT.PUT_LINE('Days open: ' || v_requisition_stats.days_open);
        DBMS_OUTPUT.PUT_LINE('Applications: ' || v_requisition_stats.application_count);
        DBMS_OUTPUT.PUT_LINE('Shortlisted: ' || v_requisition_stats.shortlisted_count);
        DBMS_OUTPUT.PUT_LINE('Interviewed: ' || v_requisition_stats.interviewed_count);
        DBMS_OUTPUT.PUT_LINE('Offered: ' || v_requisition_stats.offered_count);
        DBMS_OUTPUT.PUT_LINE('Hired: ' || v_requisition_stats.hired_count);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error in get_requisition_stats: ' || SQLERRM);
    END;
    
    -- Test calculate_dept_performance
    BEGIN
        v_performance_score := hr_recruitment_pkg.calculate_dept_performance(1); -- Department ID 1
        
        DBMS_OUTPUT.PUT_LINE('Performance score for department ID 1: ' || NVL(TO_CHAR(v_performance_score), 'N/A'));
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error in calculate_dept_performance: ' || SQLERRM);
    END;
    
    -- Test meets_minimum_requirements
    BEGIN
        v_meets_requirements := hr_recruitment_pkg.meets_minimum_requirements(1); -- Application ID 1
        
        DBMS_OUTPUT.PUT_LINE('Application ID 1 meets minimum requirements: ' || 
                             CASE WHEN v_meets_requirements THEN 'Yes' ELSE 'No' END);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error in meets_minimum_requirements: ' || SQLERRM);
    END;
END;
/