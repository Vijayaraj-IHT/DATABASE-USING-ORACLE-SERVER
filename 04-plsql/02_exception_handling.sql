/* ============================================================================
   FILE      : 04-plsql/02_exception_handling.sql
   MODULE    : PL/SQL Exception Engineering
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     Make procedural code fail predictably. Three escalation levels:
       * PRE-DEFINED server exceptions: TOO_MANY_ROWS (ORA-01422) when a
         SELECT ... INTO (a scalar fetch) meets a multi-row set.
       * PRE-DEFINED runtime exceptions: INVALID_CURSOR (ORA-01001) when a
         FETCH is attempted on an already CLOSED explicit cursor.
       * USER-DEFINED exceptions: declare a named EXCEPTION, RAISE it inside
         business logic, and resolve it in the EXCEPTION WHEN ... handler --
         the PL/SQL equivalent of throwing a domain error.

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN
     E1 test_exception        : SELECT name INTO ... FROM users WHERE
                                user_type = 'Borrower' matches 9 rows -> the
                                exact fetch is impossible. The procedure traps
                                ORA-01422 and reports it gracefully.
     E2 invalid_cursor_demo   : OPEN -> CLOSE -> FETCH. The third step
                                violates the cursor state machine and raises
                                ORA-01001, also trapped.
     E3 check_price           : explicit cursor walks the fleet; any unit
                                priced below the 100/day floor RAISES the
                                custom "low_price" exception; the EXCEPTION
                                section converts it into an operator message.

   ----------------------------------------------------------------------------
   SAMPLE EXPECTED INPUT / OUTPUT
     Input : SQL> SET SERVEROUTPUT ON
             SQL> @04-plsql/02_exception_handling.sql
             SQL> EXEC test_exception;
     Output: ERROR ORA-01422: exact fetch returns more than requested number
             of rows                                    (trapped, not crashed)

             SQL> EXEC invalid_cursor_demo;
             ERROR ORA-01001: invalid cursor            (trapped, not crashed)

             SQL> EXEC check_price;
             Machine price below minimum threshold
             (Electric Drill at 50/day trips the floor on the very first row)
   ============================================================================ */

SET SERVEROUTPUT ON

/* --- E1: TOO_MANY_ROWS, trapped ------------------------------------------- */
CREATE OR REPLACE PROCEDURE test_exception IS
   uname users.name%TYPE;
BEGIN
   SELECT name                       -- 9 borrowers match -> cannot singularise
   INTO   uname
   FROM   users
   WHERE  user_type = 'Borrower';

   DBMS_OUTPUT.PUT_LINE(uname);
EXCEPTION
   WHEN TOO_MANY_ROWS THEN
      DBMS_OUTPUT.PUT_LINE(
         'ERROR ORA-01422: exact fetch returns more than requested number ' ||
         'of rows');
END;
/

/* --- E2: INVALID_CURSOR, trapped ------------------------------------------ */
CREATE OR REPLACE PROCEDURE invalid_cursor_demo IS
   CURSOR c IS SELECT owner_id, owner_name FROM owner;
   o  owner%ROWTYPE;
BEGIN
   OPEN  c;
   CLOSE c;
   FETCH c INTO o;                  -- cursor is CLOSED: illegal state
EXCEPTION
   WHEN INVALID_CURSOR THEN
      DBMS_OUTPUT.PUT_LINE('ERROR ORA-01001: invalid cursor');
END;
/

/* --- E3: User-defined domain exception ------------------------------------- */
CREATE OR REPLACE PROCEDURE check_price IS
   CURSOR c IS
      SELECT name, price FROM machine ORDER BY machine_id;
   low_price EXCEPTION;            -- domain error, not an Oracle error
BEGIN
   FOR m IN c LOOP
      IF m.price < 100 THEN
         RAISE low_price;
      END IF;
      DBMS_OUTPUT.PUT_LINE(m.name || ' ' || m.price);
   END LOOP;
EXCEPTION
   WHEN low_price THEN
      DBMS_OUTPUT.PUT_LINE('Machine price below minimum threshold');
END;
/

/* --- Invoke all three demos ------------------------------------------------- */
BEGIN
   test_exception;
   invalid_cursor_demo;
   check_price;
END;
/
