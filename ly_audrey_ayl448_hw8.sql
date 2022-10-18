-- Audrey Ly
--ayl448

-- Q1
-- Customer and customer_acquisition do not have any of the same fields,
-- because although they both have some of the same types of data (first name, 
-- last name, email, phone, etc), the fields are named differently.

DROP VIEW customer_acquisition_view;

CREATE VIEW customer_acquisition_view AS
SELECT acquired_customer_id, ca_first_name, ca_last_name, ca_email, ca_phone, ca_zip_code,
    0 AS credits_used,
    ca_credits_remaining/2 AS credits_earned
FROM customer_acquisition;

--Q2
CREATE TABLE customer_dw
(
    customer_id NUMBER,
    first_name VARCHAR(40),
    last_name VARCHAR(40),
    email VARCHAR(40),
    phone CHAR(12),
    zip CHAR(5),
    stay_credits_earned NUMBER, 
    stay_credits_used NUMBER,
    data_source CHAR(4),
    CONSTRAINT data_source_cust_pk primary key (data_source, customer_id)
);

--Q3
CREATE VIEW customer_view AS
    SELECT customer_id, first_name, last_name, email, phone, zip,
    stay_credits_earned, stay_credits_used
FROM customer;

CREATE VIEW customer_acquisition_view AS
SELECT acquired_customer_id AS customer_id, ca_first_name AS first_name, ca_last_name AS last_name, ca_email AS email, 
            SUBSTR(ca_phone, 2, 3) || '-' || 
            SUBSTR(ca_phone, 6, 8) AS phone, ca_zip_code AS zip,
    ca_credits_remaining AS credits_remaining
FROM customer_acquisition;

--Q4
CREATE OR REPLACE PROCEDURE customer_etl_proc
AS 
BEGIN
    INSERT INTO customers_dw
        SELECT dw.customer_id, dw.first_name, dw.last_name, dw.email, dw.phone, dw.zip,
    dw.stay_credits_earned, dw.stay_credits_used
FROM customer_view exv LEFT JOIN customers_dw dw
    ON exv.customer_id = dw.customer_dw
    WHERE dw.customer_id IS NULL;
    
    INSERT INTO customers_dw
        SELECT cav.customer_id, cav.first_name, cav.last_name, cav.email, cav.phone, cav.zip,
    cav.stay_credits_earned, cav.stay_credits_used --change ca_ to just first_name in cav (match to customer dw table)
FROM customer_acquisition_view cav LEFT JOIN customers_dw dw
    ON cav.customer_id = dw.customer_dw
    WHERE cav.customer_id IS NULL;
    
MERGE INTO customer_dw dw
    USING customer_acquisition_view cav
    ON (dw.customer_id = cav.customer_id) 
    --and dw.data_source = 'NEW')
    WHEN MATCHED THEN
    UPDATE SET dw.customer_id = cav.customer_id,
               dw.first_name = cav.first_name, 
               dw.last_name = cav.customer_last_name,
               dw.email = cav.email,
               dw.phone = cav.phone,
               dw.zip = cav.zip,
               dw.stay_credits_earned = cav.stay_credits_earned 
               dw.stay_credits_used = cav.stay_credits_used ;
END;
/

select * from customer_dw;

select * from customer_view;
