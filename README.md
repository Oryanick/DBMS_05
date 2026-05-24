# DBMS_05 – From Schema to Data: DDL and DML in Practice

**Module:** Databases · THGA Bochum  
**Lecturer:** Stephan Bökelmann · <sboekelmann@ep1.rub.de>  
**Repository:** <https://github.com/MaxClerkwell/DBMS_05>  
**Prerequisites:** DBMS_01, DBMS_02, DBMS_03, DBMS_04, Lecture 05 (SQL I – DDL & DML)  
**Duration:** 90 minutes

---

## Learning Objectives

After completing this exercise you will be able to:

- Choose appropriate **SQL data types** for a given domain and justify the choice
- Write **`CREATE TABLE`** statements with column and table constraints
  (`PRIMARY KEY`, `FOREIGN KEY`, `NOT NULL`, `UNIQUE`, `CHECK`, `DEFAULT`)
- Declare **referential actions** (`ON DELETE`, `ON UPDATE`) and argue for the
  correct choice per relationship
- Use **`ALTER TABLE`** to add, drop, and modify columns and constraints
- Write **`INSERT`**, **`UPDATE`**, and **`DELETE`** statements — including
  multi-row inserts and updates with subqueries
- Protect destructive DML with **`BEGIN` / `ROLLBACK` / `COMMIT`** and explain
  why Autocommit is dangerous in practice

**After completing this exercise you should be able to answer the following questions independently:**

- Why is `NUMERIC(p,s)` mandatory for monetary values, while `REAL` is not?
- What is the difference between a column constraint and a table constraint —
  and when must a table constraint be used?
- Why does a `CHECK` constraint never reject a `NULL` value?
- What is the effect of a missing `WHERE` clause in `UPDATE` and `DELETE`?

---

## Check Prerequisites

```bash
sqlite3 --version
git --version
```

> You should see two version strings — SQLite 3.x and Git 2.x.
> If SQLite is missing:
>
> ```bash
> sudo apt-get install -y sqlite3   # Debian / Ubuntu
> brew install sqlite3              # macOS
> ```

