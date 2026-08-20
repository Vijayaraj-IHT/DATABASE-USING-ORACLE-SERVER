# 📂 Folder Structure & Hierarchy

**Package:** `Oracle-SQL-JDBC-Lending-Hub`
**Counts:** 7 directories · 24 files · **20 `.sql` modules** · 1 Java client · 1 master README

---

## Hierarchy

```
Oracle-SQL-JDBC-Lending-Hub/
│
├── README.md                          ← Master documentation (badges, ER diagram,
│                                        deep-dives, quick-start runbook)
├── FOLDER_STRUCTURE.md                ← This file
├── LICENSE                            ← MIT license
├── .gitignore                         ← Build artifacts / secrets exclusion
│
├── 01-schema/                         ── DDL + seed data ───────────────────
│   ├── 01_create_tables.sql           ← 7 tables, named PKs, CLOB/DATE typing
│   ├── 02_add_constraints.sql         ← 9 named FOREIGN KEYs (ALTER TABLE)
│   └── 03_seed_data.sql               ← 53-row dataset incl. orphan edge rows
│
├── 02-queries/                        ── Declarative SQL ───────────────────
│   ├── 01_selection_filters.sql       ← WHERE / projection / DATE predicates
│   ├── 02_aggregate_functions.sql     ← COUNT, AVG, MAX, SUM, GROUP BY
│   ├── 03_joins.sql                   ← INNER / LEFT / RIGHT / FULL / SELF / CROSS
│   ├── 04_set_operators.sql           ← UNION, INTERSECT, MINUS + RI spot-check
│   ├── 05_subqueries.sql              ← Scalar, IN / NOT IN, ALL / ANY
│   └── 06_correlated_and_cte.sql      ← Correlated subqueries, inline views, WITH
│
├── 03-views-indexes/                  ── Physical & virtual design ─────────
│   ├── 01_indexes.sql                 ← B-tree, UNIQUE, DESC-key + USER_INDEXES
│   └── 02_views.sql                   ← 10 views: CHECK OPTION, READ ONLY,
│                                        expression, join, DISTINCT, aggregates
│
├── 04-plsql/                          ── Procedural layer ──────────────────
│   ├── 01_cursor_procedures.sql       ← Implicit / explicit / parametric cursors
│   ├── 02_exception_handling.sql      ← TOO_MANY_ROWS, INVALID_CURSOR, custom
│   ├── 03_functions.sql               ← Scalar, SYS_REFCURSOR, parametric fns
│   └── 04_procedures_dml_out_params.sql ← DML dispatcher, OUT, IN OUT params
│
├── 05-triggers/                       ── Row-level event engine ────────────
│   ├── 01_validation_triggers.sql     ← Rating band, owner check, payment > 0
│   ├── 02_audit_triggers.sql          ← AFTER/BEFORE on INSERT/UPDATE/DELETE
│   ├── 03_instead_of_trigger.sql      ← INSTEAD OF on non-updatable view
│   └── 04_payment_sync_trigger.sql    ← payment → invoice status propagation
│
└── 06-java-gui/                       ── Swing + JDBC client ───────────────
    ├── LendingPlatform.java           ← Full CRUD UI (bind-variable JDBC)
    └── items_table.sql                ← ITEMS catalog table the app drives
```

---

## Reading Order (recommended execution sequence)

1. **`01-schema/`** → run `01 → 02 → 03` (tables, constraints, seed data).
2. **`02-queries/`** → any order; `03_joins.sql` is the centerpiece.
3. **`03-views-indexes/`** → adds indexes, then views.
4. **`04-plsql/`** → procedures → exceptions → functions → DML params.
5. **`05-triggers/`** → validation → audit → INSTEAD OF → sync (run with `SET SERVEROUTPUT ON`).
6. **`06-java-gui/`** → `items_table.sql` first, then compile & run `LendingPlatform.java` with `ojdbc` on the classpath.

## Module ↔ Exercise Map (raw lab log → curated file)

| Lab dump section | Curated location |
|---|---|
| `CREATE TABLE` / `ALTER TABLE` / seed `SELECT`s | `01-schema/` |
| Filters + aggregates (`WHERE`, `COUNT`, `AVG`…) | `02-queries/01` + `02` |
| INNER / LEFT / RIGHT / FULL / SELF / CROSS joins | `02-queries/03_joins.sql` |
| `UNION` / `INTERSECT` / `MINUS` | `02-queries/04_set_operators.sql` |
| Scalar/quantified subqueries (`IN`, `ALL`, `ANY`) | `02-queries/05_subqueries.sql` |
| Correlated subquery, inline view, `WITH` CTE | `02-queries/06_correlated_and_cte.sql` |
| `CREATE INDEX` / `CREATE VIEW` exercises (EX7) | `03-views-indexes/` |
| Cursor procedures + exceptions (EX9) | `04-plsql/01` + `02` |
| Functions / DML procedure / OUT params (EXP10) | `04-plsql/03` + `04` |
| 10 trigger exercises + payment sync (EX8) | `05-triggers/` |
| Java JDBC Swing app (EX10) | `06-java-gui/` |
