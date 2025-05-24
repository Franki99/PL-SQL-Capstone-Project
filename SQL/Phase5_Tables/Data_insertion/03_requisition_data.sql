-- Insert Job Posting
INSERT INTO job_postings (
    posting_id,
    requisition_id,
    posting_title,
    posting_status,
    publishing_date,
    closing_date,
    is_internal,
    created_by
)
VALUES (
    job_postings_seq.NEXTVAL,
    34, -- Use the exact requisition_id from your query
    'Software Developer Position',
    'Published',
    SYSDATE,
    SYSDATE + 30,
    0,
    22 -- Alice Uwase (user_id)
);

COMMIT;