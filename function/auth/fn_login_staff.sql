-- ============================================================
-- fn_login_staff
-- Screen: Staff > Log in
-- Used by: the staff login form.
-- STAFF has no email column, so staff log in with their name.
-- Same bcrypt check as fn_login_customer. Returns the staff row
-- (including branch_id and role, which the app needs to route to
-- the right staff screens) on success, and NO rows on failure.
-- If two staff ever shared a name, only the one whose password
-- matches is returned.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_login_staff(
    p_name     VARCHAR,
    p_password TEXT
)
RETURNS TABLE (
    staff_id  INT,
    branch_id INT,
    name      VARCHAR,
    role      VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT s.staff_id,
           s.branch_id,
           s.name,
           s.role
    FROM staff s
    WHERE lower(s.name) = lower(btrim(p_name))
      AND s.password_hash = crypt(p_password, s.password_hash);
END;
$$;

-- Example call (succeeds, sample-data password is 'password123'):
-- SELECT * FROM fn_login_staff('Somchai Jaidee', 'password123');
-- Example call (wrong password: returns 0 rows):
-- SELECT * FROM fn_login_staff('Somchai Jaidee', 'wrongpass');
