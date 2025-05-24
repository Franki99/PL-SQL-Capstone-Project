-- Update department IDs for users without departments
UPDATE users 
SET department_id = 21 -- Information Technology
WHERE first_name = 'Jean' AND last_name = 'Mutabazi';

UPDATE users 
SET department_id = 22 -- Human Resources
WHERE first_name = 'Alice' AND last_name = 'Uwase';

COMMIT;