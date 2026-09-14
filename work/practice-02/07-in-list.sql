-- Optional concept: IN matches any value in a stated set.
-- Expected rows (course_id | title | department): 201 | Statistics | MATH;
-- 202 | Linear Algebra | MATH; 301 | Microeconomics | ECON.
SELECT course_id, title, department
FROM practice.courses
WHERE department IN ('MATH', 'ECON')
ORDER BY course_id ASC;
