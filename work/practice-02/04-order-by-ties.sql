-- Concept: A second ORDER BY key resolves ties in credits and makes the full order predictable.
-- Expected course_id order: 101, 102, 201, 103, 104, 202, 301, 105.
SELECT course_id, title, credits
FROM practice.courses
ORDER BY credits DESC, course_id ASC;
