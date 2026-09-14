-- Concept: SELECT chooses output columns, and AS gives them clear result-column aliases.
-- Expected rows (id | course_title): 101 | Databases; 102 | Programming; 103 | Algorithms;
-- 104 | Networks; 105 | Data Ethics; 201 | Statistics; 202 | Linear Algebra; 301 | Microeconomics.
SELECT
    course_id AS id,
    title AS course_title
FROM practice.courses
ORDER BY course_id ASC;
