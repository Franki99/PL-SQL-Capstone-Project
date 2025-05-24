-- HR Recruitment Package Specification
CREATE OR REPLACE PACKAGE hr_recruitment_pkg AS
    -- Constants
    c_min_matching_score CONSTANT NUMBER := 75;
    c_min_interview_rating CONSTANT NUMBER := 3.5;
    
    -- Types
    TYPE candidate_rec IS RECORD (
        applicant_id NUMBER,
        applicant_name VARCHAR2(101),
        email VARCHAR2(100),
        years_experience NUMBER,
        matching_score NUMBER,
        interview_rating NUMBER,
        recommendation VARCHAR2(30)
    );
    
    TYPE candidate_tab IS TABLE OF candidate_rec;
    
    TYPE requisition_stats_rec IS RECORD (
        requisition_id NUMBER,
        job_title VARCHAR2(100),
        department_name VARCHAR2(100),
        days_open NUMBER,
        application_count NUMBER,
        shortlisted_count NUMBER,
        interviewed_count NUMBER,
        offered_count NUMBER,
        hired_count NUMBER
    );
    
    -- Public Procedures
    
    -- 1. Process new application
    PROCEDURE process_new_application (
        p_applicant_id IN NUMBER,
        p_posting_id IN NUMBER,
        p_cover_letter IN CLOB,
        p_additional_docs IN VARCHAR2,
        p_application_id OUT NUMBER,
        p_matching_score OUT NUMBER
    );
    
    -- 2. Review and shortlist applications
    PROCEDURE review_applications (
        p_posting_id IN NUMBER,
        p_reviewer_id IN NUMBER,
        p_min_score IN NUMBER DEFAULT c_min_matching_score,
        p_processed_count OUT NUMBER,
        p_shortlisted_count OUT NUMBER
    );
    
    -- 3. Schedule and manage interviews
    PROCEDURE manage_interviews (
        p_posting_id IN NUMBER,
        p_interviewer_id IN NUMBER,
        p_start_date IN DATE DEFAULT SYSDATE + 1,
        p_scheduled_count OUT NUMBER
    );
    
    -- 4. Process interview results
    PROCEDURE process_interview_results (
        p_interview_id IN NUMBER,
        p_overall_rating IN NUMBER,
        p_technical_rating IN NUMBER,
        p_communication_rating IN NUMBER,
        p_cultural_rating IN NUMBER,
        p_notes IN CLOB,
        p_recommendation IN VARCHAR2
    );
    
    -- 5. Generate job offer
    PROCEDURE generate_job_offer (
        p_application_id IN NUMBER,
        p_prepared_by IN NUMBER,
        p_approved_by IN NUMBER,
        p_offered_salary IN NUMBER,
        p_start_date IN DATE,
        p_expiration_date IN DATE DEFAULT SYSDATE + 7,
        p_benefits_package IN VARCHAR2,
        p_offer_id OUT NUMBER
    );
    
    -- 6. Process offer response
    PROCEDURE process_offer_response (
        p_offer_id IN NUMBER,
        p_status IN VARCHAR2,
        p_response_date IN DATE DEFAULT SYSDATE
    );
    
    -- 7. Complete hiring process
    PROCEDURE complete_hiring (
        p_offer_id IN NUMBER,
        p_employee_id OUT NUMBER
    );
    
    -- Public Functions
    
    -- 1. Get top candidates for a position
    FUNCTION get_top_candidates_list (
        p_posting_id IN NUMBER,
        p_limit IN NUMBER DEFAULT 5
    ) RETURN candidate_tab;
    
    -- 2. Get requisition statistics
    FUNCTION get_requisition_stats (
        p_requisition_id IN NUMBER
    ) RETURN requisition_stats_rec;
    
    -- 3. Calculate department recruitment performance
    FUNCTION calculate_dept_performance (
        p_department_id IN NUMBER
    ) RETURN NUMBER;
    
    -- 4. Check if candidate meets minimum requirements
    FUNCTION meets_minimum_requirements (
        p_application_id IN NUMBER
    ) RETURN BOOLEAN;
    
    -- 5. Get recruitment efficiency metrics
    FUNCTION get_efficiency_metrics (
        p_department_id IN NUMBER DEFAULT NULL,
        p_start_date IN DATE DEFAULT ADD_MONTHS(SYSDATE, -12),
        p_end_date IN DATE DEFAULT SYSDATE
    ) RETURN SYS_REFCURSOR;
    
END hr_recruitment_pkg;
/