-- Practice 7: eight read-only tasks on activity_lab. Four core, four optional.
-- Keep this setting in the connection used for date casts and calendar reports:
SET TIME ZONE 'UTC';
SHOW TimeZone;
-- P7-1: September2026 events: inclusive September1, exclusive October1.
-- Return event_id, registration_id, occurred_at, status; order occurred_at, event_id.
-- P7-2: daily September counts with FILTER for registered and cancelled events.
-- P7-3: generate September1-7 dates and join daily counts, including zero-activity days.
-- P7-4: latest state before October1; DISTINCT ON with timestamp DESC/event_id DESC;
-- select active registrations AFTER choosing the latest event. Join registration identifiers.
-- Optional P7-5: use EXISTS to list each student who ever cancelled before October1 once.
-- Optional P7-6: current participants per workshop, including empty workshops; ordered STRING_AGG.
-- Optional P7-7: September event counts by date_trunc('week', occurred_at).
-- Optional P7-8: all workshops, September event counts and cancellation/registration ratio;
-- use numeric division and NULLIF for a zero denominator. Keep an undefined ratio NULL.
-- Save SQL, output, reasoning, the report time zone and the cutoff for every task.
