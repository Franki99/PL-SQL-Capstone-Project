-- First, check your actual posting and applicant IDs
SELECT posting_id, requisition_id, posting_title FROM job_postings;
SELECT applicant_id, first_name, last_name, email FROM applicants;

-- Insert Applications one by one with commits (using subqueries for IDs)
INSERT INTO applications (
    application_id, 
    posting_id, 
    applicant_id, 
    application_status, 
    matching_score,
    submission_date, 
    last_status_change
)
VALUES (
    applications_seq.NEXTVAL, 
    (SELECT MIN(posting_id) FROM job_postings), -- First posting
    (SELECT applicant_id FROM applicants WHERE email = 'ondayisaba@email.com'), 
    'Shortlisted', 
    85.5,
    TO_DATE('2025-04-22', 'YYYY-MM-DD'), 
    TO_DATE('2025-04-30', 'YYYY-MM-DD')
);
COMMIT;

INSERT INTO applications (
    application_id, 
    posting_id, 
    applicant_id, 
    application_status, 
    matching_score,
    submission_date, 
    last_status_change
)
VALUES (
    applications_seq.NEXTVAL, 
    (SELECT MIN(posting_id) FROM job_postings), -- First posting
    (SELECT applicant_id FROM applicants WHERE email = 'mmukamana@email.com'), 
    'Shortlisted', 
    92.0,
    TO_DATE('2025-04-23', 'YYYY-MM-DD'), 
    TO_DATE('2025-04-30', 'YYYY-MM-DD')
);
COMMIT;

INSERT INTO applications (
    application_id, 
    posting_id, 
    applicant_id, 
    application_status, 
    matching_score,
    submission_date, 
    last_status_change
)
VALUES (
    applications_seq.NEXTVAL, 
    (SELECT MIN(posting_id) FROM job_postings), -- First posting
    (SELECT applicant_id FROM applicants WHERE email = 'dmugisha@email.com'), 
    'Screening', 
    78.0,
    TO_DATE('2025-04-25', 'YYYY-MM-DD'), 
    TO_DATE('2025-04-28', 'YYYY-MM-DD')
);
COMMIT;