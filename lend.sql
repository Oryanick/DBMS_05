PRAGMA foreign_keys = ON;

BEGIN;

--  Verfügbarkeit Check 
SELECT COUNT(*) AS open_loans
FROM ausleihe
WHERE exemplar_id = 5
AND rueckgabe_datum IS NULL;

-- ausleihe einfügen 
INSERT INTO ausleihe (ausleihe_id, exemplar_id, mitglied_id, ausleihe_datum)
VALUES (5, 5, 3, CURRENT_DATE);

COMMIT;

-- Kontrolle

SELECT * FROM ausleihe WHERE ausleihe_id = 5;
