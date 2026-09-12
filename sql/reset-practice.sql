\set ON_ERROR_STOP on

-- This removes database edits inside the disposable practice schema only.
-- Host SQL files and other database schemas are not removed.
BEGIN;
DROP SCHEMA IF EXISTS practice CASCADE;
\i /course/sql/00-seed.sql
COMMIT;
