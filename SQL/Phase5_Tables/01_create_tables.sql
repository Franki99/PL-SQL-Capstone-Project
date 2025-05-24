-- 01_create_tables.sql
-- Connect to your database
CONNECT Divanni/Aguerokun10@localhost:1521/B_25312_Divanni_IhuzoHR_DB

-- Department table
CREATE TABLE departments (
    department_id NUMBER PRIMARY KEY,
    department_name VARCHAR2(100) NOT NULL,
    location VARCHAR2(100),
    manager_id NUMBER,
    created_date DATE DEFAULT SYSDATE,
    modified_date DATE DEFAULT SYSDATE
);

-- Job Position table
CREATE TABLE job_positions (
    job_id NUMBER PRIMARY KEY,
    job_title VARCHAR2(100) NOT NULL,
    job_description CLOB,
    min_salary NUMBER,
    max_salary NUMBER,
    created_date DATE DEFAULT SYSDATE,
    modified_date DATE DEFAULT SYSDATE
);

-- Job Requisition table
CREATE TABLE job_requisitions (
    requisition_id NUMBER PRIMARY KEY,
    department_id NUMBER NOT NULL,
    job_id NUMBER NOT NULL,
    requested_by NUMBER NOT NULL,
    approval_status VARCHAR2(20) DEFAULT 'Pending' 
        CHECK (approval_status IN ('Pending', 'Approved', 'Rejected')),
    number_of_positions NUMBER DEFAULT 1,
    required_skills VARCHAR2(500),
    required_experience NUMBER, -- in years
    education_requirements VARCHAR2(200),
    special_requirements VARCHAR2(500),
    priority VARCHAR2(20) CHECK (priority IN ('Low', 'Medium', 'High', 'Urgent')),
    request_date DATE DEFAULT SYSDATE,
    target_hire_date DATE,
    approved_by NUMBER,
    approval_date DATE,
    created_date DATE DEFAULT SYSDATE,
    modified_date DATE DEFAULT SYSDATE
);

-- Job Posting table
CREATE TABLE job_postings (
    posting_id NUMBER PRIMARY KEY,
    requisition_id NUMBER NOT NULL,
    posting_title VARCHAR2(200) NOT NULL,
    posting_description CLOB,
    posting_status VARCHAR2(20) DEFAULT 'Draft' 
        CHECK (posting_status IN ('Draft', 'Published', 'Closed')),
    publishing_date DATE,
    closing_date DATE,
    is_internal NUMBER(1) DEFAULT 0 CHECK (is_internal IN (0, 1)), -- 0=external, 1=internal
    created_by NUMBER NOT NULL,
    created_date DATE DEFAULT SYSDATE,
    modified_date DATE DEFAULT SYSDATE
);

-- Applicant table
CREATE TABLE applicants (
    applicant_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) NOT NULL UNIQUE,
    phone VARCHAR2(20),
    address VARCHAR2(200),
    city VARCHAR2(50),
    country VARCHAR2(50),
    national_id VARCHAR2(50),
    highest_degree VARCHAR2(50),
    years_of_experience NUMBER,
    current_employer VARCHAR2(100),
    current_position VARCHAR2(100),
    skills VARCHAR2(500),
    resume_file_path VARCHAR2(255),
    registration_date DATE DEFAULT SYSDATE,
    last_login_date DATE,
    account_status VARCHAR2(20) DEFAULT 'Active' 
        CHECK (account_status IN ('Active', 'Inactive', 'Blocked')),
    created_date DATE DEFAULT SYSDATE,
    modified_date DATE DEFAULT SYSDATE
);

-- Application table
CREATE TABLE applications (
    application_id NUMBER PRIMARY KEY,
    posting_id NUMBER NOT NULL,
    applicant_id NUMBER NOT NULL,
    application_status VARCHAR2(30) DEFAULT 'Submitted' 
        CHECK (application_status IN ('Submitted', 'Screening', 'Shortlisted', 'Interviewed', 'Offered', 'Hired', 'Rejected', 'Withdrawn')),
    matching_score NUMBER(5,2), -- Algorithm-calculated score based on job fit
    cover_letter CLOB,
    additional_documents VARCHAR2(500), -- Comma-separated list of document paths
    submission_date DATE DEFAULT SYSDATE,
    last_status_change DATE DEFAULT SYSDATE,
    created_date DATE DEFAULT SYSDATE,
    modified_date DATE DEFAULT SYSDATE
);

