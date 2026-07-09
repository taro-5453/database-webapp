-- ============================================================
-- fn_get_branches
-- Screen: Customer > Browse Branches
-- Used by: the branch list / picker on the home screen.
-- Returns all branches with their basic info so the customer
-- can choose one.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_get_branches()
RETURNS TABLE (
    branch_id INT,
    name      VARCHAR,
    address   VARCHAR,
    phone     VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT b.branch_id, b.name, b.address, b.phone
    FROM branch b
    ORDER BY b.name ASC;
END;
$$;

-- Example call:
-- SELECT * FROM fn_get_branches();
-- Example result: all 10 branches, alphabetical.
