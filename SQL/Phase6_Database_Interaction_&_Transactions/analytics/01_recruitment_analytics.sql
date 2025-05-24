-- Problem Statement: 
-- Analyze recruitment efficiency and candidate quality across departments and job positions
-- This will help identify bottlenecks and optimize the recruitment process

-- 1. Analyze time-to-fill positions by department and job
WITH application_stages AS (
    SELECT 
        d.department_id,
        d.department_name,
        jp.job_id,
        jp.job_title,
        jr.requisition_id,
        jr.request_date,
        MIN(a.submission_date) AS first_application_date,
        MIN(CASE WHEN a.application_status IN ('Shortlisted', 'Interviewed', 'Offered', 'Hired') 
             THEN a.last_status_change ELSE NULL END) AS first_shortlist_date,
        MIN(i.interview_date) AS first_interview_date,
        MIN(CASE WHEN jo.offer_status = 'Accepted' THEN jo.modified_date ELSE NULL END) AS acceptance_date,
        MIN(e.hire_date) AS hire_date
    FROM 
        departments d
    JOIN job_requisitions jr ON d.department_id = jr.department_id
    JOIN job_positions jp ON jr.job_id = jp.job_id
    LEFT JOIN job_postings jpo ON jr.requisition_id = jpo.requisition_id
    LEFT JOIN applications a ON jpo.posting_id = a.posting_id
    LEFT JOIN interviews i ON a.application_id = i.application_id
    LEFT JOIN job_offers jo ON a.application_id = jo.application_id
    LEFT JOIN applicants ap ON a.applicant_id = ap.applicant_id
    LEFT JOIN employees e ON ap.applicant_id = e.applicant_id
    WHERE jr.approval_status = 'Approved'
    GROUP BY d.department_id, d.department_name, jp.job_id, jp.job_title, jr.requisition_id, jr.request_date
)
SELECT 
    department_name,
    job_title,
    requisition_id,
    request_date,
    first_application_date,
    first_shortlist_date,
    first_interview_date,
    acceptance_date,
    hire_date,
    CASE WHEN hire_date IS NOT NULL THEN 
        ROUND((hire_date - request_date), 0) 
    ELSE 
        ROUND((SYSDATE - request_date), 0) 
    END AS days_open,
    ROUND(AVG(CASE WHEN hire_date IS NOT NULL THEN 
                (hire_date - request_date) 
             ELSE 
                (SYSDATE - request_date) 
             END) OVER (PARTITION BY department_id), 0) AS avg_days_by_dept,
    ROUND(AVG(CASE WHEN hire_date IS NOT NULL THEN 
                (hire_date - request_date) 
             ELSE 
                (SYSDATE - request_date) 
             END) OVER (PARTITION BY job_id), 0) AS avg_days_by_job,
    CASE WHEN hire_date IS NOT NULL THEN 
        'Filled' 
    ELSE 
        'Open' 
    END AS status
FROM application_stages
ORDER BY department_name, job_title;

