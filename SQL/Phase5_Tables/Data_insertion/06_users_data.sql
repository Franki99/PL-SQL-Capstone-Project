-- Insert users
INSERT INTO users (
    user_id, username, password_hash, first_name, last_name, email, department_id, user_role
)
VALUES (
    users_seq.NEXTVAL, 'jmutabazi', 'hashed_password', 'Jean', 'Mutabazi', 'jmutabazi@ihuzo.com', 
    (SELECT department_id FROM departments WHERE department_name = 'Information Technology'), 
    'Department Manager'
);

INSERT INTO users (
    user_id, username, password_hash, first_name, last_name, email, department_id, user_role
)
VALUES (
    users_seq.NEXTVAL, 'auwase', 'hashed_password', 'Alice', 'Uwase', 'auwase@ihuzo.com', 
    (SELECT department_id FROM departments WHERE department_name = 'Human Resources'), 
    'HR Recruitment'
);

COMMIT;