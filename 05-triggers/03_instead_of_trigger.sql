/* ============================================================================
   FILE      : 05-triggers/03_instead_of_trigger.sql
   MODULE    : INSTEAD OF Triggers - Writing Through Non-Updatable Views
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     A view built on a join/cartesian product is INHERENTLY non-updatable:
     Oracle cannot decide which base table should receive the row. An
     INSTEAD OF trigger substitutes procedural logic for the DML itself --
     the engine never touches the view, it runs the trigger body "instead".

       * usermachineview        : deliberately awkward view = USERS x MACHINE
                                  cartesian preview (admin dashboard join).
       * trg_instead_insert_view: INSTEAD OF INSERT routes ONLY the
                                  :NEW.user_id / :NEW.name payload into USERS;
                                  the machine column is informational.
       * Net effect             : client code INSERTs into the VIEW and the
                                  trigger maps it to the right base table.

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN
     1. CREATE VIEW usermachineview over the cartesian product. Any direct
        INSERT INTO usermachineview would otherwise raise ORA-01776/01732.
     2. INSTEAD OF INSERT fires per attempted row; :NEW carries the values
        the client wrote through the view's column list.
     3. The trigger performs a well-targeted INSERT INTO users
        (user_id, name) -- entity integrity otherwise enforced by PK_USERS.

   ----------------------------------------------------------------------------
   SAMPLE EXPECTED INPUT / OUTPUT
     Input : SQL> @05-triggers/03_instead_of_trigger.sql
             SQL> INSERT INTO usermachineview (user_id, name, machine_name)
                  VALUES (10, 'Vijay', 'Drill');
     Output: 1 row created.           (trigger fired INSTEAD of view DML)
             SQL> SELECT user_id, name FROM users WHERE user_id = 10;
             USER_ID NAME
             ------- -----
                  10 Vijay
             (final SELECT in the script proves it; demo row rolled back)
   ============================================================================ */

CREATE OR REPLACE VIEW usermachineview AS
   SELECT u.user_id,
          u.name AS user_name,
          m.name AS machine_name
   FROM   users u
          CROSS JOIN machine m;

/* Non-updatable by construction -> declare the substitution --------------- */
CREATE OR REPLACE TRIGGER trg_instead_insert_view
INSTEAD OF INSERT ON usermachineview
FOR EACH ROW
BEGIN
   INSERT INTO users (user_id, name)
   VALUES (:NEW.user_id, :NEW.user_name);
END;
/

/* --- Proof: write through the view, read from the base table --------------- */
INSERT INTO usermachineview (user_id, user_name, machine_name)
VALUES (10, 'Vijay', 'Drill');

SELECT user_id, name
FROM   users
WHERE  user_id = 10;            -- expected: 10 Vijay (trigger did the write)

ROLLBACK;                       -- keep the seed dataset pristine
