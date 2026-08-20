/* ============================================================================
   FILE      : 04-plsql/01_cursor_procedures.sql
   MODULE    : PL/SQL Cursors - Implicit, Explicit and Parametric
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     Row-by-row processing where declarative SQL ends: walk the platform's
     users, owners, machines and requests programmatically and emit a report
     stream via DBMS_OUTPUT.
       * IMPLICIT cursor + cursor FOR loop  : Oracle opens/fetches/closes.
       * EXPLICIT cursor with %ROWTYPE      : full OPEN/LOOP/FETCH/EXIT/CLOSE
                                              lifecycle under script control.
       * PARAMETRIC CURSOR c(uid NUMBER)    : the cursor's WHERE clause is
                                              bound per call -- the PL/SQL
                                              analogue of a correlated filter.
       * Multi-join cursor                  : 3-table business document per row.

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN
     P1 show_users           : cursor FOR loop over every platform user.
     P2 high_rating_users    : same loop, WHERE overall_rating > 4.
     P3 show_owners          : manual explicit cursor, %NOTFOUND exit test,
                               OWNER%ROWTYPE anchored record declaration.
     P4 user_request_status  : nested loops -- outer implicit loop over users,
                               inner PARAMETRIC cursor bound to u.user_id.
     P5 user_machine_status  : one cursor spanning users/lending_request/
                               machine joins; aliased select-list to avoid the
                               duplicate NAME column pitfall.
     P6 check_user_rating    : scalar SELECT ... INTO + IF gate (IN parameter).
     P7 machine_details      : two-column SELECT ... INTO with %TYPE anchors.

   ----------------------------------------------------------------------------
   SAMPLE EXPECTED INPUT / OUTPUT
     Input : SQL> SET SERVEROUTPUT ON
             SQL> @04-plsql/01_cursor_procedures.sql
             SQL> EXEC show_owners;
     Output: 1 Suresh Constructions
             2 Metro Industrial Tools
             3 Vijay Infrastructure
             4 Elite Heavy Equipment
             5 Global Rent Corp

             SQL> EXEC user_request_status;   (abridged)
             User: Arjun Kumar
               Status: Approved
             User: Priya Sharma
               Status: Approved
             ...
             User: Sanjay Patel
               Status: Pending
             User: Vikram Singh          <- no requests: header only
             User: Anjali Rao            <- no requests: header only

             SQL> EXEC check_user_rating(3);
             Not Eligible                (Rahul Verma scores 3.9 < 4)
   ============================================================================ */

SET SERVEROUTPUT ON

/* --- P1: Implicit-cursor FOR loop over the member registry ---------------- */
CREATE OR REPLACE PROCEDURE show_users IS
BEGIN
   FOR u IN (SELECT user_id, name, email, phone
             FROM   users
             ORDER  BY user_id) LOOP
      DBMS_OUTPUT.PUT_LINE(
            u.user_id || ' ' || u.name || ' ' || u.email || ' ' || u.phone);
   END LOOP;
END;
/

/* --- P2: Same loop with a trust-gate filter ------------------------------- */
CREATE OR REPLACE PROCEDURE high_rating_users IS
BEGIN
   FOR u IN (SELECT user_id, name, overall_rating
             FROM   users
             WHERE  overall_rating > 4
             ORDER  BY user_id) LOOP
      DBMS_OUTPUT.PUT_LINE(
            u.user_id || ' ' || u.name || ' ' || u.overall_rating);
   END LOOP;
END;
/
/* Expected: 1 Arjun Kumar 4.8 | 4 Meena Reddy 4.5 | 5 Karthik Raj 4.1 |
             6 Divya Nair 4.6  | 9 Anjali Rao 4.3                         */

/* --- P3: Explicit cursor lifecycle ----------------------------------------- */
CREATE OR REPLACE PROCEDURE show_owners IS
   CURSOR c_owner IS
      SELECT owner_id, owner_name FROM owner ORDER BY owner_id;
   o  owner%ROWTYPE;
BEGIN
   OPEN  c_owner;
   LOOP
      FETCH c_owner INTO o;
      EXIT WHEN c_owner%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE(o.owner_id || ' ' || o.owner_name);
   END LOOP;
   CLOSE c_owner;
END;
/

/* --- P4: Parametric cursor driven by an outer implicit loop ---------------- */
CREATE OR REPLACE PROCEDURE user_request_status IS
   CURSOR c_req (uid NUMBER) IS
      SELECT request_status
      FROM   lending_request
      WHERE  borrower_id = uid;
BEGIN
   FOR u IN (SELECT user_id, name FROM users ORDER BY user_id) LOOP
      DBMS_OUTPUT.PUT_LINE('User: ' || u.name);
      FOR r IN c_req (u.user_id) LOOP          -- cursor RE-OPENS per user_id
         DBMS_OUTPUT.PUT_LINE('  Status: ' || r.request_status);
      END LOOP;
   END LOOP;
END;
/

/* --- P5: One cursor spanning a three-table business document ---------------- */
CREATE OR REPLACE PROCEDURE user_machine_status IS
   CURSOR c IS
      SELECT u.name AS borrower_name,
             m.name AS machine_name,
             l.request_status
      FROM   users u
             JOIN lending_request l ON u.user_id   = l.borrower_id
             JOIN machine m         ON m.machine_id = l.machine_id
      ORDER  BY u.user_id;
BEGIN
   FOR rec IN c LOOP
      DBMS_OUTPUT.PUT_LINE(
            rec.borrower_name || ' ' || rec.machine_name || ' ' ||
            rec.request_status);
   END LOOP;
END;
/
/* Expected (7 rows):
   Arjun Kumar Electric Drill Approved
   Priya Sharma Circular Saw Approved
   Rahul Verma Concrete Mixer Rejected
   Meena Reddy Tower Crane Approved
   Karthik Raj Welding Machine Approved
   Divya Nair Power Hammer Approved
   Sanjay Patel Circular Saw Pending                                    */

/* --- P6: Scalar lookup + business rule gate ---------------------------------- */
CREATE OR REPLACE PROCEDURE check_user_rating (uid NUMBER) IS
   rating users.overall_rating%TYPE;
BEGIN
   SELECT overall_rating
   INTO   rating
   FROM   users
   WHERE  user_id = uid;

   IF rating >= 4 THEN
      DBMS_OUTPUT.PUT_LINE('Eligible');
   ELSE
      DBMS_OUTPUT.PUT_LINE('Not Eligible');
   END IF;
END;
/

/* --- P7: Anchored two-column lookup -------------------------------------------- */
CREATE OR REPLACE PROCEDURE machine_details (mid NUMBER) IS
   mname  machine.name%TYPE;
   mprice machine.price%TYPE;
BEGIN
   SELECT name, price
   INTO   mname, mprice
   FROM   machine
   WHERE  machine_id = mid;

   DBMS_OUTPUT.PUT_LINE('Name: '  || mname);
   DBMS_OUTPUT.PUT_LINE('Price: ' || mprice);
END;
/
/* SQL> EXEC machine_details(1);
   Name: Electric Drill
   Price: 50                                                                   */

/* --- Invocation block: run the full tour in one call ---------------------------- */
BEGIN
   show_users;
   high_rating_users;
   show_owners;
   user_request_status;
   user_machine_status;
   check_user_rating(3);     -- Not Eligible  (3.9 < 4)
   check_user_rating(1);     -- Eligible      (4.8 >= 4)
   machine_details(1);
END;
/
