-- P13-3: workshop admission. Schema: p13_locking.
-- A1 -> B1 (leave waiting) -> A2 -> A3 -> B2 -> B3 -> A4.

-- @block lock_A1 A
-- BEGIN ISOLATION LEVEL READ COMMITTED;
-- SELECT workshop_id FROM p13_locking./* TODO LOCK_TABLE */
-- WHERE workshop_id=1304 /* TODO LOCK_CLAUSE */;
-- @endblock

-- @block lock_B1 B
-- BEGIN ISOLATION LEVEL READ COMMITTED;
-- SELECT workshop_id FROM p13_locking./* TODO LOCK_TABLE */
-- WHERE workshop_id=1304 /* TODO LOCK_CLAUSE */;
-- @endblock

-- Leave B1 waiting; switch to A.
-- @block lock_A2 A
-- SELECT capacity FROM p13_locking.workshops WHERE workshop_id=1304;
-- SELECT count(*) AS registered FROM p13_locking.registrations WHERE workshop_id=1304;
-- @endblock

-- Keep the INSERT only if A2 permits admission; always COMMIT.
-- @block lock_A3 A
-- INSERT INTO p13_locking.registrations VALUES (1304,'L-A')
-- RETURNING workshop_id,learner_code;
-- COMMIT;
-- @endblock

-- After B1 returns, run this as a NEW selection.
-- @block lock_B2 B
-- SELECT capacity FROM p13_locking.workshops WHERE workshop_id=1304;
-- SELECT count(*) AS registered FROM p13_locking.registrations WHERE workshop_id=1304;
-- @endblock

-- Keep the INSERT only if B2 permits admission; always COMMIT.
-- @block lock_B3 B
-- INSERT INTO p13_locking.registrations VALUES (1304,'L-B')
-- RETURNING workshop_id,learner_code;
-- COMMIT;
-- @endblock

-- @block lock_A4 A
-- SELECT workshop_id,learner_code FROM p13_locking.registrations ORDER BY learner_code;
-- SELECT count(*) AS registered FROM p13_locking.registrations WHERE workshop_id=1304;
-- @endblock
