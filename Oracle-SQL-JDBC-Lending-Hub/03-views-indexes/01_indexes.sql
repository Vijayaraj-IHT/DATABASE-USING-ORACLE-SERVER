/* ============================================================================
   FILE      : 03-views-indexes/01_indexes.sql
   MODULE    : Secondary Access Paths - B-Tree Indexes
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     Accelerate the platform's hot lookup paths with explicit indexes and
     learn how to inspect (and retire) them. Concepts demonstrated:
       * Plain B-tree index on MACHINE(NAME) -- powers catalog search.
       * UNIQUE index on USERS(EMAIL) -- enforces an alternate key that the
         logical model implies but no PK covers.
       * Descending-key index on MACHINE(PRICE DESC) -- supports "premium
         first" sorting without a sort step.
       * Metadata introspection through USER_INDEXES / USER_IND_COLUMNS.
       * Index lifecycle: CREATE ... inspect ... DROP.

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN
     1.  Create idx_machine_name for equality/range probes on machine names.
     2.  Query USER_INDEXES to prove the catalog records the new segment.
     3.  Drop it again (indexes are physical, never logical -- the table is
         untouched).
     4.  Create uq_users_email UNIQUE: inserting a duplicate e-mail fails with
         ORA-00001.
     5.  Create price_desc_idx (price DESC) so
         ORDER BY price DESC can be satisfied natively from the index.

   ----------------------------------------------------------------------------
   SAMPLE EXPECTED INPUT / OUTPUT
     Input : SQL> @03-views-indexes/01_indexes.sql
     Output: Index created.  (x3, with a drop + recreate cycle on step 1)

     Catalog excerpt after creation:
       INDEX_NAME           TABLE_NAME   UNIQUENESS
       -------------------- ------------ ---------
       IDX_MACHINE_NAME     MACHINE      NONUNIQUE
       UQ_USERS_EMAIL       USERS        UNIQUE
       PRICE_DESC_IDX       MACHINE      NONUNIQUE

     Duplicate-proof check:
       INSERT INTO users (user_id, email) VALUES (10, 'arjun.kumar@gmail.com');
       -> ORA-00001: unique constraint (...UQ_USERS_EMAIL) violated
   ============================================================================ */

/* 1 -- Catalog search accelerator -------------------------------- */
CREATE INDEX idx_machine_name
   ON machine (name);

/* Proof from the data dictionary --------------------------------- */
SELECT index_name, table_name, uniqueness
FROM   user_indexes
WHERE  table_name IN ('MACHINE', 'USERS')
ORDER  BY table_name, index_name;

/* 2 -- Indexes are physical: dropping never harms table data ------ */
DROP INDEX idx_machine_name;

/* Recreate for ongoing use --------------------------------------- */
CREATE INDEX idx_machine_name
   ON machine (name);

/* 3 -- Business-rule enforcement: one account per e-mail ---------- */
CREATE UNIQUE INDEX uq_users_email
   ON users (email);

/* 4 -- Premium-first browsing without a sort step ----------------- */
CREATE INDEX price_desc_idx
   ON machine (price DESC);

/* Final catalog state --------------------------------------------- */
SELECT index_name, table_name, uniqueness
FROM   user_indexes
WHERE  table_name IN ('MACHINE', 'USERS')
ORDER  BY table_name, index_name;
