-- Concept: Parentheses make the intended grouping of AND and OR conditions explicit.
-- Expected rows (course_id | title | department | credits): 105 | Data Ethics | CS | 3;
-- 201 | Statistics | MATH | 6; 202 | Linear Algebra | MATH | 5.
SELECT course_id, title, department, credits
FROM practice.courses
WHERE department = 'MATH'
   OR (department = 'CS' AND credits < 5)
ORDER BY course_id ASC;
