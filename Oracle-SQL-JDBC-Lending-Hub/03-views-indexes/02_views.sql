/* ============================================================================
   FILE      : 03-views-indexes/02_views.sql
   MODULE    : Virtual Tables - Views, Update Restrictions and Security
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     Package recurring queries as schema objects. Every classic view flavour
     from the lab is reproduced against the LIVE lending schema:
       * Alias-headed view          : rename columns via the view header.
       * Filtered view              : horizontal (row) restriction.
       * WITH CHECK OPTION          : DML through the view cannot smuggle a
                                      row out of the view's defining filter.
       * WITH READ ONLY             : hard stop for any DML.
       * Expression view            : computed column (10% service charge).
       * Join view                  : denormalised catalog (machine + owner).
       * DISTINCT / aggregate views : inherently non-updatable combinations.
       * Key-preserved rule violation demo: inserting into a view without the
         base table's NOT NULL key -> ORA-01400.

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN / SAMPLE EXPECTED OUTPUT (full seed dataset)
     V1  machine_alias_view      : 8 rows, columns renamed MID/MACHINE_NAME/PRICE
     V2  expensive_machine_view  : Tower Crane 50000 | Excavator 12000 (price>5000)
     V3  available_machine_view  : 6 'Available' rows; CHECK OPTION blocks
                                   UPDATE ... SET status_available='Not Available'
                                   with ORA-01402.
     V4  readonly_machine_view   : 8 rows; any INSERT -> ORA-42399.
     V5  total_machine_price_view: 66195 (sum over all 8 machines)
     V6  machine_owner_view      : 7 rows (Hydraulic Press excluded: NULL owner)
     V7  distinct_owner_view     : 1,2,3,4 + NULL (Hydraulic Press' owner)
     V8  machine_price_service   : price_with_service = price*1.10 per row
     V9  owner_machine_count_view: owner 1->2, 2->2, 3->2, 4->1, NULL->1
     V10 NOT NULL violation demo : INSERT missing OWNER_ID -> ORA-01400
   ============================================================================ */

/* ------------------------------------------------------------------ V1 -----
   Column-aliased projection; header names drive the external interface      */
CREATE OR REPLACE VIEW machine_alias_view (mid, machine_name, price) AS
   SELECT machine_id, name, price
   FROM   machine;

SELECT * FROM machine_alias_view ORDER BY mid;

/* DROP VIEW machine_alias_view;  -- lifecycle: views are droppable metadata */

/* ------------------------------------------------------------------ V2 -----
   Horizontal restriction: the premium catalog                              */
CREATE OR REPLACE VIEW expensive_machine_view AS
   SELECT machine_id, name, price
   FROM   machine
   WHERE  price > 5000;

SELECT * FROM expensive_machine_view;

/* ------------------------------------------------------------------ V3 -----
   WITH CHECK OPTION: availability may only be managed through this view    */
CREATE OR REPLACE VIEW available_machine_view AS
   SELECT machine_id, name, status_available
   FROM   machine
   WHERE  status_available = 'Available'
   WITH CHECK OPTION;

SELECT * FROM available_machine_view;

/* -- Restriction demo (uncomment to test):
   UPDATE available_machine_view
   SET    status_available = 'Not Available'
   WHERE  machine_id = 1;
   -> ORA-01402: view WITH CHECK OPTION where-clause violation
---------------------------------------------------------------------------- */

/* ------------------------------------------------------------------ V4 -----
   READ ONLY catalog snapshot                                                */
CREATE OR REPLACE VIEW readonly_machine_view AS
   SELECT machine_id, name, price
   FROM   machine
   WITH READ ONLY;

SELECT * FROM readonly_machine_view ORDER BY machine_id;

/* -- Restriction demo (uncomment to test):
   INSERT INTO readonly_machine_view VALUES (300,'Ghost',10);
   -> ORA-42399: cannot perform a DML operation on a read-only view
---------------------------------------------------------------------------- */

/* ------------------------------------------------------------------ V5 -----
   Aggregate view: total catalogue value (not updatable: group function)    */
CREATE OR REPLACE VIEW total_machine_price_view AS
   SELECT SUM(price) AS total_price
   FROM   machine;

SELECT * FROM total_machine_price_view;   -- TOTAL_PRICE = 66195

/* ------------------------------------------------------------------ V6 -----
   Join view: denormalised catalog card                                      */
CREATE OR REPLACE VIEW machine_owner_view AS
   SELECT m.machine_id, m.name AS machine_name, o.owner_name
   FROM   machine m
          JOIN owner o ON m.owner_id = o.owner_id;

SELECT * FROM machine_owner_view ORDER BY machine_id;

/* ------------------------------------------------------------------ V7 -----
   DISTINCT view (eliminates duplicates -> inherently non-updatable)        */
CREATE OR REPLACE VIEW distinct_owner_view AS
   SELECT DISTINCT owner_id
   FROM   machine;

SELECT * FROM distinct_owner_view;

/* ------------------------------------------------------------------ V8 -----
   Expression view: price including a 10% service charge                    */
CREATE OR REPLACE VIEW machine_price_service_view AS
   SELECT machine_id, name, price,
          price * 1.10 AS price_with_service
   FROM   machine;

SELECT * FROM machine_price_service_view ORDER BY machine_id;

/* ------------------------------------------------------------------ V9 -----
   GROUP BY view: fleet size per owner                                       */
CREATE OR REPLACE VIEW owner_machine_count_view (owner_id, total_machines) AS
   SELECT owner_id, COUNT(machine_id)
   FROM   machine
   GROUP  BY owner_id;

SELECT * FROM owner_machine_count_view;

/* ------------------------------------------------------------------ V10 ----
   Key-preserved/NOT NULL restriction demo: the view exposes only OWNER_NAME,
   so inserting into it leaves OWNER_ID (PK -> NOT NULL) without a value.   */
CREATE OR REPLACE VIEW owner_name_view AS
   SELECT owner_name
   FROM   owner;

/* -- Expected failure (run to observe):
   INSERT INTO owner_name_view (owner_name) VALUES ('Rajesh');
   -> ORA-01400: cannot insert NULL into ("C##USER"."OWNER"."OWNER_ID")
---------------------------------------------------------------------------- */
