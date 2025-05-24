-- First, check your actual application IDs and interviewer (user) IDs
SELECT a.application_id, ap.first_name || ' ' || ap.last_name AS applicant_name, 
       a.application_status, jp.posting_title
FROM applications a
JOIN applicants ap ON a.applicant_id = ap.applicant_id
JOIN job_postings jp ON a.posting_id = jp.posting_id;

SELECT user_id, first_name, last_name, user_role FROM users;

-- Insert Interviews one by one with commits (using actual application IDs)
INSERT INTO interviews (
    interview_id, 
    application_id, 
    interview_type, 
    interview_date, 
    interview_location,
    interviewer_id, 
    interview_status, 
    overall_rating, 
    technical_skills_rating,
    communication_rating, 
    cultural_fit_rating, 
    recommendation
)
VALUES (
    interviews_seq.NEXTVAL, 
    (SELECT MIN(application_id) FROM applications), -- First application
    'Technical', 
    TO_DATE('2025-05-05', 'YYYY-MM-DD'), 
    'Ihuzo Office, Room 302', 
    21, -- Jean Mutabazi (adjust if your user_id is different)
    'Completed', 
    4.2, 
    4.5, 
    4.0, 
    4.0,
    'Hire'
);
COMMIT;

INSERT INTO interviews (
    interview_id, 
    application_id, 
    interview_type, 
    interview_date, 
    interview_location,
    interviewer_id, 
    interview_status
)
VALUES (
    interviews_seq.NEXTVAL, 
    (SELECT MIN(application_id) + 1 FROM applications), -- Second application
    'Technical', 
    TO_DATE('2025-05-10', 'YYYY-MM-DD'), 
    'Virtual - Zoom', 
    21, -- Jean Mutabazi (adjust if your user_id is different)
    'Scheduled'
);
COMMIT;