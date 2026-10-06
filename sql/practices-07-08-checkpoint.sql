\set ON_ERROR_STOP on
-- Explicit recovery only: replaces activity_lab and reporting_lab, including edits there.
-- Earlier practice schemas, storage_lab and host work files are preserved.
DROP SCHEMA IF EXISTS activity_lab CASCADE;
DROP SCHEMA IF EXISTS reporting_lab CASCADE;
\ir migrations/40-practices-07-08-reporting.sql
\ir migrations/50-practice-07-activity.sql
