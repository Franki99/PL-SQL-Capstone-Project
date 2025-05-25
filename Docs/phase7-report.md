# Ihuzo HR System - Phase 7: Advanced Database Programming and Auditing

## Problem Statement

The Ihuzo HR System contains sensitive employee and recruitment data that requires strict protection and compliance with organizational policies. As the system manages personal information, job applications, and hiring decisions, unauthorized or off-hours modifications to this data could lead to:

1. Data integrity issues affecting recruitment decisions
2. Potential breaches of candidate confidentiality
3. Unauthorized changes to salary, benefits, or employment terms
4. Loss of audit trail for compliance requirements

To maintain data integrity and security, the HR department has implemented a policy that restricts database modifications during standard business hours (Monday to Friday) when administrators may be occupied with other tasks and unable to monitor system changes. Additionally, system maintenance is not permitted during public holidays to ensure system stability during periods when technical support may be limited.

These restrictions must be enforced at the database level to prevent accidental or unauthorized modifications, regardless of the front-end application used to access the data.

## Implementation Overview

### 1. Holiday Table

A reference table `public_holidays` was created to store upcoming public holidays during which database modifications should be restricted. The table includes:

- Holiday date
- Holiday name
- Description
- Creation metadata

### 2. Audit Table

A comprehensive audit table `hr_audit_log` was implemented to track all database activities, including:

- User information
- Operation type (INSERT, UPDATE, DELETE)
- Table and record affected
- Old and new values for updates
- Operation status (ALLOWED, DENIED)
- Denial reason when applicable
- Environmental information (client info, IP address, OS user)

### 3. Restriction Logic

Database modifications are restricted based on two criteria:

- **Time-based restriction**: Operations are blocked on weekdays (Monday to Friday)
- **Holiday-based restriction**: Operations are blocked on public holidays in the upcoming month

This logic is implemented through:

- A helper function `is_restricted_time()` that checks current date conditions
- Triggers that evaluate the function before allowing modifications

### 4. Trigger Implementation

#### Simple Triggers

Simple triggers were created for critical HR tables to enforce the time-based restrictions:

- `trg_restrict_applicants`
- `trg_restrict_applications`
- `trg_restrict_employees`
- `trg_restrict_job_offers`
- `trg_restrict_users`

Each trigger:

1. Evaluates if the current time is restricted
2. Logs denied operations to the audit table
3. Raises an error with appropriate message to prevent the operation

#### Compound Trigger

A compound trigger `trg_salary_audit_compound` was implemented for salary-related operations on the `job_positions` table. This trigger:

1. Evaluates restriction at the statement level
2. Performs detailed logging for salary changes
3. Raises appropriate errors to prevent operations during restricted times
4. Provides audit trail for both allowed and denied operations

### 5. Audit Package

A comprehensive audit package `hr_audit_pkg` was developed to centralize auditing functionality:

#### Key Components:

- **Constants and Types**: Standardized record formats and value limits
- **Logging Procedures**: Centralized audit trail creation
- **Restriction Check**: Reusable function to evaluate time restrictions
- **Reporting Functions**: Ability to generate audit reports by table, user, or status

#### Main Features:

- Autonomous transactions for audit logging to ensure audit trail persistence
- Value truncation to handle large data fields
- Exception handling to prevent audit failures from affecting main operations
- Comprehensive reporting capabilities

## Testing Results

The implementation was tested under various conditions:

### Time-Based Restriction Tests

- **Weekday Test**: Operations were correctly blocked during weekday hours
- **Weekend Test**: Operations were properly allowed during weekend hours
- **Holiday Test**: Operations were correctly blocked on simulated public holidays

### Auditing Tests

- **Denied Operations**: All denied operations were properly logged with reasons
- **Allowed Operations**: Permitted operations were logged with appropriate details
- **Manual Audit Entry**: The audit package successfully accepted manual log entries

### Compound Trigger Test

- The compound trigger correctly identified and blocked salary changes during restricted times
- Detailed audit logs were created for attempted salary modifications

## Security Enhancements

This implementation enhances the Ihuzo HR System security in several ways:

1. **Enforced Policy Compliance**: System-level enforcement of operational time windows
2. **Comprehensive Audit Trail**: Complete record of all data modifications and attempts
3. **Detailed Change Tracking**: Granular logging of field-level changes for sensitive data
4. **Centralized Security Logic**: Consistent application of security rules through packages
5. **Environmental Awareness**: Capturing of client context for forensic purposes

## Screenshots

![Weekday Restriction](./screenshots/weekday_restriction.png)
![Holiday Restriction](./screenshots/holiday_restriction.png)
![Audit Logs](./screenshots/audit_logs.png)
![Package Execution](./screenshots/package_execution.png)
