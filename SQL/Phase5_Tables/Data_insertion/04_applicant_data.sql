-- Insert Applicants
INSERT INTO applicants (
    applicant_id, first_name, last_name, email, phone, address, city, country,
    national_id, highest_degree, years_of_experience, current_employer, current_position,
    skills, resume_file_path, registration_date
)
VALUES (
    applicants_seq.NEXTVAL, 'Olivier', 'Ndayisaba', 'ondayisaba@email.com', '+250781234567',
    '123 Kigali Road', 'Kigali', 'Rwanda', '1199080012345678', 'Bachelor in Computer Science',
    5, 'TechRwanda', 'Software Engineer',
    'Java, Spring, React, SQL, Git', '/resumes/ondayisaba_resume.pdf', 
    TO_DATE('2025-04-21', 'YYYY-MM-DD')
);

INSERT INTO applicants (
    applicant_id, first_name, last_name, email, phone, address, city, country,
    national_id, highest_degree, years_of_experience, current_employer, current_position,
    skills, resume_file_path, registration_date
)
VALUES (
    applicants_seq.NEXTVAL, 'Marie', 'Mukamana', 'mmukamana@email.com', '+250722345678',
    '456 Huye Street', 'Huye', 'Rwanda', '1198070023456789', 'Master in Computer Science',
    7, 'RwandaIT Solutions', 'Senior Developer',
    'Java, Python, React, Angular, NoSQL, SQL, Cloud Architecture', '/resumes/mmukamana_resume.pdf', 
    TO_DATE('2025-04-22', 'YYYY-MM-DD')
);

INSERT INTO applicants (
    applicant_id, first_name, last_name, email, phone, address, city, country,
    national_id, highest_degree, years_of_experience, current_employer, current_position,
    skills, resume_file_path, registration_date
)
VALUES (
    applicants_seq.NEXTVAL, 'Jean', 'Bizimana', 'jbizimana@email.com', '+250733456789',
    '789 Musanze Avenue', 'Musanze', 'Rwanda', '1199050034567890', 'Bachelor in Information Systems',
    4, 'DataSystems Rwanda', 'Database Administrator',
    'Oracle, SQL, PL/SQL, Database Design, Performance Tuning, Backup and Recovery', '/resumes/jbizimana_resume.pdf', 
    TO_DATE('2025-04-11', 'YYYY-MM-DD')
);

INSERT INTO applicants (
    applicant_id, first_name, last_name, email, phone, address, city, country,
    national_id, highest_degree, years_of_experience, current_employer, current_position,
    skills, resume_file_path, registration_date
)
VALUES (
    applicants_seq.NEXTVAL, 'Patricia', 'Uwimana', 'puwimana@email.com', '+250744567890',
    '101 Rubavu Road', 'Rubavu', 'Rwanda', '1200010045678901', 'Bachelor in Marketing',
    3, 'Digital Marketing Rwanda', 'Marketing Associate',
    'Digital Marketing, Social Media, Content Creation, SEO, Analytics', '/resumes/puwimana_resume.pdf', 
    TO_DATE('2025-04-26', 'YYYY-MM-DD')
);

INSERT INTO applicants (
    applicant_id, first_name, last_name, email, phone, address, city, country,
    national_id, highest_degree, years_of_experience, current_employer, current_position,
    skills, resume_file_path, registration_date
)
VALUES (
    applicants_seq.NEXTVAL, 'Emmanuel', 'Hakizimana', 'ehakizimana@email.com', '+250755678901',
    '202 Nyamata Street', 'Nyamata', 'Rwanda', '1197120056789012', 'Master in Database Management',
    6, 'Tech Solutions Africa', 'Database Manager',
    'Oracle, SQL Server, MySQL, MongoDB, ETL, Data Warehousing', '/resumes/ehakizimana_resume.pdf', 
    TO_DATE('2025-04-12', 'YYYY-MM-DD')
);

INSERT INTO applicants (
    applicant_id, first_name, last_name, email, phone, address, city, country,
    national_id, highest_degree, years_of_experience, current_employer, current_position,
    skills, resume_file_path, registration_date
)
VALUES (
    applicants_seq.NEXTVAL, 'Diane', 'Mugisha', 'dmugisha@email.com', '+250766789012',
    '303 Nyagatare Avenue', 'Nyagatare', 'Rwanda', '1198090067890123', 'Bachelor in Computer Engineering',
    4, 'Rwanda Software Solutions', 'Software Developer',
    'Java, Spring Boot, React, JavaScript, Git, CI/CD', '/resumes/dmugisha_resume.pdf', 
    TO_DATE('2025-04-23', 'YYYY-MM-DD')
);