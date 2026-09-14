-- Optional concept: LIKE 'Data%' matches titles that begin with the text Data.
-- Expected rows (course_id | title): 101 | Databases; 105 | Data Ethics.
SELECT course_id, title
FROM practice.courses
WHERE title LIKE 'Data%'
ORDER BY course_id ASC;
