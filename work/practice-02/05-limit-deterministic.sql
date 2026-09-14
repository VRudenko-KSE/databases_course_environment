-- Concept: LIMIT returns a predictable top three because ORDER BY includes a unique tie-breaker.
-- Expected rows (course_id | title | seats_available): 105 | Data Ethics | 10;
-- 103 | Algorithms | 8; 301 | Microeconomics | 6.
SELECT course_id, title, seats_available
FROM practice.courses
ORDER BY seats_available DESC, course_id ASC
LIMIT 3;
