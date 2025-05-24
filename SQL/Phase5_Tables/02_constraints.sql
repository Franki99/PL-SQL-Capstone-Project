-- Connect to your database
CONNECT Divanni/Aguerokun10@localhost:1521/B_25312_Divanni_IhuzoHR_DB

-- Add foreign key constraints

-- Department self-reference for manager
ALTER TABLE departments
ADD CONSTRAINT fk_dept_manager
FOREIGN KEY (manager_id) REFERENCES users(user_id);

-- Job Requisition foreign keys
ALTER TABLE job_requisitions
ADD CONSTRAINT fk_req_department
FOREIGN KEY (department_id) REFERENCES departments(department_id);

ALTER TABLE job_requisitions
ADD CONSTRAINT fk_req_job
FOREIGN KEY (job_id) REFERENCES job_positions(job_id);

ALTER TABLE job_requisitions
ADD CONSTRAINT fk_req_requested_by
FOREIGN KEY (requested_by) REFERENCES users(user_id);

ALTER TABLE job_requisitions
ADD CONSTRAINT fk_req_approved_by
FOREIGN KEY (approved_by) REFERENCES users(user_id);

-- Job Posting foreign keys
ALTER TABLE job_postings
ADD CONSTRAINT fk_posting_requisition
FOREIGN KEY (requisition_id) REFERENCES job_requisitions(requisition_id);

ALTER TABLE job_postings
ADD CONSTRAINT fk_posting_created_by
FOREIGN KEY (created_by) REFERENCES users(user_id);

-- Application foreign keys
ALTER TABLE applications
ADD CONSTRAINT fk_app_posting
FOREIGN KEY (posting_id) REFERENCES job_postings(posting_id);

ALTER TABLE applications
ADD CONSTRAINT fk_app_applicant
FOREIGN KEY (applicant_id) REFERENCES applicants(applicant_id);

-- Interview foreign keys
ALTER TABLE interviews
ADD CONSTRAINT fk_interview_application
FOREIGN KEY (application_id) REFERENCES applications(application_id);

ALTER TABLE interviews
ADD CONSTRAINT fk_interview_interviewer
FOREIGN KEY (interviewer_id) REFERENCES users(user_id);

-- Job Offer foreign keys
ALTER TABLE job_offers
ADD CONSTRAINT fk_offer_application
FOREIGN KEY (application_id) REFERENCES applications(application_id);

ALTER TABLE job_offers
ADD CONSTRAINT fk_offer_prepared_by
FOREIGN KEY (prepared_by) REFERENCES users(user_id);

ALTER TABLE job_offers
ADD CONSTRAINT fk_offer_approved_by
FOREIGN KEY (approved_by) REFERENCES users(user_id);

-- Employee foreign keys
ALTER TABLE employees
ADD CONSTRAINT fk_emp_applicant
FOREIGN KEY (applicant_id) REFERENCES applicants(applicant_id);

ALTER TABLE employees
ADD CONSTRAINT fk_emp_department
FOREIGN KEY (department_id) REFERENCES departments(department_id);

ALTER TABLE employees
ADD CONSTRAINT fk_emp_job
FOREIGN KEY (job_id) REFERENCES job_positions(job_id);

ALTER TABLE employees
ADD CONSTRAINT fk_emp_supervisor
FOREIGN KEY (supervisor_id) REFERENCES employees(employee_id);

-- User foreign keys
ALTER TABLE users
ADD CONSTRAINT fk_user_department
FOREIGN KEY (department_id) REFERENCES departments(department_id);

-- Activity Log foreign keys
ALTER TABLE activity_logs
ADD CONSTRAINT fk_log_user
FOREIGN KEY (user_id) REFERENCES users(user_id);

-- Add unique constraints
ALTER TABLE job_postings
ADD CONSTRAINT uq_job_posting_requisition
UNIQUE (requisition_id, posting_status);

-- Add check constraints for date validations
ALTER TABLE job_requisitions
ADD CONSTRAINT ck_req_dates
CHECK (target_hire_date >= request_date);

ALTER TABLE job_postings
ADD CONSTRAINT ck_posting_dates
CHECK (closing_date >= publishing_date);