-- 2. Analyze candidate quality with window functions
WITH candidate_rankings AS (
    SELECT 
        d.department_name,
        jp.job_title,
        jpo.posting_id,
        a.application_id,
        ap.first_name || ' ' || ap.last_name AS candidate_name,
        a.matching_score,
        i.overall_rating,
        i.technical_skills_rating,
        i.communication_rating,
        i.cultural_fit_rating,
        i.recommendation,
        RANK() OVER (PARTITION BY jpo.posting_id ORDER BY a.matching_score DESC) AS algorithm_rank,
        RANK() OVER (PARTITION BY jpo.posting_id ORDER BY i.overall_rating DESC NULLS LAST) AS interview_rank,
        RANK() OVER (PARTITION BY jpo.posting_id ORDER BY i.technical_skills_rating DESC NULLS LAST) AS technical_rank,
        RANK() OVER (PARTITION BY jpo.posting_id ORDER BY i.communication_rating DESC NULLS LAST) AS communication_rank,
        RANK() OVER (PARTITION BY jpo.posting_id ORDER BY i.cultural_fit_rating DESC NULLS LAST) AS cultural_rank,
        CASE 
            WHEN i.recommendation = 'Strong Hire' THEN 4
            WHEN i.recommendation = 'Hire' THEN 3
            WHEN i.recommendation = 'Neutral' THEN 2
            WHEN i.recommendation = 'Do Not Hire' THEN 1
            ELSE 0
        END AS recommendation_score
    FROM 
        departments d
    JOIN job_requisitions jr ON d.department_id = jr.department_id
    JOIN job_positions jp ON jr.job_id = jp.job_id
    JOIN job_postings jpo ON jr.requisition_id = jpo.requisition_id
    JOIN applications a ON jpo.posting_id = a.posting_id
    JOIN applicants ap ON a.applicant_id = ap.applicant_id
    LEFT JOIN interviews i ON a.application_id = i.application_id AND i.interview_status = 'Completed'
    WHERE a.application_status IN ('Shortlisted', 'Interviewed', 'Offered', 'Hired')
)
SELECT 
    department_name,
    job_title,
    posting_id,
    candidate_name,
    matching_score,
    overall_rating,
    technical_skills_rating,
    communication_rating,
    cultural_fit_rating,
    recommendation,
    algorithm_rank,
    interview_rank,
    technical_rank,
    communication_rank,
    cultural_rank,
    ROUND((NVL(algorithm_rank, 999) + NVL(interview_rank, 999) + NVL(technical_rank, 999) + 
           NVL(communication_rank, 999) + NVL(cultural_rank, 999)) / 
          CASE 
              WHEN interview_rank IS NULL THEN 1 
              ELSE 5 
          END, 2) AS composite_score,
    DENSE_RANK() OVER (PARTITION BY posting_id 
                      ORDER BY recommendation_score DESC NULLS LAST, 
                               overall_rating DESC NULLS LAST, 
                               matching_score DESC) AS overall_rank
FROM candidate_rankings
ORDER BY department_name, job_title, posting_id, overall_rank;

-- 3. Analyze recruitment funnel and conversion rates by department using window functions
WITH recruitment_funnel AS (
    SELECT 
        d.department_id,
        d.department_name,
        jp.job_id,
        jp.job_title,
        COUNT(DISTINCT a.application_id) AS total_applications,
        COUNT(DISTINCT CASE WHEN a.application_status IN ('Shortlisted', 'Interviewed', 'Offered', 'Hired') 
                      THEN a.application_id END) AS shortlisted,
        COUNT(DISTINCT CASE WHEN a.application_status IN ('Interviewed', 'Offered', 'Hired') 
                      THEN a.application_id END) AS interviewed,
        COUNT(DISTINCT CASE WHEN a.application_status IN ('Offered', 'Hired') 
                      THEN a.application_id END) AS offered,
        COUNT(DISTINCT CASE WHEN a.application_status = 'Hired' 
                      THEN a.application_id END) AS hired
    FROM 
        departments d
    JOIN job_requisitions jr ON d.department_id = jr.department_id
    JOIN job_positions jp ON jr.job_id = jp.job_id
    JOIN job_postings jpo ON jr.requisition_id = jpo.requisition_id
    LEFT JOIN applications a ON jpo.posting_id = a.posting_id
    GROUP BY d.department_id, d.department_name, jp.job_id, jp.job_title
)
SELECT 
    department_name,
    job_title,
    total_applications,
    shortlisted,
    interviewed,
    offered,
    hired,
    ROUND(shortlisted / NULLIF(total_applications, 0) * 100, 2) AS shortlist_rate,
    ROUND(interviewed / NULLIF(shortlisted, 0) * 100, 2) AS interview_rate,
    ROUND(offered / NULLIF(interviewed, 0) * 100, 2) AS offer_rate,
    ROUND(hired / NULLIF(offered, 0) * 100, 2) AS acceptance_rate,
    ROUND(hired / NULLIF(total_applications, 0) * 100, 2) AS overall_conversion,
    ROUND(AVG(total_applications) OVER (PARTITION BY department_id), 0) AS dept_avg_applications,
    ROUND(AVG(shortlist_rate) OVER (PARTITION BY department_id), 2) AS dept_avg_shortlist_rate,
    ROUND(MAX(overall_conversion) OVER (PARTITION BY department_id), 2) AS dept_max_conversion,
    ROUND(MIN(overall_conversion) OVER (PARTITION BY department_id), 2) AS dept_min_conversion
