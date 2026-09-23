INSERT INTO library_lab.borrowers (borrower_id, full_name, card_code) VALUES
    (1, 'Olena Bondar', '0001'),
    (2, 'Maksym Levchenko', '0002'),
    (3, 'Olena Bondar', '0003');

-- A book row means one catalogued edition, not an abstract work across editions.
INSERT INTO library_lab.books (book_id, title, isbn, published_on) VALUES
    (10, 'Learning Databases', '9780000000011', DATE '2024-03-01'),
    (20, 'City Gardens', '9780000000028', DATE '2023-06-15'),
    (30, 'Night Maps', '9780000000035', NULL);

INSERT INTO library_lab.copies (copy_id, book_id, inventory_code, replacement_cost, retired) VALUES
    (101, 10, 'LIB-001', 125.50, false),
    (102, 10, 'LIB-002', 125.50, false),
    (201, 20, 'LIB-003', 80.00, false),
    (202, 20, 'LIB-004', 0.00, true);

INSERT INTO library_lab.loans (loan_id, borrower_id, copy_id, borrowed_at, due_at, returned_at) VALUES
    (1001, 1, 101, TIMESTAMPTZ '2026-09-01 09:00+03', TIMESTAMPTZ '2026-09-08 09:00+03',
     TIMESTAMPTZ '2026-09-05 10:00+03'),
    (1002, 2, 201, TIMESTAMPTZ '2026-09-02 11:00+03', TIMESTAMPTZ '2026-09-09 11:00+03', NULL),
    (1003, 1, 101, TIMESTAMPTZ '2026-09-10 09:00+03', TIMESTAMPTZ '2026-09-17 09:00+03', NULL);