> **Screenshot 1:** Take a screenshot of your terminal showing both
> successful version checks and insert it here.
>
> `![Screenshot1](https://github.com/Oryanick/DBMS_05/blob/master/Screenshot%201.png)

---

## 0 – Fork and Clone the Repository

**Step 1 – Fork on GitHub:**  
Navigate to <https://github.com/MaxClerkwell/DBMS_05> and click **Fork**.
Keep the default settings and confirm.

**Step 2 – Clone your fork:**

```bash
git clone git@github.com:<your-username>/DBMS_05.git
cd DBMS_05
ls
```

> You should see only the `README.md`. You will create all further files
> yourself during this exercise.

---

## 1 – The Domain: A Municipal Library

A small municipal library manages its collection, members, and lending
transactions in a relational database. The library needs to track:

- **Books** — each identified by its ISBN, with a title, publication year,
  publisher, and a recommended lending price per day in euro.
- **Copies** — a book can exist in multiple physical copies, each stored at a
  specific shelf location.
- **Members** — registered with name, date of birth, e-mail address, and the
  date they joined the library.
- **Loans** — a member borrows a specific copy on a given date. The return date
  is recorded when the copy is handed back; until then it remains unknown.

The entity-relationship structure is deliberately given to you so that this
exercise can focus entirely on DDL and DML. Your task is to implement this
schema correctly in SQL.

### The Relations

| Relation    | Attributes (informal)                                                               | Primary Key           |
|-------------|-------------------------------------------------------------------------------------|-----------------------|
| `buch`      | isbn, titel, erscheinungsjahr, verlag, tagesgebuehr (in €)                         | isbn                  |
| `exemplar`  | exemplar_id, isbn (FK), standort                                                    | exemplar_id           |
| `mitglied`  | mitglied_id, nachname, vorname, geburtsdatum, email, beitritt_datum                 | mitglied_id           |
| `ausleihe`  | ausleihe_id, exemplar_id (FK), mitglied_id (FK), ausleihe_datum, rueckgabe_datum   | ausleihe_id           |

### Task 1 – Identify the Correct Data Types

For each attribute in the table above, choose the most appropriate SQL standard
data type and write it into the table below. Justify each choice in one sentence.
Use `NUMERIC(p,s)` for monetary values; choose the most precise date/time type
for each temporal attribute.

| Attribute              | Your Type         |          Justification                |
|------------------------|-------------------|---------------------------------------|
| isbn                   | TEXT              | alphanumerischer Standardcode         |
| titel                  | TEXT              | variabler Buchtitel                   |
| erscheinungsjahr       | INTEGER           | ganzzahliges Jahr                     |
| verlag                 | TEXT              | Name als Zeichenkette                 |
| tagesgebuehr           | NUMERIC(6,2)      | exacter Geldwert ohne Rundungsfehler  |
| exemplar_id            | INTEGER           | numerische eindeutige ID              |
| standort               | TEXT              | Ortcode wo sich Sachen befinden       |
| mitglied_id            | INTEGER           | eine eindeutige ID                    |
| nachname               | TEXT              | Personenname                          |
| vorname                | TEXT              | Personenname                          |
| geburtsdatum           | DATE              | Datumswert                            |
| email                  | TEXT              | Email als String                      |
| beitritt_datum         | DATE              | Datumswert                            |
| ausleihe_id            | INTEGER           | eindeutige ID                         |
| ausleihe_datum         | DATE              | Datumswert                            |
| rueckgabe_datum        | DATE              | Datumswert                            |

### Questions for Task 1

**Question 1.1:** `tagesgebuehr` could be stored as `REAL`. Give a concrete
example — using arithmetic — of why `REAL` would produce an incorrect result
for a lending fee calculation. Which type must be used instead?

> *Your answer:*  REAL speichert Fließkommazahlen binär und führt dadurch zu Rundungsfehlern (ZB  0,1 + 0,2 ist nicht gleich exakt 0,3). Bei Geldbeträgen entstehen dadurch falsche Summen nach mehreren Berechnungen, deshalb muss NUMERIC(p,s) verwendet werden, da es Dezimalwerte exakt speichert.

**Question 1.2:** `rueckgabe_datum` must be nullable. Explain what `NULL` means
in this specific context. Is `NULL` the same as "zero days"? Justify with
reference to the three-valued logic of SQL.

> *Your answer:* NULL in rueckgabe_datum bedeutet, dass das Buch noch nicht zurückgegeben wurde. Es ist nicht gleich 0 Tage oder ein leerer Wert. In der SQL Dreiwertelogik bedeutet NULL unbekannt und Vergleiche mit NULL ergeben nicht TRUE oder FALSE, sondern UNKNOWN.

**Question 1.3:** `beitritt_datum` should default to today's date when no value
is provided. Write the `DEFAULT` expression you would use and explain why this
is preferable to always supplying the date explicitly in the application.

> *Your answer:* ich würde DEFAULT CURRENT_DATE benutzen, das sorgt dafür, dass das Beitrittsdatum automatisch gesetzt wird, wenn kein Wert angegeben wird. Das ist gut, weil die Anwendung die Daten nicht selbst liefern muss also haben wir dann weniger Fehler und konsistente Daten.

---

## 2 – DDL: Create the Schema

### Task 2a – Write schema.sql

```bash
vim schema.sql
```

Write `CREATE TABLE` statements for all four relations. Requirements:

- Every column must have an explicit type.
- Apply `NOT NULL` everywhere a value must always be present.
- `email` in `mitglied` must be unique across all members.
- `tagesgebuehr` must be greater than zero.
- `rueckgabe_datum`, if not `NULL`, must be greater than or equal to
  `ausleihe_datum` — express this as a table-level `CHECK` constraint.
- `beitritt_datum` must default to the current date.
- All foreign keys must declare `ON DELETE` and `ON UPDATE` actions:
  - Deleting a `buch` record must be refused as long as copies exist.
  - Deleting an `exemplar` record must be refused as long as active loans exist.
  - Deleting a `mitglied` record must be refused as long as loans exist.
  - Updating a primary key value must cascade to all dependent tables.
- Use SQLite types only (`INTEGER`, `TEXT`, `REAL`, `NUMERIC`, `DATE`).

> **Hint:** In SQLite, foreign key enforcement is off by default.
> Always run `PRAGMA foreign_keys = ON;` before your DDL and DML statements
> within the same session.

<details>
<summary>Solution skeleton — try it yourself first</summary>

```sql
PRAGMA foreign_keys = ON;

CREATE TABLE buch (
    isbn              TEXT           PRIMARY KEY,
    titel             TEXT           NOT NULL,
    erscheinungsjahr  INTEGER        NOT NULL,
    verlag            TEXT           NOT NULL,
    tagesgebuehr      NUMERIC(6,2)   NOT NULL CHECK (tagesgebuehr > 0)
);

