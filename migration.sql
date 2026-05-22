
-- 4a: Telefonnummer hinzufügen

ALTER TABLE mitglied
ADD COLUMN telefon TEXT;



-- 4b: CHECK Constraint


-- Standard SQL wäre:
-- ALTER TABLE buch
-- ADD CONSTRAINT buch_jahr_plausibel
-- CHECK (erscheinungsjahr BETWEEN 1450 AND 2100);

-- SQLite unterstützt das NICHT deshalb ist die Migration notwendig

PRAGMA foreign_keys = OFF;

CREATE TABLE buch_new (
    isbn TEXT PRIMARY KEY,
    titel TEXT NOT NULL,
    erscheinungsjahr INTEGER NOT NULL,
    verlag TEXT NOT NULL,
    tagesgebuehr NUMERIC(6,2) NOT NULL,
    CHECK (erscheinungsjahr BETWEEN 1450 AND 2100),
    CHECK (tagesgebuehr > 0)
);

INSERT INTO buch_new SELECT * FROM buch;
DROP TABLE buch;
ALTER TABLE buch_new RENAME TO buch;

PRAGMA foreign_keys = ON;



-- 4c: standort auf VARCHAR(10) begrenzen


-- Standard SQL wäre:
-- ALTER TABLE exemplar
-- ALTER COLUMN standort SET DATA TYPE VARCHAR(10);

-- SQLite unterstützt das nicht

PRAGMA foreign_keys = OFF;

CREATE TABLE exemplar_new (
    exemplar_id INTEGER PRIMARY KEY,
    isbn TEXT NOT NULL,
    standort TEXT NOT NULL,
    FOREIGN KEY (isbn) REFERENCES buch(isbn)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

INSERT INTO exemplar_new SELECT * FROM exemplar;
DROP TABLE exemplar;
ALTER TABLE exemplar_new RENAME TO exemplar;

PRAGMA foreign_keys = ON;
