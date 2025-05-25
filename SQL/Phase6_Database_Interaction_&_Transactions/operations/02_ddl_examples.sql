-- DDL Example 1: CREATE - Add a new table for tracking recruitment campaigns
CREATE TABLE recruitment_campaignss (
    campaign_id NUMBER PRIMARY KEY,
    campaign_name VARCHAR2(100) NOT NULL,
    description VARCHAR2(500),
    start_date DATE NOT NULL,
    end_date DATE,
    target_positions NUMBER DEFAULT 0,
    budget NUMBER,
    status VARCHAR2(20) DEFAULT 'Planning' 
        CHECK (status IN ('Planning', 'Active', 'Completed', 'Cancelled')),
    created_by NUMBER NOT NULL,
    created_date DATE DEFAULT SYSDATE,
    modified_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_campaign_creator FOREIGN KEY (created_by) REFERENCES users(user_id)
);

-- Create sequence for the new table
CREATE SEQUENCE recruitment_campaigns_seq START WITH 1 INCREMENT BY 1;

-- DDL Example 2: ALTER - Add columns to an existing table
ALTER TABLE test_connection
ADD (
    campaign_id NUMBER,
    cost_per_click NUMBER(11,3),
    total_views NUMBER DEFAULT 0,
    total_applications NUMBER DEFAULT 0
);

-- DDL Example 3: CREATE INDEX - Add index for performance
CREATE INDEX idx_posting_campaignns ON test_connection(campaign_id);
CREATE INDEX idx_campaign_date ON recruitment_campaigns(start_date, end_date);

-- DDL Example 4: CREATE VIEW - Create a view for easier reporting
CREATE OR REPLACE VIEW vw_application_status AS
SELECT 
    d.department_name,
    jp.job_title,
    jpo.posting_title,
    ap.first_name || ' ' || ap.last_name AS applicant_name,
    ap.email AS applicant_email,
    a.application_status,
    a.matching_score,
    a.submission_date,
    i.interview_date,
    i.overall_rating,
    i.recommendation,
    jo.offer_status,
    jo.offered_salary
FROM 
    departments d
JOIN job_requisitions jr ON d.department_id = jr.department_id
JOIN job_positions jp ON jr.job_id = jp.job_id
JOIN job_postings jpo ON jr.requisition_id = jpo.requisition_id
JOIN applications a ON jpo.posting_id = a.posting_id
JOIN applicants ap ON a.applicant_id = ap.applicant_id
LEFT JOIN interviews i ON a.application_id = i.application_id AND i.interview_status = 'Completed'
LEFT JOIN job_offers jo ON a.application_id = jo.application_id
ORDER BY d.department_name, jp.job_title, a.submission_date;

-- DDL Example 5: CREATE MATERIALIZED VIEW - For analytics performance
CREATE MATERIALIZED VIEW mv_recruitment_metrics
REFRESH COMPLETE ON DEMAND
AS
SELECT 
    d.department_id,
    d.department_name,
    jp.job_id,
    jp.job_title,
    COUNT(DISTINCT jr.requisition_id) AS requisition_count,
    COUNT(DISTINCT jpo.posting_id) AS posting_count,
    COUNT(DISTINCT a.application_id) AS application_count,
    COUNT(DISTINCT CASE WHEN a.application_status = 'Shortlisted' THEN a.application_id END) AS shortlisted_count,
    COUNT(DISTINCT i.interview_id) AS interview_count,
    COUNT(DISTINCT jo.offer_id) AS offer_count,
    COUNT(DISTINCT CASE WHEN jo.offer_status = 'Accepted' THEN jo.offer_id END) AS accepted_offers,
    COUNT(DISTINCT e.employee_id) AS hired_count,
    ROUND(COUNT(DISTINCT CASE WHEN a.application_status = 'Shortlisted' THEN a.application_id END) / 
          NULLIF(COUNT(DISTINCT a.application_id), 0) * 100, 2) AS shortlist_rate,
    ROUND(COUNT(DISTINCT CASE WHEN jo.offer_status = 'Accepted' THEN jo.offer_id END) / 
          NULLIF(COUNT(DISTINCT jo.offer_id), 0) * 100, 2) AS offer_acceptance_rate,
    ROUND(AVG(i.overall_rating), 2) AS avg_interview_rating
FROM 
    departments d
LEFT JOIN job_requisitions jr ON d.department_id = jr.department_id
LEFT JOIN job_positions jp ON jr.job_id = jp.job_id
LEFT JOIN job_postings jpo ON jr.requisition_id = jpo.requisition_id
LEFT JOIN applications a ON jpo.posting_id = a.posting_id
LEFT JOIN interviews i ON a.application_id = i.application_id
LEFT JOIN job_offers jo ON a.application_id = jo.application_id
LEFT JOIN applicants ap ON a.applicant_id = ap.applicant_id
LEFT JOIN employees e ON ap.applicant_id = e.applicant_id AND e.department_id = d.department_id
GROUP BY d.department_id, d.department_name, jp.job_id, jp.job_title;

-- DDL Example 6: DROP and recreate a constraint with a new name
-- First get the existing constraint name to make sure we have it right
SELECT constraint_name
FROM user_constraints
WHERE table_name = 'APPLICATIONS'
AND constraint_type = 'R'
AND r_constraint_name IN (
    SELECT constraint_name 
    FROM user_constraints 
    WHERE table_name = 'JOB_POSTINGS'
    AND constraint_type = 'P'
);

-- Temporary table to demonstrate constraint changes safely
CREATE TABLE temp_applications (
    temp_id NUMBER PRIMARY KEY,
    posting_id NUMBER,
    applicant_id NUMBER,
    CONSTRAINT fk_temp_posting FOREIGN KEY (posting_id) REFERENCES job_postings(posting_id)
);

-- Drop the constraint from the temp table
ALTER TABLE temp_applications DROP CONSTRAINT fk_temp_posting;

-- Add it back with a different name
ALTER TABLE temp_applications ADD CONSTRAINT fk_temp_app_posting
FOREIGN KEY (posting_id) REFERENCES job_postings(posting_id);

-- Clean up the temporary table
DROP TABLE temp_applications;