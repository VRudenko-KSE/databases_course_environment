SET TIME ZONE 'UTC';
-- Setup only: copy both values into the strict tuple comparison for P11-4.
-- This is the 100000th row, immediately BEFORE the page at OFFSET 100000.
-- Exclude this lookup from the measured seek query; rerun after a checkpoint.
SELECT starts_at AS cursor_starts_at, booking_id AS cursor_booking_id
FROM advanced_lab.bookings
ORDER BY starts_at DESC, booking_id DESC
OFFSET 99999 LIMIT 1;