CREATE TABLE exemplar (
    exemplar_id  INTEGER  PRIMARY KEY,
    isbn         TEXT     NOT NULL,
    standort     TEXT     NOT NULL,
    FOREIGN KEY (isbn) REFERENCES buch(isbn)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE mitglied (
    mitglied_id     INTEGER  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nachname        TEXT     NOT NULL,
    vorname         TEXT     NOT NULL,
    geburtsdatum    DATE     NOT NULL,
    email           TEXT     NOT NULL UNIQUE,
    beitritt_datum  DATE     NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE ausleihe (
    ausleihe_id      INTEGER  PRIMARY KEY,
    exemplar_id      INTEGER  NOT NULL,
    mitglied_id      INTEGER  NOT NULL,
    ausleihe_datum   DATE     NOT NULL,
    rueckgabe_datum  DATE,
    FOREIGN KEY (exemplar_id) REFERENCES exemplar(exemplar_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (mitglied_id) REFERENCES mitglied(mitglied_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CHECK (rueckgabe_datum IS NULL OR rueckgabe_datum >= ausleihe_datum)
);
```

> **Note:** SQLite does not implement `GENERATED ALWAYS AS IDENTITY`. Use
> `INTEGER PRIMARY KEY` instead — SQLite automatically assigns the next
> available integer when `NULL` is inserted into such a column. This is
> SQLite-specific behaviour; the standard syntax is shown in the lecture.

</details>

### Task 2b – Load the Schema and Verify

```bash
sqlite3 bibliothek.db < schema.sql
sqlite3 bibliothek.db ".tables"
sqlite3 bibliothek.db ".schema"
```

> Expected tables: `ausleihe  buch  exemplar  mitglied`

> **Screenshot 2:** Take a screenshot showing the `.tables` and `.schema`
> output in your terminal.
>
> ![Screenshot2](https://github.com/Oryanick/DBMS_05/blob/master/Screenshot%202.png) 

### Task 2c – Test Constraints

Without modifying `schema.sql`, run the following statements directly in
`sqlite3` (enable foreign keys first with `PRAGMA foreign_keys = ON;`) and
record what happens:

```sql
-- Test A: insert a book with a negative daily fee
INSERT INTO buch VALUES ('000-0-0000-0000-0', 'Fehlertest', 2024, 'Verlag X', -1.50);

-- Test B: insert a member without an e-mail
INSERT INTO mitglied (nachname, vorname, geburtsdatum)
VALUES ('Mustermann', 'Max', '2000-01-01');

-- Test C: insert a loan with a return date earlier than the loan date
INSERT INTO buch   VALUES ('978-3-16-148410-0', 'Testbuch', 2023, 'Verlag Y', 2.00);
INSERT INTO exemplar VALUES (1, '978-3-16-148410-0', 'Regal A1');
INSERT INTO mitglied (nachname, vorname, geburtsdatum, email)
VALUES ('Muster', 'Anna', '1990-05-20', 'anna@example.com');
INSERT INTO ausleihe VALUES (1, 1, 1, '2026-05-10', '2026-05-01');
```

> *Describe the error or result for each test:*
>
> - Test A: Die Tabelle buch hat eine CHECK Constraint, die verlangt, dass die Tagesgebühr größer als 0 ist. Der Wert -1.50 verletzt diese Bedingung, daher wird der Insert abgelehnt.
> - Test B: Die Spalte email ist als NOT NULL definiert. Da beim INSERT keine EMail angegeben wurde, verletzt der Datensatz diese Pflicht und wird nicht gespeichert.
> - Test C: Die CHECK Constraint stellt sicher, dass entweder: das Rückgabedatum NULL ist (noch ausgeliehen), oder das Rückgabedatum zeitlich nach oder gleich dem Ausleihdatum liegt. Hier ist 2026-05-01 < 2026-05-10, also verletzt der Datensatz die Bedingung.

### Questions for Task 2

**Question 2.1:** The `CHECK` on `rueckgabe_datum` was written as a table
constraint rather than a column constraint. Why is a column constraint
insufficient here?

> *Your answer:* Ein Spalten Constraint kann nur auf den Wert derselben Spalte verweisen, der CHECK Constraint vergleicht jedoch rueckgabe_datum mit ausleihe_datum und benötigt daher Zugriff auf zwei Spalten, deswegen ist ein Tabellen Constraint erforderlich.

**Question 2.2:** You chose `ON DELETE RESTRICT` for all foreign keys.
Describe a realistic alternative: for which relationship would `ON DELETE
CASCADE` be appropriate instead, and why?

> *Your answer:* ON DELETE CASCADE könnte zwischen exemplar und ausleihe sinnvoll sein. Wenn ein Exemplar dauerhaft aus dem Bibliothekssystem entfernt wird, könnten alle zugehörigen Ausleihedatensätze ebenfalls automatisch gelöscht werden. Dadurch werden verwaiste Datensätze vermieden und Aufräumarbeiten vereinfacht.

**Question 2.3:** `email` is declared `UNIQUE`. According to the SQL standard,
how many `NULL` values may a `UNIQUE` column contain? Explain using the
three-valued logic of SQL.

> *Your answer:* Laut SQL Standard kann eine UNIQUE Spalte mehrere NULL Werte enthalten, es liegt daran, dass NULL unbekannt bedeutet. In der dreiwertige  SQL Logik wird NULL nicht als gleich einem anderen NULL Wert betrachtet, daher wird die UNIQUE Beschränkung nicht verletzt.

---

## 3 – DML: Populate and Modify Data

### Task 3a – Write data.sql

```bash
vim data.sql
```

Populate the database with the following data. Insert them in the correct
dependency order (no foreign key violation).

**Books (`buch`):**

| isbn              | titel                          | erscheinungsjahr | verlag             | tagesgebuehr |
|-------------------|--------------------------------|------------------|--------------------|--------------|
| 978-3-423-08733-2 | Steppenwolf                    | 1927             | dtv                | 0.50         |
| 978-3-518-36893-4 | Homo Faber                     | 1957             | Suhrkamp           | 0.50         |
| 978-3-257-20456-6 | Der Vorleser                   | 1995             | Diogenes           | 0.75         |
| 978-3-596-18296-4 | Das Parfum                     | 1985             | Fischer            | 0.75         |
| 978-3-423-13571-9 | Die Verwandlung                | 1915             | dtv                | 0.30         |

**Copies (`exemplar`):**

| exemplar_id | isbn              | standort |
|-------------|-------------------|----------|
| 1           | 978-3-423-08733-2 | A-01-3   |
| 2           | 978-3-423-08733-2 | A-01-4   |
| 3           | 978-3-518-36893-4 | A-02-1   |
| 4           | 978-3-257-20456-6 | B-01-7   |
| 5           | 978-3-596-18296-4 | B-02-2   |
| 6           | 978-3-423-13571-9 | A-03-1   |

**Members (`mitglied`):**  
*(Omit `beitritt_datum` to test the DEFAULT; supply it explicitly for Klara
Sommer to simulate a historic membership date.)*

| nachname | vorname | geburtsdatum | email                      | beitritt_datum |
|----------|---------|--------------|----------------------------|----------------|
| Berger   | Jonas   | 2001-04-12   | jonas.berger@mail.de       | *(default)*    |
| Sommer   | Klara   | 1985-11-30   | klara.sommer@web.de        | 2019-03-15     |
| Hartmann | Lea     | 1998-07-08   | lea.hartmann@example.com   | *(default)*    |

**Loans (`ausleihe`):**

| ausleihe_id | exemplar_id | mitglied_id | ausleihe_datum | rueckgabe_datum |
|-------------|-------------|-------------|----------------|-----------------|
| 1           | 1           | 1           | 2026-05-01     | 2026-05-10      |
| 2           | 3           | 2           | 2026-05-05     | *(NULL)*        |
| 3           | 4           | 1           | 2026-05-12     | *(NULL)*        |
| 4           | 6           | 3           | 2026-04-20     | 2026-04-28      |

```bash
sqlite3 bibliothek.db < data.sql
```

Verify row counts:

```sql
SELECT 'buch',     COUNT(*) FROM buch
UNION ALL SELECT 'exemplar',  COUNT(*) FROM exemplar
UNION ALL SELECT 'mitglied',  COUNT(*) FROM mitglied
UNION ALL SELECT 'ausleihe',  COUNT(*) FROM ausleihe;
```

> Expected: 5, 6, 3, 4.

Commit:

```bash
git add schema.sql data.sql
git commit -m "feat: DDL and initial data for library database"
```

### Task 3b – UPDATE Statements

Write and execute the following updates. Save them in `updates.sql`.

1. The publisher `dtv` has changed its official name to `Deutscher Taschenbuch
   Verlag`. Update all affected rows with a single `UPDATE` statement.
2. Exemplar 3 (*Homo Faber*, currently on loan) has been returned today.
   Record today's date (`CURRENT_DATE`) as the return date for loan 2.
3. Raise the daily fee for all books published before 1960 by 10 cents.

For each update, first write it inside a `BEGIN` / `ROLLBACK` block and verify
the result with a `SELECT`. Then replace `ROLLBACK` with `COMMIT`.

```sql
BEGIN;
-- your UPDATE here


PRAGMA foreign_keys = ON;

-- 3b.1 Verlag ändern
BEGIN;

UPDATE buch
SET verlag = 'Deutscher Taschenbuch Verlag'
WHERE verlag = 'dtv';

COMMIT;


-- 3b.2 Rückgabe setzen
BEGIN;

UPDATE ausleihe
SET rueckgabe_datum = CURRENT_DATE
WHERE ausleihe_id = 2;

COMMIT;


-- 3b.3 Gebühr erhöhen
BEGIN;

UPDATE buch
SET tagesgebuehr = tagesgebuehr + 0.10
WHERE erscheinungsjahr < 1960;

COMMIT;


SELECT * FROM buch;  -- verify
ROLLBACK;            -- change to COMMIT after verification
```

### Task 3c – DELETE Statements

Write and execute the following deletions. Save them in `deletes.sql`.

1. Remove all loans where the return date is more than 30 days before today.
   Use `julianday(CURRENT_DATE) - julianday(rueckgabe_datum) > 30` as the
   condition.
2. Attempt to delete exemplar 3. Describe the error you expect and the
   referential integrity rule that causes it.
3. After successfully deleting all associated loans (they are all historic and
   have been returned), delete exemplar 3.

For each deletion, wrap it in `BEGIN` / `ROLLBACK`, verify, then `COMMIT`.

### Questions for Task 3

**Question 3.1:** The multi-table UPDATE in Task 3b.1 (renaming the publisher)
works because all affected rows are in the same table. Why can a standard SQL
`UPDATE` not update rows in two different tables simultaneously, and what would
you use instead in a production system?

> *Your answer:*  Ein Standard SQL UPDATE arbeitet immer nur auf einer einzelnen Tabelle, da SQL mengeorientiert pro Relation ausgeführt wird. Jede Tabelle besitzt eine eigene Speicherstruktur und mehrtabellige Änderungen würden schnell zu Inkonsistenzen führen. Deshalb sind direkte Updates über mehrere Tabellen in einer einzelnen SQL Anweisung nicht möglich. In der Praxis löst man solche Fälle durch mehrere UPDATE Anweisungen innerhalb einer Transaktion, durch Stored Procedures oder durch Trigger, die Änderungen automatisch synchronisieren.

**Question 3.2:** Task 3b.3 raises the fee for books published before 1960
by 10 cents. Write the equivalent statement using `NUMERIC` arithmetic:
`tagesgebuehr = tagesgebuehr + 0.10`. Would the same statement work correctly
with `REAL`? Explain the risk.

> *Your answer:* Bei der Verwendung von tagesgebuehr = tagesgebuehr + 0.10 ist NUMERIC die korrekte Wahl, da es exakte Dezimalarithmetik für Geldwerte ermöglicht. REAL hingegen arbeitet mit binären Gleitkommazahlen und kann dadurch Rundungsfehler erzeugen. Ein typisches Risiko ist, dass Berechnungen wie ZB: 0.1 + 0.2 = 0.30000000000000004 ergeben. Dies führt zu falschen Gebühren, Rundungsabweichungen in Rechnungen und Inkonsistenzen bei Summen über mehrere Datensätze hinweg.

**Question 3.3:** Task 3c.1 deletes loans where the return date is more than
30 days ago. A `DELETE` without a `WHERE` clause would delete all loans.
Describe the operational consequence and explain how `BEGIN` / `ROLLBACK`
protects against this mistake.

> *Your answer:* Ein DELETE FROM ausleihe ohne WHERE Klausel würde alle Kredite löschen, wodurch die komplette Ausleihhistorie verloren geht und Geschäftslogik sowie Referenzen in anderen Tabellen beschädigt würden. Um solche Fehler zu vermeiden, kann man die Operation in eine Transaktion einbetten. Mit BEGIN  wird die Änderung gestartet und durch ROLLBACK kann der gesamte Vorgang wieder rückgängig gemacht werden. Dadurch werden Änderungen nur getestet aber nicht auuuf Dauer gespeichert, wodurch die Datenbank geschützt bleibt.

---

## 4 – ALTER TABLE: Evolving the Schema

Over time, the library's requirements change. Perform the following schema
migrations. Save them in `migration.sql`.

### Task 4a – Add a Column

The library wants to record a phone number for each member (optional —
not every member provides one).

```sql
ALTER TABLE mitglied
    ADD COLUMN telefon TEXT;
```

Verify with `.schema mitglied` in `sqlite3`.

### Task 4b – Add a Named Constraint

The library decides that a book's publication year must be between 1450
(invention of the printing press) and the current year.

```sql
ALTER TABLE buch
    ADD CONSTRAINT buch_jahr_plausibel
    CHECK (erscheinungsjahr BETWEEN 1450 AND 2100);
```

> **Note:** SQLite does not support `ADD CONSTRAINT` for `CHECK` constraints
> via `ALTER TABLE`. In SQLite, to add a new constraint to an existing table
> you must: (1) create a new table with the constraint, (2) copy the data,
> (3) drop the old table, (4) rename. Document this limitation in a comment
> in `migration.sql` and write the four-step migration instead.
>
> In standard SQL (and in PostgreSQL, for example), `ADD CONSTRAINT` works
> directly.

### Task 4c – Change a Column Type

The library wants to increase the maximum length of `standort` (currently
unbounded `TEXT`) to enforce a maximum of 10 characters. In standard SQL:

```sql
ALTER TABLE exemplar
    ALTER COLUMN standort SET DATA TYPE VARCHAR(10);
```

> **Note:** This operation is also unsupported in SQLite. Document the
> limitation and describe the four-step workaround in a comment.
> Write the standard SQL statement as a comment above it.

### Questions for Task 4

**Question 4.1:** `ALTER TABLE mitglied ADD COLUMN telefon TEXT` adds a
nullable column. Why is this simpler than adding a `NOT NULL` column to an
already-populated table? What steps would be needed for a `NOT NULL` column?

> *Your answer:* Das Hinzufügen einer neuen Spalte mit NULL ist deutlich einfacher, denn bestehende Datensätze müssen nicht angepasst werden und es ist keine Migration erforderlich. Die Spalte kann einfach ergänzt werden, ohne dass bereits gespeicherte Daten beeinflusst werden. Bei einer NOT NULL Spalte wäre die Situation deutlich komplexer, da alle bestehenden Zeilen einen gültigen Wert benötigen würden und dafür müsste man in der Regel eine neue Tabelle erstellen, Standardwerte definieren, alle alten Daten migrieren und anschließend die alte Tabelle ersetzen.

**Question 4.2:** SQLite's limited `ALTER TABLE` support is a deliberate
design decision. What does this tell you about the trade-off between a
lightweight embedded database and a full-featured server database system?
Name one scenario where SQLite is the right choice and one where it is not.

> *Your answer:* SQLite ist eine leichtgewichtige, eingebettete Datenbank ohne Serverprozess. Sie eignet sich besonders für lokale Anwendungen, kleine Projekte, mobile Apps oder Praktika, da sie einfach zu verwenden ist und keine Serververwaltung benötigt. Serverbasierte Datenbanken wie MySQL bieten hingegen volle ALTER TABLE Unterstützung, Mehrbenutzerbetrieb und sind für große Datenmengen sowie produktive Systeme ausgelegt. SQLite ist daher ideal für einfache oder lokale Anwendungen aber ungeeignet für komplexe Systeme wie Banking Anwendungen, Webshops oder industrielle Datenbanken.

Commit:

```bash
git add migration.sql
git commit -m "feat: schema migration – telefon column and constraint notes"
```

---

## 5 – Transactions: Borrowing as an Atomic Operation

Lending a book copy to a member is not a single SQL statement — it is a
two-step operation:

1. Check that the copy is not currently on loan (no `ausleihe` row with
   `rueckgabe_datum IS NULL` for this `exemplar_id`).
2. Insert a new `ausleihe` row.

If step 2 fails (e.g. due to a constraint violation) after step 1 has
been checked, the database must remain consistent.

### Task 5a – Simulate a Safe Lending Transaction

Write a `BEGIN` / `COMMIT` block in `lend.sql` that lends exemplar 5
(*Das Parfum*) to member 3 (Lea Hartmann) starting today.

```sql
PRAGMA foreign_keys = ON;

BEGIN;

-- Step 1: verify the copy is available (no open loan)
SELECT COUNT(*) AS open_loans
FROM   ausleihe
WHERE  exemplar_id = 5
  AND  rueckgabe_datum IS NULL;

-- Step 2: insert the loan (only proceed if the count above is 0)
INSERT INTO ausleihe (ausleihe_id, exemplar_id, mitglied_id, ausleihe_datum)
VALUES (5, 5, 3, CURRENT_DATE);

COMMIT;
```

Verify:

```sql
SELECT * FROM ausleihe WHERE ausleihe_id = 5;
```

> **Screenshot 3:** Take a screenshot showing the inserted row.
>
> ![Screenshot2](https://github.com/Oryanick/DBMS_05/blob/master/Screenshot%203.png)

### Task 5b – Simulate a Rollback

Now attempt to lend exemplar 3 (*Homo Faber*) to member 1, even though it
was returned in Task 3b (step 2). First re-open the loan artificially:

```sql
BEGIN;
UPDATE ausleihe SET rueckgabe_datum = NULL WHERE ausleihe_id = 2;
-- Now exemplar 3 appears to be on loan again.
-- The following INSERT would succeed (SQLite does not auto-prevent it):
INSERT INTO ausleihe (ausleihe_id, exemplar_id, mitglied_id, ausleihe_datum)
VALUES (6, 3, 1, CURRENT_DATE);
-- Having seen both statements, we decide to abort:
ROLLBACK;
```

Verify that neither change persisted:

```sql
SELECT rueckgabe_datum FROM ausleihe WHERE ausleihe_id = 2;
SELECT COUNT(*) FROM ausleihe WHERE ausleihe_id = 6;
```

> *Describe what you see and explain why `ROLLBACK` reversed both changes:*  Nach dem Beginn der Transaktion wurden zwei Änderungen durchgeführt: ein UPDATE der Rückgabeinformation sowie ein INSERT eines neuen Ausleihdatensatzes. Beim Versuch des INSERTs wurde ein FOREIGN KEY constraint Fehler ausgelöst sodass die Operation nicht erfolgreich war. Nach dem anschließenden ROLLBACK wurden alle innerhalb der Transaktion ausgeführten Änderungen vollständig verworfen. Der Datensatz mit ausleihe_id = 6 wurde nicht gespeichert und die ursprünglichen Daten der Tabelle ausleihe blieben unverändert. Der ROLLBACK Befehl stellt den Zustand der Datenbank auf den Zeitpunkt vor BEGIN zurück. Alle innerhalb der Transaktion ausgeführten Operationen werden gemeinsam rückgängig gemacht, unabhängig davon, ob sie erfolgreich waren oder Fehler ausgelöst haben. Dadurch bleibt die Datenbank konsistent.

### Questions for Task 5

**Question 5.1:** In the lending scenario, why is it important that the
availability check and the insert happen inside the same transaction?
What could go wrong if they ran as separate Autocommit statements?

> *Your answer:* Die Verfügbarkeitsprüfung und das Einfügen eines neuen Ausleihdatensatzes müssen innerhalb derselben Transaktion erfolgen, um eine konsistente Sicht auf die Datenbank sicherzustellen. Wenn diese beiden Schritte als getrennte Autocommit Statements ausgeführt würden, könnte zwischen der Prüfung und dem Insert ein anderer Benutzer denselben Datensatz ausleihen. Dadurch würde die Prüfung kein aktiver Kredit vorhanden plötzlich falsch werden und es könnten doppelte Ausleihen entstehen. Durch die gemeinsame Transaktion wird garantiert, dass die geprüfte Bedingung während der gesamten Operation gültig bleibt oder die gesamte Operation abgebrochen wird.

**Question 5.2:** The lecture states: "Ein fehlendes `WHERE` aktualisiert
alle Zeilen." Write the single most dangerous `UPDATE` statement possible
on this database and explain the damage it would cause. Then explain how
`BEGIN` / `ROLLBACK` would allow you to recover.

> *Your answer:* Ein besonders gefährliches SQL Statement in dieser Datenbank wäre: UPDATE ausleihe SET rueckgabe_datum = CURRENT_DATE; Dieses Statement würde alle Ausleihen als zurückgegeben markieren, unabhängig davon, ob sie tatsächlich zurückgegeben wurden oder noch aktiv sind. Dadurch würde die komplette Ausleihhistorie logisch zerstört werden. Ohne WHERE Klausel wird jede Zeile der Tabelle verändert. Mit einer Transaktion kann dieser Fehler jedoch kontrolliert werden: BEGIN; UPDATE ausleihe SET rueckgabe_datum = CURRENT_DATE; ROLLBACK; Der ROLLBACK stellt den Zustand der Tabelle wieder her sodass keine Änderungen dauerhaft übernommen werden. Dadurch können gefährliche Fehler vor dem Commit erkannt und rückgängig gemacht werden.

**Question 5.3:** Autocommit is convenient for read-only queries (`SELECT`).
Is it also safe for DML in an interactive session? Give a concrete example
from this exercise where Autocommit would have caused irreversible data loss.

> *Your answer:* Autocommit ist für DML Operationen nicht sicher, da jede Änderung sofort dauerhaft gespeichert wird. Ein Beispiel aus dieser Aufgabe wäre:DELETE FROM ausleihe WHERE exemplar_id = 3; Wenn dieser Befehl im Autocommit Modus ohne vorherige Transaktion ausgeführt wird, wird der Datensatz sofort und dauerhaft gelöscht. Ein versehentlicher Fehler (ZB: falsche WHERE Bedingung oder falsche ID) kann nicht mehr rückgängig gemacht werden. Mit einer Transaktion wäre es dagegen sicher:BEGIN; DELETE FROM ausleihe WHERE exemplar_id = 3; ROLLBACK; So können Änderungen geprüft werden, bevor sie endgültig übernommen werden.

Commit:

```bash
git add lend.sql
git commit -m "feat: transaction examples for safe lending operations"
```

---

## 6 – Reflection

**Question A – Type discipline:**  
The lecture warns against using `TEXT` for everything. Looking at the
`buch` table: which column would be most tempting to store as `TEXT` when
it should be a more specific type, and what concrete query would break or
produce wrong results if the wrong type were used?

> *Your answer:* In der Tabelle buch ist besonders die Spalte titel verlockend, einfach als TEXT zu speichern, obwohl sie semantisch mehr als nur eine beliebige Zeichenkette ist. Ein typisches Problem entsteht bei einer falschen Typwahl für erscheinungsjahr wenn dieses als TEXT gespeichert wird, dann würden Vergleiche lexikografisch statt numerisch durchgeführt werden. Beispielsweise kann die Bedingung erscheinungsjahr > 1960 zu falschen Ergebnissen führen, da Strings alphabetisch verglichen werden (ZB: wird 2000 möglicherweise kleiner als 1960 interpretiert). Dadurch entstehen fehlerhafte Filterergebnisse und eine kaputte zeitliche Logik.


**Question B – DDL as documentation:**  
A colleague reads your `schema.sql` and says: "Constraints slow down inserts
— I'd rather check these rules in the application." Give two concrete
reasons why enforcing constraints in the database is preferable to
enforcing them only in application code.

> *Your answer:*  Ein erster wichtiger Grund für Constraints in der Datenbank ist die zentrale Datenintegrität. Jede Anwendung, die auf die Datenbank zugreift wird automatisch durch die Regeln geschützt, sodass keine zweite Anwendung oder ein Skript die Datenbank ohne diese Einschränkungen manipulieren kann. Ein zweiter Vorteil ist die Unabhängigkeit von der Applikationslogik. Die Regeln gelten auch bei manuellen SQL Änderungen oder Datenimporten, wodurch Fehler direkt auf Datenbankebene verhindert werden und nicht erst im Programmcode auftreten. Dadurch fungiert die Datenbank als letzte Instanz der Wahrheit.


**Question C – NULL semantics in lending:**  
In `ausleihe`, `rueckgabe_datum IS NULL` means "currently on loan". Could
this semantic be expressed without using `NULL` — e.g. by using a status
column instead? What are the trade-offs?

> *Your answer:*  Die Bedeutung von rueckgabe_datum IS NULL kann theoretisch auch durch eine zusätzliche Statusspalte ersetzt werden, beispielsweise mit Werten wie offen oder zurueckgegeben. Eine mögliche alternative Modellierung wäre eine Spalte status TEXT mit einem CHECK Constraint wie status IN (offen, zurueckgegeben). Diese Lösung hat den Vorteil, dass keine NULL Logik benötigt wird und die Semantik im Code klarer ist. Allerdings entstehen auch Nachteile wie mögliche Redundanz zwischen Status und Datum, erhöhte Fehleranfälligkeit durch inkonsistente Daten und zusätzlicher Pflegeaufwand. Da NULL in SQL bereits eine standardisierte Bedeutung für nicht vorhanden hat, wird es in der Praxis oft für solche Fälle bevorzugt.


**Question D – `TRUNCATE` vs. `DELETE`:**  
If you wanted to reset the entire database and reload the sample data from
scratch, you would need to empty all four tables. Can you use `TRUNCATE`
in SQLite? What alternative would you use, and in what order must the tables
be emptied to respect foreign key constraints?

> *Your answer:* SQLite unterstützt kein TRUNCATE. Um eine vollständige Löschung aller Daten durchzuführen, müssen stattdessen mehrere DELETE Anweisungen verwendet werden. Dabei ist die Reihenfolge entscheidend: Zuerst werden die Tabellen ausleihe, danach exemplar, anschließend buch und zuletzt mitglied geleert. Diese Reihenfolge ist notwendig, denn Fremdschlüsselbeziehungen bestehen: ausleihe hängt von exemplar und mitglied ab, und exemplar wiederum von buch. Eltern Datensätze dürfen erst gelöscht werden wenn alle abhängigen Kind Datensätze entfernt wurden. Alternativ könnte man PRAGMA foreign_keys = OFF verwenden, dies ist jedoch nicht empfohlen da dadurch die referenzielle Integrität verloren geht.

> **Screenshot 4:** Take a screenshot showing the output of the row-count
> verification from Task 3a after completing all DML tasks, with
> `.headers on` and `.mode column` active.
>
> ![Screenshot2](https://github.com/Oryanick/DBMS_05/blob/master/Screenshot%204.png)

---

## Bonus Tasks

1. **`INSERT INTO … SELECT`:** The library acquires a second copy of every
   book that has been borrowed more than once. Write a single
   `INSERT INTO exemplar … SELECT` statement that inserts one additional
   row per qualifying book, with `standort = 'Neu-' || standort` of the
   existing copy.

2. **Overdue calculation:** Write a `SELECT` that lists all currently open
   loans (no return date), the member's full name, the book title, and the
   number of days the book has been borrowed (using `julianday(CURRENT_DATE)
   - julianday(ausleihe_datum)`). Sort by days descending.

3. **Lending fee invoice:** Write a `SELECT` that computes the total lending
   fee for each completed loan (return date not null):
   `(julianday(rueckgabe_datum) - julianday(ausleihe_datum)) * tagesgebuehr`.
   Join all necessary tables and show the member's name, book title, and
   amount due.

4. **GitHub Actions:** Add `.github/workflows/ci.yml` that installs SQLite,
   runs `schema.sql` and `data.sql` against a fresh database, and verifies
   the row counts with a shell assertion. Trigger the workflow by pushing
   any commit to `main`.

---

## Further Reading

- ISO/IEC 9075 (SQL Standard) — official reference; most universities have access
- [SQLite – Core Functions](https://www.sqlite.org/lang_corefunc.html)
- [SQLite – Date and Time Functions](https://www.sqlite.org/lang_datefunc.html)
- [SQLite – Foreign Key Support](https://www.sqlite.org/foreignkeys.html)
- [SQLite – ALTER TABLE Limitations](https://www.sqlite.org/lang_altertable.html)
- Lecture 05 handout – *SQL I: DDL & DML*
