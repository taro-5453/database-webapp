-- ============================================================
-- Momo Paradise - Functions (Batch 1)
-- Real PostgreSQL functions (CREATE FUNCTION).
-- Each function feeds a specific screen; see notes above each.
-- ============================================================


-- ============================================================
-- fn_get_available_tables
-- Screen: Customer > Browse Branch / Availability
-- Used by: the "available tables" list on a branch's page.
-- Returns tables at a branch that are currently free and big
-- enough for the requested party size.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_get_available_tables(
    p_branch_id  INT,
    p_party_size INT
)
RETURNS TABLE (
    table_id INT,
    capacity INT,
    status   VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT dt.table_id, dt.capacity, dt.status
    FROM dining_table dt
    WHERE dt.branch_id = p_branch_id
      AND dt.status = 'available'
      AND dt.capacity >= p_party_size
    ORDER BY dt.capacity ASC;   -- smallest table that fits first
END;
$$;

-- Example call:
-- SELECT * FROM fn_get_available_tables(1, 4);
-- Example result: tables at branch 1 that are free and seat 4+.

