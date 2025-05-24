-- Insert Applicants one by one with commits after each
INSERT INTO applicants (
    applicant_id, first_name, last_name, email, phone, 
    highest_degree, years_of_experience, current_employer, current_position,
    skills, registration_date
)
VALUES (
    applicants_seq.NEXTVAL, 'Olivier', 'Ndayisaba', 'ondayisaba@email.com', '+250781234567',
    'Bachelor in Computer Science', 5, 'TechRwanda', 'Software Engineer',
    'Java, Spring, React, SQL, Git', TO_DATE('2025-04-21', 'YYYY-MM-DD')
);
COMMIT;

INSERT INTO applicants (
    applicant_id, first_name, last_name, email, phone, 
    highest_degree, years_of_experience, current_employer, current_position,
    skills, registration_date
)
VALUES (
    applicants_seq.NEXTVAL, 'Marie', 'Mukamana', 'mmukamana@email.com', '+250722345678',
    'Master in Computer Science', 7, 'RwandaIT Solutions', 'Senior Developer',
    'Java, Python, React, Angular, NoSQL, SQL', TO_DATE('2025-04-22', 'YYYY-MM-DD')
);
COMMIT;

INSERT INTO applicants (
    applicant_id, first_name, last_name, email, phone, 
    highest_degree, years_of_experience, current_employer, current_position,
    skills, registration_date
)
VALUES (
    applicants_seq.NEXTVAL, 'Jean', 'Bizimana', 'jbizimana@email.com', '+250733456789',
    'Bachelor in Information Systems', 4, 'DataSystems Rwanda', 'Database Administrator',
    'Oracle, SQL, PL/SQL, Database Design', TO_DATE('2025-04-11', 'YYYY-MM-DD')
);
COMMIT;

INSERT INTO applicants (
    applicant_id, first_name, last_name, email, phone, 
    highest_degree, years_of_experience, current_employer, current_position,
    skills, registration_date
)
VALUES (
    applicants_seq.NEXTVAL, 'Patricia', 'Uwimana', 'puwimana@email.com', '+250744567890',
    'Bachelor in Marketing', 3, 'Digital Marketing Rwanda', 'Marketing Associate',
    'Digital Marketing, Social Media, Content Creation', TO_DATE('2025-04-26', 'YYYY-MM-DD')
);
COMMIT;

INSERT INTO applicants (
    applicant_id, first_name, last_name, email, phone, 
    highest_degree, years_of_experience, current_employer, current_position,
    skills, registration_date
)
VALUES (
    applicants_seq.NEXTVAL, 'Emmanuel', 'Hakizimana', 'ehakizimana@email.com', '+250755678901',
    'Master in Database Management', 6, 'Tech Solutions Africa', 'Database Manager',
    'Oracle, SQL Server, MySQL, MongoDB', TO_DATE('2025-04-12', 'YYYY-MM-DD')
);
COMMIT;

INSERT INTO applicants (
    applicant_id, first_name, last_name, email, phone, 
    highest_degree, years_of_experience, current_employer, current_position,
    skills, registration_date
)
VALUES (
    applicants_seq.NEXTVAL, 'Diane', 'Mugisha', 'dmugisha@email.com', '+250766789012',
    'Bachelor in Computer Engineering', 4, 'Rwanda Software Solutions', 'Software Developer',
    'Java, Spring Boot, React, JavaScript', TO_DATE('2025-04-23', 'YYYY-MM-DD')
);
COMMIT;