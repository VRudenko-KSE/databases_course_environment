\set ON_ERROR_STOP on
BEGIN;
CREATE SCHEMA activity_lab;
-- Independent fictional workshop data; all FKs stay inside this disposable lab.
CREATE TABLE activity_lab.students (
    student_id integer PRIMARY KEY,
    full_name text NOT NULL
);
CREATE TABLE activity_lab.workshops (
    workshop_id integer PRIMARY KEY,
    title text NOT NULL
);
CREATE TABLE activity_lab.registrations (
    registration_id integer PRIMARY KEY,
    student_id integer NOT NULL REFERENCES activity_lab.students(student_id),
    workshop_id integer NOT NULL REFERENCES activity_lab.workshops(workshop_id),
    UNIQUE (student_id, workshop_id)
);
CREATE TABLE activity_lab.registration_events (
    event_id integer PRIMARY KEY,
    registration_id integer NOT NULL REFERENCES activity_lab.registrations(registration_id),
    occurred_at timestamptz NOT NULL,
    status text NOT NULL CHECK (status IN ('registered', 'cancelled'))
);
INSERT INTO activity_lab.students VALUES
    (1,'Anna Kovalenko'), (2,'Bohdan Melnyk'), (3,'Carla Ortiz'),
    (4,'Danylo Shevchenko'), (5,'Eva Novak'), (6,'Farid Khan'), (7,'Grace Lee');
INSERT INTO activity_lab.workshops VALUES
    (501,'SQL Clinic'), (502,'Data Visualisation'), (503,'Career Talk'), (504,'Writing Circle');
INSERT INTO activity_lab.registrations VALUES
    (101,1,501), (102,2,501), (103,3,501), (104,4,502), (105,5,502),
    (106,6,503), (107,1,502), (108,2,503), (109,6,501), (110,7,501);
-- UTC boundaries, September 4 gap, cancellation/re-registration, and a timestamp tie.
-- With equal timestamps, the larger event_id is the explicitly defined later event.
INSERT INTO activity_lab.registration_events VALUES
    (1,101,'2026-08-31 23:59:59+00','registered'),
    (2,102,'2026-09-01 00:00:00+00','registered'),
    (3,101,'2026-09-01 10:00:00+00','cancelled'),
    (4,103,'2026-09-02 09:00:00+00','registered'),
    (5,104,'2026-09-02 09:30:00+00','registered'),
    (6,104,'2026-09-03 10:00:00+00','cancelled'),
    (7,104,'2026-09-03 11:00:00+00','registered'),
    (8,105,'2026-09-05 12:00:00+00','registered'),
    (9,106,'2026-09-05 12:15:00+00','registered'),
    (10,103,'2026-09-06 09:00:00+00','cancelled'),
    (11,107,'2026-09-06 10:00:00+00','registered'),
    (12,109,'2026-09-06 11:00:00+00','registered'),
    (13,108,'2026-09-07 11:00:00+00','registered'),
    (14,108,'2026-09-07 11:00:00+00','cancelled'),
    (15,102,'2026-09-30 23:59:59+00','cancelled'),
    (16,106,'2026-09-30 23:59:59+00','cancelled'),
    (17,106,'2026-10-01 00:00:00+00','registered'),
    -- Remains active without any September event: a snapshot needs earlier history.
    (18,110,'2026-08-20 09:00:00+00','registered');
COMMIT;
