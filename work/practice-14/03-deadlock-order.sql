-- P14-3: deadlock order. Reasoning/SQL editing only; no fixture is required.
-- A holds 1404 and requests 1405; B holds 1405 and requests 1404.
-- Mark both wait arrows. Put these operations in a common order for A and B.

-- UPDATE resources SET marker=marker+1 WHERE resource_id=1404 RETURNING resource_id,marker;
-- UPDATE resources SET marker=marker+1 WHERE resource_id=1405 RETURNING resource_id,marker;

-- A's order: [first operation] then [second operation].
-- B's order: [first operation] then [second operation].
-- Explain the remaining possible wait and which edge of the original cycle cannot form.
