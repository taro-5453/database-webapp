-- ============================================================
-- fn_register_customer
-- Screen: Customer > Sign up
-- Used by: the registration form.
-- Hashes the password with bcrypt (pgcrypto's crypt + gen_salt('bf'))
-- so no plaintext password is ever stored. Rejects duplicate emails
-- with a readable message instead of a raw unique-constraint error.
-- Also creates the customer's membership row (0 points, standard tier)
-- so the profile screen works right after signup.
-- Returns the new customer_id.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_register_customer(
    p_name     VARCHAR,
    p_email    VARCHAR,
    p_phone    VARCHAR,
    p_password TEXT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_id INT;
BEGIN
    IF p_name IS NULL OR btrim(p_name) = '' THEN
        RAISE EXCEPTION 'Name is required';
    END IF;

    IF p_email IS NULL OR btrim(p_email) = '' THEN
        RAISE EXCEPTION 'Email is required';
    END IF;

    IF p_password IS NULL OR length(p_password) < 8 THEN
        RAISE EXCEPTION 'Password must be at least 8 characters';
    END IF;

    -- emails are stored lowercased so login is case-insensitive
    IF EXISTS (SELECT 1 FROM customer c
               WHERE lower(c.email) = lower(btrim(p_email))) THEN
        RAISE EXCEPTION 'Email % is already registered', btrim(p_email);
    END IF;

    INSERT INTO customer (name, email, phone, password_hash)
    VALUES (btrim(p_name),
            lower(btrim(p_email)),
            p_phone,
            crypt(p_password, gen_salt('bf')))   -- bcrypt hash
    RETURNING customer_id INTO v_customer_id;

    INSERT INTO membership (customer_id, points, tier)
    VALUES (v_customer_id, 0, 'standard');

    RETURN v_customer_id;
END;
$$;

-- Example call:
SELECT fn_register_customer('Test User', 'test.user@example.com', '081-000-0099', 'supersecret1');
-- Example call (should FAIL: duplicate email):
SELECT fn_register_customer('Someone Else', 'nattapong@example.com', NULL, 'supersecret1');
-- Example call (should FAIL: password too short):
SELECT fn_register_customer('Short Pass', 'short@example.com', NULL, 'abc');
