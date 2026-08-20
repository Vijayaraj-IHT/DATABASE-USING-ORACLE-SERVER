/* ============================================================================
   FILE      : 05-triggers/01_validation_triggers.sql
   MODULE    : Row-Level Validation Triggers (BEFORE ... FOR EACH ROW)
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     Enforce business rules that are richer than declarative CHECK constraints
     by intercepting DML row-by-row BEFORE it lands. Each trigger inspects the
     :NEW pseudo-record and vetoes bad input with RAISE_APPLICATION_ERROR,
     raising a deterministic application error code in the -20000..-20999
     band reserved for customers.
       * Range validation   : machine_rating must lie in [0, 5].
       * Existence validation: referenced owner must exist (procedural RI).
       * Domain validation  : payment_amount must be strictly positive.
       * Informatory trigger: look up machine name while creating a request.

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN
     T1 trg_machine_rating_chk  : BEFORE INSERT ON machine; rejects rating
                                  outside [0,5] with ORA-20001.
     T2 trg_machine_owner_chk   : BEFORE INSERT ON machine; counts OWNER rows
                                  matching :NEW.owner_id (NULL owners stay
                                  legal); raises ORA-20003 when the parent is
                                  missing -- the logged lab failure.
     T3 trg_request_machine_info: BEFORE INSERT ON lending_request; echoes the
                                  machine name (graceful when unassigned).
     T4 trg_payment_amount_chk  : BEFORE INSERT ON payment; raises ORA-20004
                                  for amounts <= 0.

   ----------------------------------------------------------------------------
   SAMPLE EXPECTED INPUT / OUTPUT  (SET SERVEROUTPUT ON; demos at file end)
     INSERT machine (rating 6)     -> ORA-20001: Invalid Machine Rating
     INSERT machine (owner_id 99)  -> ORA-20003: Owner does not exist
     INSERT lending_request 101    -> "Machine: Electric Drill"
     INSERT payment (amount -1000) -> ORA-20004: Invalid Payment Amount
   ============================================================================ */

SET SERVEROUTPUT ON

/* --- T1: rating stays inside the 0..5 star band ---------------------------- */
CREATE OR REPLACE TRIGGER trg_machine_rating_chk
BEFORE INSERT ON machine
FOR EACH ROW
BEGIN
   IF :NEW.machine_rating < 0 OR :NEW.machine_rating > 5 THEN
      RAISE_APPLICATION_ERROR(-20001, 'Invalid Machine Rating');
   END IF;
END;
/

/* --- T2: the referenced owner must really exist ------------------------------ */
CREATE OR REPLACE TRIGGER trg_machine_owner_chk
BEFORE INSERT ON machine
FOR EACH ROW
DECLARE
   v_count NUMBER;
BEGIN
   IF :NEW.owner_id IS NOT NULL THEN
      SELECT COUNT(*)
      INTO   v_count
      FROM   owner
      WHERE  owner_id = :NEW.owner_id;

      IF v_count = 0 THEN
         RAISE_APPLICATION_ERROR(-20003, 'Owner does not exist');
      END IF;
   END IF;
END;
/

/* --- T3: informatory lookup while a request is created ------------------------- */
CREATE OR REPLACE TRIGGER trg_request_machine_info
BEFORE INSERT ON lending_request
FOR EACH ROW
DECLARE
   v_name machine.name%TYPE;
BEGIN
   SELECT name
   INTO   v_name
   FROM   machine
   WHERE  machine_id = :NEW.machine_id;

   DBMS_OUTPUT.PUT_LINE('Machine: ' || v_name);
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('Machine: <not assigned yet>');
END;
/

/* --- T4: money guard - payment amount must be positive --------------------------- */
CREATE OR REPLACE TRIGGER trg_payment_amount_chk
BEFORE INSERT ON payment
FOR EACH ROW
BEGIN
   IF :NEW.payment_amount <= 0 THEN
      RAISE_APPLICATION_ERROR(-20004, 'Invalid Payment Amount');
   END IF;
END;
/

/* --- Proof battery: two failures and two successes ------------------------------- */
INSERT INTO machine (machine_id, owner_id, name, price_type, price,
                     status_available, machine_rating, description)
VALUES (301, 1, 'Crane', 'Hour', 600, 'Available', 6, 'Heavy');
/* expected -> ORA-20001: Invalid Machine Rating                              */

INSERT INTO machine (machine_id, owner_id, name, price_type, price,
                     status_available, machine_rating, description)
VALUES (302, 99, 'Loader', 'Day', 400, 'Available', 4, 'Normal');
/* expected -> ORA-20003: Owner does not exist                                */

INSERT INTO lending_request
VALUES (101, 1, 1, DATE '2026-03-10', DATE '2026-03-11', DATE '2026-03-12',
        'Approved');
/* expected -> "Machine: Electric Drill" then "1 row created."               */

INSERT INTO payment VALUES (901, 1, 'UPI', -1000, 'Completed');
/* expected -> ORA-20004: Invalid Payment Amount                              */

ROLLBACK;    -- keep the seed dataset pristine after the demo battery
