-- Get the first employee's ID
SELECT employee_id FROM employees WHERE email = 'olivier.ndayisaba@ihuzo.com';

-- Insert second employee with first employee as supervisor
INSERT INTO employees (
    employee_id, 
    applicant_id, 
    department_id, 
    job_id, 
    hire_date, 
    supervisor_id, -- Use the first employee as supervisor
    salary, 
    email, 
    employment_status
)
VALUES (
    employees_seq.NEXTVAL, 
    (SELECT applicant_id FROM applicants WHERE email = 'mmukamana@email.com'),
    21, -- IT Department
    21, -- Software Developer position
    TO_DATE('2025-05-20', 'YYYY-MM-DD'),
    (SELECT employee_id FROM employees WHERE email = 'olivier.ndayisaba@ihuzo.com'), -- First employee as supervisor
    1700000, 
    'marie.mukamana@ihuzo.com', 
    'Active'
);
COMMIT;