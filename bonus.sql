-- BONUS 1: Insert additional copy for frequently borrowed books
INSERT INTO exemplar (exemplar_id, isbn, standort)
SELECT
    (SELECT MAX(exemplar_id) FROM exemplar) + ROW_NUMBER() OVER(),
    isbn,
    'Neu-' || standort
FROM exemplar
WHERE isbn IN (
    SELECT e.isbn
    FROM ausleihe a
    JOIN exemplar e ON a.exemplar_id = e.exemplar_id
    GROUP BY e.isbn
    HAVING COUNT(*) > 1
);

-- BONUS 2: Overdue loans
SELECT
    m.nachname || ' ' || m.vorname AS mitglied,
    b.titel,
    julianday(CURRENT_DATE) - julianday(a.ausleihe_datum) AS tage
FROM ausleihe a
JOIN mitglied m ON a.mitglied_id = m.mitglied_id
JOIN exemplar e ON a.exemplar_id = e.exemplar_id
JOIN buch b ON e.isbn = b.isbn
WHERE a.rueckgabe_datum IS NULL
ORDER BY tage DESC;

-- BONUS 3: Lending fee invoice
SELECT
    m.nachname || ' ' || m.vorname AS mitglied,
    b.titel,
    (julianday(a.rueckgabe_datum) - julianday(a.ausleihe_datum)) * b.tagesgebuehr AS gebuehr
FROM ausleihe a
JOIN mitglied m ON a.mitglied_id = m.mitglied_id
JOIN exemplar e ON a.exemplar_id = e.exemplar_id
JOIN buch b ON e.isbn = b.isbn
WHERE a.rueckgabe_datum IS NOT NULL;