FROM (
    SELECT 
        department_name,
        job_title,
        total_applications,
        shortlisted,
        interviewed,
        offered,
        hired,
        ROUND(shortlisted / NULLIF(total_applications, 0) * 100, 2) AS shortlist_rate,
        ROUND(interviewed / NULLIF(shortlisted, 0) * 100, 2) AS interview_rate,
        ROUND(offered / NULLIF(interviewed, 0) * 100, 2) AS offer_rate,
        ROUND(hired / NULLIF(offered, 0) * 100, 2) AS acceptance_rate,
        ROUND(hired / NULLIF(total_applications, 0) * 100, 2) AS overall_conversion,
        department_id
    FROM recruitment_funnel
)
ORDER BY department_name, job_title;

-- 4. Compare candidate quality across time periods using window functions
WITH monthly_quality AS (
    SELECT 
        TO_CHAR(a.submission_date, 'YYYY-MM') AS application_month,
        d.department_name,
        COUNT(a.application_id) AS applications,
        ROUND(AVG(a.matching_score), 2) AS avg_matching_score,
        ROUND(AVG(i.overall_rating), 2) AS avg_interview_rating,
        ROUND(AVG(i.technical_skills_rating), 2) AS avg_technical_rating,
        COUNT(CASE WHEN i.recommendation = 'Strong Hire' THEN 1 END) AS strong_hire_count,
        COUNT(CASE WHEN i.recommendation = 'Hire' THEN 1 END) AS hire_count,
        COUNT(CASE WHEN i.recommendation = 'Neutral' THEN 1 END) AS neutral_count,
        COUNT(CASE WHEN i.recommendation = 'Do Not Hire' THEN 1 END) AS do_not_hire_count
    FROM 
        applications a
    JOIN job_postings jpo ON a.posting_id = jpo.posting_id
    JOIN job_requisitions jr ON jpo.requisition_id = jr.requisition_id
    JOIN departments d ON jr.department_id = d.department_id
    LEFT JOIN interviews i ON a.application_id = i.application_id AND i.interview_status = 'Completed'
    GROUP BY TO_CHAR(a.submission_date, 'YYYY-MM'), d.department_name
)
SELECT 
    application_month,
    department_name,
    applications,
    avg_matching_score,
    avg_interview_rating,
    avg_technical_rating,
    strong_hire_count,
    hire_count,
    neutral_count,
    do_not_hire_count,
    LAG(avg_matching_score, 1) OVER (PARTITION BY department_name ORDER BY application_month) AS prev_month_matching_score,
    ROUND((avg_matching_score - LAG(avg_matching_score, 1) OVER (PARTITION BY department_name ORDER BY application_month)) / 
          NULLIF(LAG(avg_matching_score, 1) OVER (PARTITION BY department_name ORDER BY application_month), 0) * 100, 2) AS matching_score_growth,
    LAG(avg_interview_rating, 1) OVER (PARTITION BY department_name ORDER BY application_month) AS prev_month_interview_rating,
    ROUND((avg_interview_rating - LAG(avg_interview_rating, 1) OVER (PARTITION BY department_name ORDER BY application_month)) / 
          NULLIF(LAG(avg_interview_rating, 1) OVER (PARTITION BY department_name ORDER BY application_month), 0) * 100, 2) AS interview_rating_growth,
    ROUND(AVG(avg_matching_score) OVER (PARTITION BY department_name), 2) AS dept_avg_matching_score,
    ROUND(AVG(avg_interview_rating) OVER (PARTITION BY department_name), 2) AS dept_avg_interview_rating
FROM monthly_quality
ORDER BY department_name, application_month;