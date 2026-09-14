-- Optional concept: BETWEEN includes both boundary values, so course IDs 102 and 104 are included.
-- Expected rows (course_id | title): 102 | Programming; 103 | Algorithms; 104 | Networks.
SELECT course_id, title
FROM practice.courses
WHERE course_id BETWEEN 102 AND 104
ORDER BY course_id ASC;
