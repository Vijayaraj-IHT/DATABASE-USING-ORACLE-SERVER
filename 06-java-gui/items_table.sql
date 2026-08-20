/* ============================================================================
   FILE      : 06-java-gui/items_table.sql
   MODULE    : Standalone Catalog Table for the Swing/JDBC Client
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     Provide the exact single-table schema the LendingPlatform Swing app
     performs CRUD against. ITEMS is a deliberately simplified, denormalised
     projection of the full MACHINE entity (free-form CATEGORY text instead of
     a category FK, no owner linkage) so the JDBC exercise stays focused on
     PreparedStatement mechanics rather than relational navigation.
       * Entity integrity: ITEM_ID primary key -- the app's "Remove Item" and
         "Update Price" operations key off it.
       * NUMBER(10,2) money column, mapped to JDBC float in the client.
       * Idempotent drop guard so refreshes are one command.

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN
     1. Anonymous block drops ITEMS if it exists (re-runnable setup).
     2. CREATE TABLE items with four position-stable columns -- the client
        writes INSERT INTO ITEMS VALUES (?,?,?,?) positionally, so do NOT
        reorder columns without updating LendingPlatform.java.
     3. Four seed rows give the "View Catalog" button immediate content.

   ----------------------------------------------------------------------------
   SAMPLE EXPECTED INPUT / OUTPUT
     Input : SQL> @06-java-gui/items_table.sql
     Output: Table created. / Commit complete.
             SELECT * FROM ITEMS ->
             ITEM_ID ITEM_NAME        CATEGORY     PRICE_PER_DAY
             ------- ---------------- ------------ -------------
               1001   Electric Drill   Power Tools             50
               1002   Concrete Mixer   Machinery              800
               1003   Welding Machine  Power Tools            120
               1004   Tower Crane      Heavy Equipment      50000
   ========================================================================== */

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE items PURGE';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN   -- ORA-00942: table or view does not exist
         RAISE;
      END IF;
END;
/

CREATE TABLE items (
   item_id       NUMBER        CONSTRAINT pk_items PRIMARY KEY,
   item_name     VARCHAR2(100),
   category      VARCHAR2(50),
   price_per_day NUMBER(10, 2)
);

INSERT INTO items VALUES (1001, 'Electric Drill',  'Power Tools',     50);
INSERT INTO items VALUES (1002, 'Concrete Mixer',  'Machinery',      800);
INSERT INTO items VALUES (1003, 'Welding Machine', 'Power Tools',    120);
INSERT INTO items VALUES (1004, 'Tower Crane',     'Heavy Equipment', 50000);

COMMIT;

SELECT * FROM items ORDER BY item_id;
