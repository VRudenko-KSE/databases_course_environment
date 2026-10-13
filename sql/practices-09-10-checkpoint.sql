\set ON_ERROR_STOP on
-- Explicit recovery: discard only P9/P10 database edits, experiments and scratch writes.
-- Earlier practice schemas and host work files are preserved.
DROP SCHEMA IF EXISTS index_write CASCADE;
DROP SCHEMA IF EXISTS index_lab CASCADE;
\ir migrations/60-practices-09-10.sql
