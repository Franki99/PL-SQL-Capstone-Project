-- Create Holiday Table
CREATE TABLE public_holidays (
    holiday_id NUMBER PRIMARY KEY,
    holiday_date DATE NOT NULL,
    holiday_name VARCHAR2(100) NOT NULL,
    description VARCHAR2(255),
    created_date DATE DEFAULT SYSDATE,
    created_by VARCHAR2(50) DEFAULT USER
);

-- Create sequence for the holiday table
CREATE SEQUENCE public_holidays_seq START WITH 1 INCREMENT BY 1;

-- Insert public holidays for the upcoming month (June 2025 in this example)
BEGIN
    -- Rwanda Heroes' Day (February 1) - shifted to June for this example
    INSERT INTO public_holidays (
        holiday_id, holiday_date, holiday_name, description
    ) VALUES (
        public_holidays_seq.NEXTVAL, 
        TO_DATE('2025-06-01', 'YYYY-MM-DD'),
        'Heroes Day',
        'National holiday commemorating the heroes of Rwanda'
    );

    -- Rwanda Liberation Day (July 4) - shifted to June for this example
    INSERT INTO public_holidays (
        holiday_id, holiday_date, holiday_name, description
    ) VALUES (
        public_holidays_seq.NEXTVAL, 
        TO_DATE('2025-06-15', 'YYYY-MM-DD'),
        'Liberation Day',
        'National holiday celebrating Rwanda''s liberation'
    );

    -- Umuganura Day (August 5) - shifted to June for this example
    INSERT INTO public_holidays (
        holiday_id, holiday_date, holiday_name, description
    ) VALUES (
        public_holidays_seq.NEXTVAL, 
        TO_DATE('2025-06-25', 'YYYY-MM-DD'),
        'Umuganura Day',
        'National harvest thanksgiving day'
    );
    
    COMMIT;
END;
/

-- Create an index on holiday_date for faster lookups
CREATE INDEX idx_holiday_date ON public_holidays(holiday_date);

-- Display the holidays
SELECT * FROM public_holidays;