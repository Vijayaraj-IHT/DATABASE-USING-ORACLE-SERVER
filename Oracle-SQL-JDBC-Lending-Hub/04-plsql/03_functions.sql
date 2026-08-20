/* ============================================================================
   FILE      : 04-plsql/03_functions.sql
   MODULE    : Stored Functions - Scalar, REFCURSOR and Parameterised Cursors
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     Encapsulate read-only logic as functions callable from BOTH SQL and
     PL/SQL.
       * Scalar function              : mac_price / pricing -- one value out.
       * SYS_REFCURSOR function       : owner_mac returns a LIVE cursor, i.e. a
                                        result set as a first-class value
                                        (how mid-tier JDBC apps consume sets).
       * Explicit-cursor aggregation  : count_mac tallies rows procedurally.
       * Parametric-cursor function   : count_by(o) rebinds the cursor per call.
       * SQL-level invocation         : SELECT machine_id, pricing(machine_id)
                                        proves purity (no DML inside).

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN / SAMPLE EXPECTED OUTPUT (full seed dataset)
     F1 mac_price(1)           -> 50            (Electric Drill)
     F2 owner_mac(1)           -> machine 1 Electric Drill / machine 6 Power
                                  Hammer (owner 1's fleet, via ref cursor)
     F3 count_mac()            -> 8             (whole fleet)
     F4 count_by(2)            -> 2             (Metro Industrial Tools' fleet)
     F5 pricing(machine_id)    -> 8-row price list, computed inside SQL

     Invocation patterns covered: SELECT f(...) FROM DUAL, PL/SQL assignment
     EXEC :rc := owner_mac(1) with a REFCURSOR bind variable, and in-query
     projection (F5).
   ============================================================================ */

SET SERVEROUTPUT ON

/* --- F1: price lookup as a pure scalar function ---------------------------- */
CREATE OR REPLACE FUNCTION mac_price (pid NUMBER)
RETURN NUMBER IS
   v_price machine.price%TYPE;
BEGIN
   SELECT price INTO v_price FROM machine WHERE machine_id = pid;
   RETURN v_price;
END;
/
/* SQL> SELECT mac_price(1) FROM DUAL;   ->  50                               */

/* --- F2: return owner 1's fleet AS A RESULT SET (SYS_REFCURSOR) ------------ */
CREATE OR REPLACE FUNCTION owner_mac (p_owner NUMBER)
RETURN SYS_REFCURSOR IS
   v_cursor SYS_REFCURSOR;
BEGIN
   OPEN v_cursor FOR
      SELECT machine_id, name, price, owner_id
      FROM   machine
      WHERE  owner_id = p_owner;
   RETURN v_cursor;
END;
/
/* SQL*Plus consumption:
     VARIABLE rc REFCURSOR
     EXEC :rc := owner_mac(1);
     PRINT rc;
   -> MACHINE 1 Electric Drill 50 | MACHINE 6 Power Hammer 650               */

/* --- F3: count the fleet procedurally with an explicit cursor -------------- */
CREATE OR REPLACE FUNCTION count_mac
RETURN NUMBER IS
   CURSOR c IS SELECT machine_id FROM machine;
   v_count NUMBER := 0;
BEGIN
   FOR rec IN c LOOP
      v_count := v_count + 1;
   END LOOP;
   RETURN v_count;
END;
/
/* SQL> SELECT count_mac FROM DUAL;   ->  8                                   */

/* --- F4: parametric cursor - owner's fleet size ----------------------------- */
CREATE OR REPLACE FUNCTION count_by (p_owner NUMBER)
RETURN NUMBER IS
   CURSOR c (o NUMBER) IS
      SELECT machine_id FROM machine WHERE owner_id = o;
   v_count NUMBER := 0;
BEGIN
   FOR rec IN c (p_owner) LOOP      -- parameter bound at OPEN time
      v_count := v_count + 1;
   END LOOP;
   RETURN v_count;
END;
/
/* SQL> SELECT count_by(2) FROM DUAL;   ->  2                                 */

/* --- F5: invoking a user function INSIDE a SQL statement -------------------- */
CREATE OR REPLACE FUNCTION pricing (pid NUMBER)
RETURN NUMBER IS
   v_price machine.price%TYPE;
BEGIN
   SELECT price INTO v_price FROM machine WHERE machine_id = pid;
   RETURN v_price;
END;
/

SELECT machine_id,
       name,
       pricing (machine_id) AS price_via_function
FROM   machine
ORDER  BY machine_id;
/* Expected (8 rows): 1 Electric Drill 50 | 2 Circular Saw 75 | 3 Concrete
   Mixer 800 | 4 Tower Crane 50000 | 5 Welding Machine 120 | 6 Power Hammer
   650 | 7 Excavator 12000 | 8 Hydraulic Press 2500                        */

/* --- PL/SQL-side verification of every function ----------------------------- */
DECLARE
   rc      SYS_REFCURSOR;
   v_id    machine.machine_id%TYPE;
   v_name  machine.name%TYPE;
   v_price machine.price%TYPE;
   v_owner machine.owner_id%TYPE;
BEGIN
   DBMS_OUTPUT.PUT_LINE('mac_price(1) = ' || mac_price(1));
   DBMS_OUTPUT.PUT_LINE('count_mac()  = ' || count_mac);
   DBMS_OUTPUT.PUT_LINE('count_by(2)  = ' || count_by(2));

   rc := owner_mac(1);                 -- cursor selects 4 columns...
   LOOP
      FETCH rc INTO v_id, v_name, v_price, v_owner;   -- ...fetch 4 scalars
      EXIT WHEN rc%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE('owner 1 has: ' || v_name || ' @ ' || v_price);
   END LOOP;
   CLOSE rc;
END;
/
