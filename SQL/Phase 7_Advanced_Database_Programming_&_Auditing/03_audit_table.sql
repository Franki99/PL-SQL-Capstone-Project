-- Create Audit Table
CREATE TABLE hr_audit_log (
    audit_id NUMBER PRIMARY KEY,
    username VARCHAR2(50) NOT NULL,
    operation_type VARCHAR2(20) NOT NULL, -- INSERT, UPDATE, DELETE
    table_name VARCHAR2(50) NOT NULL,
    record_id VARCHAR2(50), -- Primary key value of affected record
    column_name VARCHAR2(50), -- Column that was changed (for updates)
    old_value VARCHAR2(4000), -- Previous value (for updates and deletes)
    new_value VARCHAR2(4000), -- New value (for inserts and updates)
    operation_date TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    operation_status VARCHAR2(20) DEFAULT 'ALLOWED' NOT NULL, -- ALLOWED, DENIED
    denial_reason VARCHAR2(255), -- Reason if operation was denied
    client_info VARCHAR2(255), -- Application info
    ip_address VARCHAR2(50), -- IP address if available
    os_user VARCHAR2(50) -- Operating system user
);

-- Create sequence for the audit table
CREATE SEQUENCE hr_audit_seq START WITH 1 INCREMENT BY 1;

-- Create index on common query fields
CREATE INDEX idx_audit_username ON hr_audit_log(username);
CREATE INDEX idx_audit_operation_date ON hr_audit_log(operation_date);
CREATE INDEX idx_audit_table_name ON hr_audit_log(table_name);
CREATE INDEX idx_audit_operation_status ON hr_audit_log(operation_status);