-- Interview table
CREATE TABLE interviews (
    interview_id NUMBER PRIMARY KEY,
    application_id NUMBER NOT NULL,
    interview_type VARCHAR2(30) CHECK (interview_type IN ('Phone', 'Video', 'In-Person', 'Technical', 'Panel')),
    interview_date DATE,
    interview_location VARCHAR2(200),
    interviewer_id NUMBER NOT NULL, -- Department Manager or HR personnel
    interview_status VARCHAR2(30) DEFAULT 'Scheduled' 
        CHECK (interview_status IN ('Scheduled', 'Completed', 'Canceled', 'Rescheduled')),
    overall_rating NUMBER(3,1), -- Scale of 1-5
    technical_skills_rating NUMBER(3,1),
    communication_rating NUMBER(3,1),
    cultural_fit_rating NUMBER(3,1),
    interview_notes CLOB,
    recommendation VARCHAR2(30) CHECK (recommendation IN ('Strong Hire', 'Hire', 'Neutral', 'Do Not Hire')),
    created_date DATE DEFAULT SYSDATE,
    modified_date DATE DEFAULT SYSDATE
);

-- Job Offer table
CREATE TABLE job_offers (
    offer_id NUMBER PRIMARY KEY,
    application_id NUMBER NOT NULL,
    offered_salary NUMBER NOT NULL,
    offered_position VARCHAR2(100) NOT NULL,
    start_date DATE,
    offer_expiration_date DATE,
    offer_status VARCHAR2(30) DEFAULT 'Prepared' 
        CHECK (offer_status IN ('Prepared', 'Sent', 'Accepted', 'Rejected', 'Expired', 'Withdrawn')),
    offer_letter_path VARCHAR2(255),
    benefits_package VARCHAR2(500),
    prepared_by NUMBER NOT NULL, -- HR personnel
    approved_by NUMBER NOT NULL, -- Department Manager
    created_date DATE DEFAULT SYSDATE,
    modified_date DATE DEFAULT SYSDATE
);

-- Employee table (for hired applicants)
CREATE TABLE employees (
    employee_id NUMBER PRIMARY KEY,
    applicant_id NUMBER NOT NULL,
    department_id NUMBER NOT NULL,
    job_id NUMBER NOT NULL,
    hire_date DATE NOT NULL,
    supervisor_id NUMBER,
    salary NUMBER NOT NULL,
    email VARCHAR2(100) NOT NULL UNIQUE,
    employment_status VARCHAR2(30) DEFAULT 'Active' 
        CHECK (employment_status IN ('Active', 'On Leave', 'Terminated')),
    created_date DATE DEFAULT SYSDATE,
    modified_date DATE DEFAULT SYSDATE
);

-- Users table (for system users)
CREATE TABLE users (
    user_id NUMBER PRIMARY KEY,
    username VARCHAR2(50) NOT NULL UNIQUE,
    password_hash VARCHAR2(255) NOT NULL,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) NOT NULL UNIQUE,
    department_id NUMBER,
    user_role VARCHAR2(30) NOT NULL 
        CHECK (user_role IN ('Department Manager', 'HR Recruitment', 'System Administrator')),
    account_status VARCHAR2(20) DEFAULT 'Active' 
        CHECK (account_status IN ('Active', 'Inactive', 'Locked')),
    last_login_date DATE,
    created_date DATE DEFAULT SYSDATE,
    modified_date DATE DEFAULT SYSDATE
);

-- Activity Log table (for tracking system activities)
CREATE TABLE activity_logs (
    log_id NUMBER PRIMARY KEY,
    user_id NUMBER,
    activity_type VARCHAR2(50) NOT NULL,
    activity_description VARCHAR2(500) NOT NULL,
    ip_address VARCHAR2(50),
    activity_date TIMESTAMP DEFAULT SYSTIMESTAMP,
    related_entity VARCHAR2(50), -- e.g., 'application', 'job_posting', etc.
    related_entity_id NUMBER,
    created_date DATE DEFAULT SYSDATE
);

-- Create sequence for each table
CREATE SEQUENCE departments_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE job_positions_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE job_requisitions_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE job_postings_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE applicants_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE applications_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE interviews_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE job_offers_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE employees_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE users_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE activity_logs_seq START WITH 1 INCREMENT BY 1;