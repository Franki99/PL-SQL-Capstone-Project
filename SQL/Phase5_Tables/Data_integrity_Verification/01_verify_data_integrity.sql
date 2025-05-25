-- Verify table counts
SELECT 'departments' AS table_name, COUNT(*) AS record_count FROM departments
UNION ALL
SELECT 'job_positions' AS table_name, COUNT(*) AS record_count FROM job_positions
UNION ALL
SELECT 'job_requisitions' AS table_name, COUNT(*) AS record_count FROM job_requisitions
UNION ALL
SELECT 'job_postings' AS table_name, COUNT(*) AS record_count FROM job_postings
UNION ALL
SELECT 'applicants' AS table_name, COUNT(*) AS record_count FROM applicants
UNION ALL
SELECT 'applications' AS table_name, COUNT(*) AS record_count FROM applications
UNION ALL
SELECT 'interviews' AS table_name, COUNT(*) AS record_count FROM interviews
UNION ALL
SELECT 'job_offers' AS table_name, COUNT(*) AS record_count FROM job_offers
UNION ALL
SELECT 'employees' AS table_name, COUNT(*) AS record_count FROM employees
UNION ALL
SELECT 'users' AS table_name, COUNT(*) AS record_count FROM users
UNION ALL
SELECT 'activity_logs' AS table_name, COUNT(*) AS record_count FROM activity_logs;

-- Verify foreign key integrity
SELECT 'FK_DEPT_MANAGER' AS constraint_name, 
       (SELECT COUNT(*) FROM departments d 
        LEFT JOIN users u ON d.manager_id = u.user_id
        WHERE d.manager_id IS NOT NULL AND u.user_id IS NULL) AS orphaned_records
UNION ALL
SELECT 'FK_REQ_DEPARTMENT' AS constraint_name,
       (SELECT COUNT(*) FROM job_requisitions r
        LEFT JOIN departments d ON r.department_id = d.department_id
        WHERE d.department_id IS NULL) AS orphaned_records
UNION ALL
SELECT 'FK_POSTING_REQUISITION' AS constraint_name,
       (SELECT COUNT(*) FROM job_postings p
        LEFT JOIN job_requisitions r ON p.requisition_id = r.requisition_id
        WHERE r.requisition_id IS NULL) AS orphaned_records
UNION ALL
SELECT 'FK_APP_APPLICANT' AS constraint_name,
       (SELECT COUNT(*) FROM applications a
        LEFT JOIN applicants ap ON a.applicant_id = ap.applicant_id
        WHERE ap.applicant_id IS NULL) AS orphaned_records
UNION ALL
SELECT 'FK_INTERVIEW_APPLICATION' AS constraint_name,
       (SELECT COUNT(*) FROM interviews i
        LEFT JOIN applications a ON i.application_id = a.application_id
        WHERE a.application_id IS NULL) AS orphaned_records;

-- Verify application workflow integrity
SELECT a.application_id, a.application_status, 
       (SELECT COUNT(*) FROM interviews i WHERE i.application_id = a.application_id) AS interview_count,
       (SELECT COUNT(*) FROM job_offers o WHERE o.application_id = a.application_id) AS offer_count
FROM applications a
ORDER BY a.application_id;

-- Verify job posting and requisition alignment
SELECT r.requisition_id, r.approval_status, r.number_of_positions,
       (SELECT COUNT(*) FROM job_postings p WHERE p.requisition_id = r.requisition_id) AS posting_count,
       (SELECT COUNT(*) FROM applications a 
        JOIN job_postings p ON a.posting_id = p.posting_id 
        WHERE p.requisition_id = r.requisition_id) AS application_count,
       (SELECT COUNT(*) FROM employees e 
        JOIN applicants ap ON e.applicant_id = ap.applicant_id
        JOIN applications a ON ap.applicant_id = a.applicant_id
        JOIN job_postings p ON a.posting_id = p.posting_id
        WHERE p.requisition_id = r.requisition_id) AS hired_count
FROM job_requisitions r
ORDER BY r.requisition_id;

-- Check data types and constraints
SELECT column_name, data_type, data_length, nullable
FROM user_tab_columns
WHERE table_name = 'APPLICANTS'
ORDER BY column_id;

-- Test a complex query that validates the end-to-end recruitment process
SELECT 
    d.department_name,
    jp.job_title,
    COUNT(DISTINCT jr.requisition_id) AS requisition_count,
    COUNT(DISTINCT jpo.posting_id) AS posting_count,
    COUNT(DISTINCT a.application_id) AS application_count,
    COUNT(DISTINCT CASE WHEN a.application_status = 'Shortlisted' THEN a.application_id END) AS shortlisted_count,
    COUNT(DISTINCT i.interview_id) AS interview_count,
    COUNT(DISTINCT jo.offer_id) AS offer_count,
    COUNT(DISTINCT e.employee_id) AS hired_count
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
GROUP BY d.department_name, jp.job_title
ORDER BY d.department_name, jp.job_title;