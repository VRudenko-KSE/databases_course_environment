\set ON_ERROR_STOP on
-- Distinct schemas keep both practice states available after one fresh startup.
-- Copy the P3-4 base schema, then restore FKs (LIKE does not copy foreign keys).
BEGIN;

CREATE SCHEMA library_p5;
CREATE TABLE library_p5.borrowers (LIKE library_lab.borrowers INCLUDING ALL);
CREATE TABLE library_p5.books (LIKE library_lab.books INCLUDING ALL);
CREATE TABLE library_p5.copies (LIKE library_lab.copies INCLUDING ALL);
CREATE TABLE library_p5.loans (LIKE library_lab.loans INCLUDING ALL);
ALTER TABLE library_p5.copies
    ADD CONSTRAINT p5_copies_book_fk FOREIGN KEY (book_id) REFERENCES library_p5.books (book_id);
ALTER TABLE library_p5.loans
    ADD CONSTRAINT p5_loans_borrower_fk FOREIGN KEY (borrower_id) REFERENCES library_p5.borrowers (borrower_id),
    ADD CONSTRAINT p5_loans_copy_fk FOREIGN KEY (copy_id) REFERENCES library_p5.copies (copy_id);
INSERT INTO library_p5.borrowers SELECT * FROM library_lab.borrowers;
INSERT INTO library_p5.books SELECT * FROM library_lab.books;
INSERT INTO library_p5.copies SELECT * FROM library_lab.copies;
INSERT INTO library_p5.loans SELECT * FROM library_lab.loans;

CREATE TABLE library_p5.authors (
    author_id integer PRIMARY KEY,
    full_name text NOT NULL
);
INSERT INTO library_p5.authors VALUES (201, 'Iryna Lis'), (202, 'Taras Melnyk');
CREATE TABLE library_p5.book_authors (
    book_id integer NOT NULL REFERENCES library_p5.books (book_id),
    author_id integer NOT NULL REFERENCES library_p5.authors (author_id),
    credit_order integer NOT NULL CHECK (credit_order > 0),
    PRIMARY KEY (book_id, author_id),
    UNIQUE (book_id, credit_order)
);
INSERT INTO library_p5.book_authors VALUES (10, 201, 1), (10, 202, 2), (20, 202, 1);

CREATE SCHEMA library_p6;
CREATE TABLE library_p6.borrowers (LIKE library_lab.borrowers INCLUDING ALL);
CREATE TABLE library_p6.books (LIKE library_lab.books INCLUDING ALL);
CREATE TABLE library_p6.copies (LIKE library_lab.copies INCLUDING ALL);
CREATE TABLE library_p6.loans (LIKE library_lab.loans INCLUDING ALL);
ALTER TABLE library_p6.copies
    ADD CONSTRAINT p6_copies_book_fk FOREIGN KEY (book_id) REFERENCES library_p6.books (book_id);
ALTER TABLE library_p6.loans
    ADD CONSTRAINT p6_loans_borrower_fk FOREIGN KEY (borrower_id) REFERENCES library_p6.borrowers (borrower_id),
    ADD CONSTRAINT p6_loans_copy_fk FOREIGN KEY (copy_id) REFERENCES library_p6.copies (copy_id);
INSERT INTO library_p6.borrowers SELECT * FROM library_lab.borrowers;
INSERT INTO library_p6.books SELECT * FROM library_lab.books;
INSERT INTO library_p6.copies SELECT * FROM library_lab.copies;
INSERT INTO library_p6.loans SELECT * FROM library_lab.loans;

CREATE TABLE library_p6.authors (
    author_id integer PRIMARY KEY,
    full_name text NOT NULL
);
INSERT INTO library_p6.authors VALUES (201, 'Iryna Lis'), (202, 'Taras Melnyk');
CREATE TABLE library_p6.book_authors (
    book_id integer NOT NULL REFERENCES library_p6.books (book_id),
    author_id integer NOT NULL REFERENCES library_p6.authors (author_id),
    credit_order integer NOT NULL CHECK (credit_order > 0),
    PRIMARY KEY (book_id, author_id),
    UNIQUE (book_id, credit_order)
);
INSERT INTO library_p6.book_authors VALUES (10, 201, 1), (10, 202, 2), (20, 202, 1);

-- Practice 4 recovery inputs used again in P6.
CREATE TABLE library_p6.mixed_credits (
    book_id integer NOT NULL,
    author_id integer NOT NULL,
    title text NOT NULL,
    author_name text NOT NULL,
    PRIMARY KEY (book_id, author_id)
);
INSERT INTO library_p6.mixed_credits VALUES
    (10, 201, 'Learning Databases', 'Iryna Lis'),
    (10, 202, 'Learning Databases', 'Taras Melnyk'),
    (20, 202, 'City Gardens', 'Taras Melnyk');

CREATE TABLE library_p6.author_lists (
    book_id integer PRIMARY KEY,
    author_ids integer[] NOT NULL
);
INSERT INTO library_p6.author_lists VALUES (10, ARRAY[201, 202]), (20, ARRAY[202]);

CREATE TABLE library_p6.publisher_records (
    book_id integer PRIMARY KEY,
    title text NOT NULL,
    publisher_id integer NOT NULL,
    publisher_name text NOT NULL
);
INSERT INTO library_p6.publisher_records VALUES
    (10, 'Learning Databases', 501, 'River Press'),
    (20, 'City Gardens', 501, 'River Press'),
    (30, 'Night Maps', 502, 'North Press');

CREATE TABLE library_p6.borrower_addresses (
    borrower_id integer PRIMARY KEY REFERENCES library_p6.borrowers (borrower_id),
    full_name text NOT NULL,
    address text NOT NULL
);
INSERT INTO library_p6.borrower_addresses VALUES
    (1, 'Olena Bondar', '10 Park Street'),
    (3, 'Olena Bondar', '8 Lake Street');

CREATE VIEW library_p6.loan_live AS
SELECT l.loan_id, l.borrower_id, b.full_name, k.title
FROM library_p6.loans AS l
JOIN library_p6.borrowers AS b ON b.borrower_id = l.borrower_id
JOIN library_p6.copies AS c ON c.copy_id = l.copy_id
JOIN library_p6.books AS k ON k.book_id = c.book_id;
CREATE MATERIALIZED VIEW library_p6.loan_report AS
SELECT loan_id, borrower_id, full_name, title
FROM library_p6.loan_live;

COMMIT;
