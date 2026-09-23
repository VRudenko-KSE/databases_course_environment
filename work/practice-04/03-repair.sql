-- P4-R: Complete R1-R4 from the handout in this one session/script.
-- Use temporary tables for repair inputs and outputs, as in the TA demo.
-- Keep this work separate from library_lab's four-table fixture.

-- R1: Turn author ID arrays into scalar book/author links; reconstruct them.
CREATE TEMP TABLE author_lists (
    book_id integer PRIMARY KEY,
    author_ids integer[] NOT NULL
);
INSERT INTO author_lists VALUES (10, ARRAY[201, 202]), (20, ARRAY[202]);

-- R2: Split mixed book/author descriptions; show update/insert/delete anomalies.
CREATE TEMP TABLE mixed_credits (
    book_id integer,
    author_id integer,
    title text NOT NULL,
    author_name text NOT NULL,
    PRIMARY KEY (book_id, author_id)
);
INSERT INTO mixed_credits VALUES
    (10, 201, 'Learning Databases', 'Iryna Lis'),
    (10, 202, 'Learning Databases', 'Taras Melnyk'),
    (20, 202, 'City Gardens', 'Taras Melnyk');

-- R3: Split book and publisher facts; reconstruct the original records.
CREATE TEMP TABLE publisher_records (
    book_id integer PRIMARY KEY,
    title text NOT NULL,
    publisher_id integer NOT NULL,
    publisher_name text NOT NULL
);
INSERT INTO publisher_records VALUES
    (10, 'Learning Databases', 501, 'River Press'),
    (20, 'City Gardens', 501, 'River Press'),
    (30, 'Night Maps', 502, 'North Press');

-- R4: Join the two Olena Bondar borrower/address rows on ID, then name.
CREATE TEMP TABLE people (
    borrower_id integer PRIMARY KEY,
    full_name text NOT NULL
);
CREATE TEMP TABLE addresses (
    borrower_id integer PRIMARY KEY,
    full_name text NOT NULL,
    address text NOT NULL
);
INSERT INTO people VALUES (1, 'Olena Bondar'), (3, 'Olena Bondar');
INSERT INTO addresses VALUES
    (1, 'Olena Bondar', '10 Park Street'),
    (3, 'Olena Bondar', '8 Lake Street');
