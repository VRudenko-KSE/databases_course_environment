-- Optional concept: A successful SELECT can return zero rows when no row matches its condition.
-- Expected result: zero rows; the largest seeded credits value is 6.
SELECT course_id, title, credits
FROM practice.courses
WHERE credits > 6
ORDER BY course_id ASC;
