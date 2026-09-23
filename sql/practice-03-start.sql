-- DESTRUCTIVE ONLY INSIDE library_lab. Save your SQL and diagram before resetting.
-- Does not touch practice, public, assignment databases, or host work files.
BEGIN;
DROP SCHEMA IF EXISTS library_lab CASCADE;
CREATE SCHEMA library_lab;
COMMIT;
SELECT 'library_lab is empty; ready for Practice 3' AS checkpoint;
