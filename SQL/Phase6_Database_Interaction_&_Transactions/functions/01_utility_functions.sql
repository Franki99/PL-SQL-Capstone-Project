-- Function 1: Calculate time to fill a position
CREATE OR REPLACE FUNCTION calculate_time_to_fill (
    p_requisition_id IN NUMBER
) RETURN NUMBER IS
    v_request_date DATE;
    v_hire_date DATE;
    v_days_to_fill NUMBER;
BEGIN
    -- Get requisition request date
    BEGIN
        SELECT request_date INTO v_request_date
        FROM job_requisitions
        WHERE requisition_id = p_requisition_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END;
    
    -- Get the hire date (if any)
    BEGIN
        SELECT MIN(e.hire_date) INTO v_hire_date
        FROM employees e
        JOIN applicants ap ON e.applicant_id = ap.applicant_id
        JOIN applications a ON ap.applicant_id = a.applicant_id
        JOIN job_postings jp ON a.posting_id = jp.posting_id
        WHERE jp.requisition_id = p_requisition_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_hire_date := NULL;
    END;
    
    -- Calculate days to fill
    IF v_hire_date IS NOT NULL THEN
        v_days_to_fill := v_hire_date - v_request_date;
    ELSE
        v_days_to_fill := NULL;
    END IF;
    
    RETURN v_days_to_fill;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END calculate_time_to_fill;
/

-- Function 2: Get applicant count by status for a job posting
CREATE OR REPLACE FUNCTION get_applicant_count_by_status (
    p_posting_id IN NUMBER,
    p_status IN VARCHAR2
) RETURN NUMBER IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM applications
    WHERE 
        posting_id = p_posting_id AND
        (p_status IS NULL OR application_status = p_status);
    
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END get_applicant_count_by_status;
/

-- Function 3: Calculate matching score for an applicant and job
CREATE OR REPLACE FUNCTION calculate_matching_score (
    p_applicant_id IN NUMBER,
    p_job_id IN NUMBER
) RETURN NUMBER IS
    v_applicant_skills VARCHAR2(500);
    v_required_skills VARCHAR2(500);
    v_years_experience NUMBER;
    v_required_experience NUMBER;
    v_highest_degree VARCHAR2(50);
    v_education_requirements VARCHAR2(200);
    v_matching_score NUMBER := 50; -- Base score
BEGIN
    -- Get applicant details
    BEGIN
        SELECT skills, years_of_experience, highest_degree
        INTO v_applicant_skills, v_years_experience, v_highest_degree
        FROM applicants
        WHERE applicant_id = p_applicant_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END;
    
    -- Get job requirements
    BEGIN
        SELECT 
            MAX(jr.required_skills) AS required_skills,
            MAX(jr.required_experience) AS required_experience,
            MAX(jr.education_requirements) AS education_requirements
        INTO 
            v_required_skills,
            v_required_experience,
            v_education_requirements
        FROM job_requisitions jr
        WHERE jr.job_id = p_job_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END;
    
    -- Skills match (40% of score)
    IF v_applicant_skills IS NOT NULL AND v_required_skills IS NOT NULL THEN
        -- Check for skill keywords
        FOR skill IN (
            SELECT REGEXP_SUBSTR(v_required_skills, '[^,]+', 1, LEVEL) AS skill
            FROM dual
            CONNECT BY REGEXP_SUBSTR(v_required_skills, '[^,]+', 1, LEVEL) IS NOT NULL
        ) LOOP
            IF INSTR(UPPER(v_applicant_skills), UPPER(TRIM(skill.skill))) > 0 THEN
                v_matching_score := v_matching_score + 8; -- 8 points per matching skill (max 5 skills = 40%)
            END IF;
        END LOOP;
    END IF;
    
    -- Experience match (30% of score)
    IF v_years_experience IS NOT NULL AND v_required_experience IS NOT NULL THEN
        IF v_years_experience >= v_required_experience THEN
            v_matching_score := v_matching_score + 30;
        ELSIF v_years_experience >= (v_required_experience * 0.8) THEN
            v_matching_score := v_matching_score + 20;
        ELSIF v_years_experience >= (v_required_experience * 0.6) THEN
            v_matching_score := v_matching_score + 10;
        END IF;
    END IF;
    
    -- Education match (20% of score)
    IF v_highest_degree IS NOT NULL AND v_education_requirements IS NOT NULL THEN
        -- Match based on degree level (simplified)
        IF INSTR(UPPER(v_highest_degree), 'PHD') > 0 OR INSTR(UPPER(v_highest_degree), 'DOCTORATE') > 0 THEN
            v_matching_score := v_matching_score + 20;
        ELSIF INSTR(UPPER(v_highest_degree), 'MASTER') > 0 THEN
            IF INSTR(UPPER(v_education_requirements), 'BACHELOR') > 0 THEN
                v_matching_score := v_matching_score + 20;
            ELSE
                v_matching_score := v_matching_score + 15;
            END IF;
        ELSIF INSTR(UPPER(v_highest_degree), 'BACHELOR') > 0 THEN
            IF INSTR(UPPER(v_education_requirements), 'BACHELOR') > 0 THEN
                v_matching_score := v_matching_score + 20;
            ELSE
                v_matching_score := v_matching_score + 10;
            END IF;
        END IF;
    END IF;
    
    -- Cap the score at 100
    IF v_matching_score > 100 THEN
        v_matching_score := 100;
    END IF;
    
    RETURN v_matching_score;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END calculate_matching_score;
/

-- Function 4: Check if applicant is qualified for job
CREATE OR REPLACE FUNCTION is_applicant_qualified (
    p_applicant_id IN NUMBER,
    p_job_id IN NUMBER
) RETURN VARCHAR2 IS
    v_matching_score NUMBER;
    v_years_experience NUMBER;
    v_required_experience NUMBER;
    v_qualification_status VARCHAR2(100);
BEGIN
    -- Get matching score
    v_matching_score := calculate_matching_score(p_applicant_id, p_job_id);
    
    -- Get experience comparison
    SELECT a.years_of_experience, jr.required_experience
    INTO v_years_experience, v_required_experience
    FROM applicants a, job_requisitions jr
    WHERE a.applicant_id = p_applicant_id
    AND jr.job_id = p_job_id
    AND ROWNUM = 1;
    
    -- Determine qualification status
    IF v_matching_score >= 85 THEN
        v_qualification_status := 'Highly Qualified';
    ELSIF v_matching_score >= 70 THEN
        IF v_years_experience >= v_required_experience THEN
            v_qualification_status := 'Qualified';
        ELSE
            v_qualification_status := 'Partially Qualified (Experience Gap)';
        END IF;
    ELSIF v_matching_score >= 50 THEN
        v_qualification_status := 'Marginally Qualified';
    ELSE
        v_qualification_status := 'Not Qualified';
    END IF;
    
    RETURN v_qualification_status;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Error: ' || SQLERRM;
END is_applicant_qualified;
/