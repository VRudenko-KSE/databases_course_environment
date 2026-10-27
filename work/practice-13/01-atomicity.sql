-- P13-1: lending boundary. Schema: p13_atomicity.
-- A1 -> A2 -> A3 -> A4 -> A5. Run each block separately; do not reset between attempts.

-- @block loan_A1 A
-- /* TODO LOAN_BEGIN */
-- INSERT INTO p13_atomicity.loans (loan_id,copy_id,borrower_code)
-- VALUES (13010,1301,'L-A') RETURNING loan_id,copy_id;
-- @endblock

-- A2: deliberate error; execute separately.
-- @block loan_A2 A
-- SELECT 1/0;
-- @endblock

-- A3: undo the failed attempt, then inspect.
-- @block loan_A3 A
-- /* TODO LOAN_UNDO */
-- SELECT copy_id,state FROM p13_atomicity.copies ORDER BY copy_id;
-- SELECT loan_id,copy_id,borrower_code FROM p13_atomicity.loans ORDER BY loan_id;
-- @endblock

-- A4: complete the successful transaction.
-- @block loan_A4 A
-- /* TODO LOAN_BEGIN */
-- INSERT INTO p13_atomicity.loans (loan_id,copy_id,borrower_code)
-- VALUES (13010,1301,'L-A') RETURNING loan_id,copy_id;
-- UPDATE p13_atomicity.copies SET state='loaned' WHERE copy_id=1301
-- RETURNING copy_id,state;
-- /* TODO LOAN_FINISH */
-- @endblock

-- @block loan_A5 A
-- SELECT copy_id,state FROM p13_atomicity.copies ORDER BY copy_id;
-- SELECT loan_id,copy_id,borrower_code FROM p13_atomicity.loans ORDER BY loan_id;
-- @endblock
