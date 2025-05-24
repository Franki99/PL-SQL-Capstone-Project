-- Insert Interviews
INSERT INTO interviews (
    interview_id, application_id, interview_type, interview_date, interview_location,
    interviewer_id, interview_status, overall_rating, technical_skills_rating,
    communication_rating, cultural_fit_rating, interview_notes, recommendation
)
VALUES (
    interviews_seq.NEXTVAL, 1, 'Technical', TO_DATE('2025-05-05', 'YYYY-MM-DD'), 
    'Ihuzo Office, Room 302', 1, 'Completed', 4.2, 4.5, 4.0, 4.0,
    'Candidate demonstrated strong technical skills in Java and React. Good problem-solving approach. Communication was clear, but could be more concise. Showed enthusiasm for the company culture.',
    'Hire'
);