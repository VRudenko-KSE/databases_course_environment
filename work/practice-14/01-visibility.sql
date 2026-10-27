-- P14-1: read views. Schema: p14_visibility.
-- A1 -> B1 -> A2 -> A3. B uses autocommit; keep A open until A2.
-- Run READ COMMITTED, reset this schema, then repeat with REPEATABLE READ.

-- @block view_A1 A
-- BEGIN ISOLATION LEVEL /* TODO VIEW_MODE */;
-- SELECT capacity FROM p14_visibility.rooms WHERE room_id=1401;
-- @endblock

-- @block view_B1 B
-- UPDATE p14_visibility.rooms SET capacity=40 WHERE room_id=1401
-- RETURNING room_id,capacity;
-- @endblock

-- @block view_A2 A
-- SELECT capacity FROM p14_visibility.rooms WHERE room_id=1401;
-- COMMIT;
-- @endblock

-- @block view_A3 A
-- SELECT capacity FROM p14_visibility.rooms WHERE room_id=1401;
-- @endblock
