-- ============================================================
-- fn_login_customer
-- Screen: Customer > Log in
-- Used by: the customer login form.
-- Verifies the password by re-hashing it with the stored hash as
-- salt: crypt(input, stored_hash) = stored_hash only when the
-- password is correct (standard bcrypt check, no plaintext compared).
-- Returns the customer's row on success, and NO rows on a wrong
-- email or password — the app treats an empty result as a failed
-- login. Deliberately does not reveal WHICH of the two was wrong.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_login_customer(
    p_email    VARCHAR,
    p_password TEXT
)
RETURNS TABLE (
    customer_id INT,
    name        VARCHAR,
    email       VARCHAR,
    phone       VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c.customer_id,
           c.name,
           c.email,
           c.phone
    FROM customer c
    WHERE lower(c.email) = lower(btrim(p_email))
      AND c.password_hash = crypt(p_password, c.password_hash);
END;
$$;

-- Example call (succeeds, sample-data password is 'password123'):
SELECT * FROM fn_login_customer('nattapong@example.com', 'password123');
-- Example call (wrong password: returns 0 rows):
SELECT * FROM fn_login_customer('nattapong@example.com', 'wrongpass');
