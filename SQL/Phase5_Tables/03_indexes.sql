-- Create indexes for frequently queried columns

-- Department indexes
CREATE INDEX idx_dept_name ON departments(department_name);

-- Job Position indexes
CREATE INDEX idx_job_title ON job_positions(job_title);
CREATE INDEX idx_job_salary_range ON job_positions(min_salary, max_salary);

-- Job Requisition indexes
CREATE INDEX idx_req_status ON job_requisitions(approval_status);
CREATE INDEX idx_req_department ON job_requisitions(department_id);
CREATE INDEX idx_req_priority ON job_requisitions(priority);
CREATE INDEX idx_req_dates ON job_requisitions(request_date, target_hire_date);

-- Job Posting indexes
CREATE INDEX idx_posting_status ON job_postings(posting_status);
CREATE INDEX idx_posting_dates ON job_postings(publishing_date, closing_date);
CREATE INDEX idx_posting_internal ON job_postings(is_internal);

-- Applicant indexes
CREATE INDEX idx_applicant_name ON applicants(first_name, last_name);
CREATE INDEX idx_applicant_email ON applicants(email);
CREATE INDEX idx_applicant_experience ON applicants(years_of_experience);
CREATE INDEX idx_applicant_education ON applicants(highest_degree);

-- Application indexes
CREATE INDEX idx_application_status ON applications(application_status);
CREATE INDEX idx_application_score ON applications(matching_score);
CREATE INDEX idx_application_date ON applications(submission_date);

-- Interview indexes
CREATE INDEX idx_interview_date ON interviews(interview_date);
CREATE INDEX idx_interview_status ON interviews(interview_status);
CREATE INDEX idx_interview_rating ON interviews(overall_rating);
CREATE INDEX idx_interview_recommendation ON interviews(recommendation);

-- Job Offer indexes
CREATE INDEX idx_offer_status ON job_offers(offer_status);
CREATE INDEX idx_offer_salary ON job_offers(offered_salary);
CREATE INDEX idx_offer_dates ON job_offers(start_date, offer_expiration_date);

-- Employee indexes
CREATE INDEX idx_employee_department ON employees(department_id);
CREATE INDEX idx_employee_job ON employees(job_id);
CREATE INDEX idx_employee_status ON employees(employment_status);
CREATE INDEX idx_employee_hire_date ON employees(hire_date);

-- User indexes
CREATE INDEX idx_user_role ON users(user_role);
CREATE INDEX idx_user_department ON users(department_id);
CREATE INDEX idx_user_status ON users(account_status);

-- Activity Log indexes
CREATE INDEX idx_log_date ON activity_logs(activity_date);
CREATE INDEX idx_log_type ON activity_logs(activity_type);
CREATE INDEX idx_log_entity ON activity_logs(related_entity, related_entity_id);