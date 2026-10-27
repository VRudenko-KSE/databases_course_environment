-- P13-2: link two writes. Schema: p13_cte.
-- A1 -> A2. Autocommit ON; no open transaction.

-- @block cte_A1 A
-- WITH new_loan AS (
--     INSERT INTO p13_cte.loans (loan_id,copy_id,borrower_code)
--     VALUES (13010,1301,'L-A')
--     RETURNING /* TODO CTE_KEY */
-- )
-- UPDATE p13_cte.copies AS c SET state='loaned'
-- FROM new_loan AS l
-- WHERE /* TODO CTE_LINK */
-- RETURNING c.copy_id,c.state;
-- @endblock

-- @block cte_A2 A
-- SELECT copy_id,state FROM p13_cte.copies ORDER BY copy_id;
-- SELECT loan_id,copy_id,borrower_code FROM p13_cte.loans ORDER BY loan_id;
-- @endblock
