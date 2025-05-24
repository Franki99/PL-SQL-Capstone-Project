-- Insert Job Positions
INSERT INTO job_positions (job_id, job_title, job_description, min_salary, max_salary)
VALUES (job_positions_seq.NEXTVAL, 'Software Developer', 
        'Responsible for designing and developing software applications', 
        1200000, 2000000);

INSERT INTO job_positions (job_id, job_title, job_description, min_salary, max_salary)
VALUES (job_positions_seq.NEXTVAL, 'Database Administrator', 
        'Responsible for database management and optimization', 
        1500000, 2200000);

INSERT INTO job_positions (job_id, job_title, job_description, min_salary, max_salary)
VALUES (job_positions_seq.NEXTVAL, 'HR Specialist', 
        'Responsible for HR operations and recruitment', 
        1000000, 1800000);

INSERT INTO job_positions (job_id, job_title, job_description, min_salary, max_salary)
VALUES (job_positions_seq.NEXTVAL, 'Financial Analyst', 
        'Responsible for financial analysis and reporting', 
        1300000, 2100000);

INSERT INTO job_positions (job_id, job_title, job_description, min_salary, max_salary)
VALUES (job_positions_seq.NEXTVAL, 'Marketing Specialist', 
        'Responsible for marketing campaigns and analysis', 
        1100000, 1900000);

COMMIT;