-- Function 2: Get top candidates for a job posting
CREATE OR REPLACE FUNCTION get_top_candidates (
    p_posting_id IN NUMBER,
    p_top_count IN NUMBER DEFAULT 3
) RETURN SYS_REFCURSOR IS
    v_candidates SYS_REFCURSOR;
BEGIN
    OPEN v_candidates FOR
        SELECT 
            ap.applicant_id,
            ap.first_name || ' ' || ap.last_name AS candidate_name,
            ap.email,
            ap.phone,
            ap.years_of_experience,
            ap.highest_degree,
            a.matching_score,
            i.overall_rating,
            i.recommendation
        FROM 
            applications a
        JOIN 
            applicants ap ON a.applicant_id = ap.applicant_id
        LEFT JOIN 
            interviews i ON a.application_id = i.application_id AND i.interview_status = 'Completed'
        WHERE 
            a.posting_id = p_posting_id AND
            a.application_status IN ('Shortlisted', 'Interviewed', 'Offered')
        ORDER BY 
            CASE 
                WHEN i.recommendation = 'Strong Hire' THEN 4
                WHEN i.recommendation = 'Hire' THEN 3
                WHEN i.recommendation = 'Neutral' THEN 2
                WHEN i.recommendation = 'Do Not Hire' THEN 1
                ELSE 0
            END DESC,
            NVL(i.overall_rating, 0) DESC,
            a.matching_score DESC
        FETCH FIRST p_top_count ROWS ONLY;
    
    RETURN v_candidates;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error and return empty cursor
        DECLARE
            v_empty_cursor SYS_REFCURSOR;
        BEGIN
            OPEN v_empty_cursor FOR
                SELECT NULL AS applicant_id, 
                       NULL AS candidate_name,
                       NULL AS email,
                       NULL AS phone,
                       NULL AS years_of_experience,
                       NULL AS highest_degree,
                       NULL AS matching_score,
                       NULL AS overall_rating,
                       NULL AS recommendation
                FROM dual
                WHERE 1 = 0;
            RETURN v_empty_cursor;
        END;
END get_top_candidates;
/

-- Function 3: Calculate hiring success rate
CREATE OR REPLACE FUNCTION calculate_hiring_success_rate (
    p_department_id IN NUMBER DEFAULT NULL,
    p_start_date IN DATE DEFAULT ADD_MONTHS(SYSDATE, -12),
    p_end_date IN DATE DEFAULT SYSDATE
) RETURN NUMBER IS
    v_success_rate NUMBER;
BEGIN
    SELECT 
        CASE 
            WHEN COUNT(DISTINCT jr.requisition_id) = 0 THEN 0
            ELSE ROUND(COUNT(DISTINCT e.employee_id) / COUNT(DISTINCT jr.requisition_id) * 100, 2)
        END
    INTO v_success_rate
    FROM 
        job_requisitions jr
    LEFT JOIN job_postings jp ON jr.requisition_id = jp.requisition_id
    LEFT JOIN applications a ON jp.posting_id = a.posting_id
    LEFT JOIN applicants ap ON a.applicant_id = ap.applicant_id
    LEFT JOIN employees e ON ap.applicant_id = e.applicant_id
    WHERE 
        jr.request_date BETWEEN p_start_date AND p_end_date AND
        (p_department_id IS NULL OR jr.department_id = p_department_id) AND
        jr.approval_status = 'Approved';
    
    RETURN v_success_rate;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END calculate_hiring_success_rate;
/

-- Function 4: Get average interview rating by department
CREATE OR REPLACE FUNCTION get_avg_interview_rating (
    p_department_id IN NUMBER
) RETURN NUMBER IS
    v_avg_rating NUMBER;
BEGIN
    SELECT ROUND(AVG(i.overall_rating), 2)
    INTO v_avg_rating
    FROM 
        interviews i
    JOIN applications a ON i.application_id = a.application_id
    JOIN job_postings jp ON a.posting_id = jp.posting_id
    JOIN job_requisitions jr ON jp.requisition_id = jr.requisition_id
    WHERE 
        jr.department_id = p_department_id AND
        i.interview_status = 'Completed';
    
    RETURN v_avg_rating;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END get_avg_interview_rating;
/