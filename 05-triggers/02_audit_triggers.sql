/* ============================================================================
   FILE      : 05-triggers/02_audit_triggers.sql
   MODULE    : Audit / Notification Triggers (AFTER & BEFORE, ALL DML EVENTS)
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     Observe and narrate every state change on the platform's hot tables.
       * AFTER INSERT           : post-facto announcement of a new request.
       * AFTER UPDATE OF <col>  : column-scoped firing; :OLD vs :NEW exposes
                                  exactly what changed (status transitions).
       * BEFORE DELETE          : capture the doomed row's identity while it
                                  still exists (:OLD).
       * AFTER DELETE           : confirm the removal after the fact.
       * Conditional guard      : fire a message only when a rating DROPS
                                  (:NEW.machine_rating < :OLD.machine_rating).

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN
     A1 trg_request_after_insert   : AFTER INSERT ON lending_request.
     A2 trg_request_status_upd     : AFTER UPDATE OF request_status ON
                                     lending_request; prints "Old: X New: Y".
     A3 trg_owner_before_delete    : BEFORE DELETE ON owner; prints :OLD name.
     A4 trg_user_after_delete      : AFTER DELETE ON users; prints :OLD name.
     A5 trg_machine_rating_watch   : BEFORE UPDATE ON machine; message fires
                                     only on a downgrade.
     BEFORE triggers can veto or mutate :NEW; AFTER triggers see a committed-
     to-be row image and are the right home for audit and notification work.

   ----------------------------------------------------------------------------
   SAMPLE EXPECTED INPUT / OUTPUT  (SET SERVEROUTPUT ON; demos at file end)
     INSERT lending_request 102              -> "New Request Created: 102"
     UPDATE request 7 -> 'Completed'         -> "Old: Pending New: Completed"
     DELETE owner 5                          -> "Deleting Owner: Global Rent
                                                Corp" (rolled back afterwards)
     DELETE user 9                           -> "User Deleted: Anjali Rao"
                                                (rolled back afterwards)
     UPDATE machine 6 rating 4.2 -> 3.0      -> "Machine rating decreased"
   ============================================================================ */

SET SERVEROUTPUT ON

/* --- A1: announce every new lending request --------------------------------- */
CREATE OR REPLACE TRIGGER trg_request_after_insert
AFTER INSERT ON lending_request
FOR EACH ROW
BEGIN
   DBMS_OUTPUT.PUT_LINE('New Request Created: ' || :NEW.request_id);
END;
/

/* --- A2: narrate every status transition ------------------------------------- */
CREATE OR REPLACE TRIGGER trg_request_status_upd
AFTER UPDATE OF request_status ON lending_request
FOR EACH ROW
BEGIN
   DBMS_OUTPUT.PUT_LINE(
         'Old: ' || :OLD.request_status || ' New: ' || :NEW.request_status);
END;
/

/* --- A3: capture the owner identity before it disappears ---------------------- */
CREATE OR REPLACE TRIGGER trg_owner_before_delete
BEFORE DELETE ON owner
FOR EACH ROW
BEGIN
   DBMS_OUTPUT.PUT_LINE('Deleting Owner: ' || :OLD.owner_name);
END;
/

/* --- A4: confirm user deletion ------------------------------------------------- */
CREATE OR REPLACE TRIGGER trg_user_after_delete
AFTER DELETE ON users
FOR EACH ROW
BEGIN
   DBMS_OUTPUT.PUT_LINE('User Deleted: ' || :OLD.name);
END;
/

/* --- A5: downgrade detector ------------------------------------------------------ */
CREATE OR REPLACE TRIGGER trg_machine_rating_watch
BEFORE UPDATE ON machine
FOR EACH ROW
BEGIN
   IF :NEW.machine_rating < :OLD.machine_rating THEN
      DBMS_OUTPUT.PUT_LINE('Machine rating decreased');
   END IF;
END;
/

/* --- Proof battery (everything rolled back to keep seed data pristine) ------------- */
INSERT INTO lending_request
VALUES (102, 2, 5, DATE '2026-03-15', DATE '2026-03-16', DATE '2026-03-18',
        'Pending');
UPDATE lending_request
SET    request_status = 'Completed'
WHERE  request_id = 7;

DELETE FROM owner WHERE owner_id = 5;
DELETE FROM users WHERE user_id = 9;

UPDATE machine
SET    machine_rating = 3
WHERE  machine_id = 6;

ROLLBACK;
