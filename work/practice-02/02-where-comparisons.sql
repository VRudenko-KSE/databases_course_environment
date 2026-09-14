-- Concept: WHERE keeps rows whose seats_available value satisfies the >= comparison.
-- Expected rows (course_id | title | seats_available): 103 | Algorithms | 8;
-- 105 | Data Ethics | 10; 301 | Microeconomics | 6.
SELECT course_id, title, seats_available
FROM practice.courses
WHERE seats_available >= 6
ORDER BY course_id ASC;
