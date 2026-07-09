-- ============================================================
-- fn_get_session_owner
-- Screen: (none — backend authorization helper)
-- Used by: the Flask API before any /api/dining-sessions/<id>/*
-- call. The other session functions (fn_get_tier_menu,
-- fn_place_order, fn_get_current_bill, ...) take only a
-- session_id and do not check WHO is asking; the momo_app role
-- cannot read dining_session directly, so this is the one sanctioned
-- way for the backend to learn a session's owner and reject other
-- customers (HTTP 403) or missing sessions (HTTP 404).
-- Returns 0 rows if the session does not exist.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_get_session_owner(
    p_session_id INT
)
RETURNS TABLE (
    customer_id INT,
    status      VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT ds.customer_id,
           ds.status
    FROM dining_session ds
    WHERE ds.session_id = p_session_id;
END;
$$;

-- Example call:
-- SELECT * FROM fn_get_session_owner(1);
-- Example result: the owning customer_id and session status,
-- or no rows if session 1 does not exist.
