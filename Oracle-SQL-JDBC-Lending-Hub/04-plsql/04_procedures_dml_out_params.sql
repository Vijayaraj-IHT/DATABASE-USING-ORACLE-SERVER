/* ============================================================================
   FILE      : 04-plsql/04_procedures_dml_out_params.sql
   MODULE    : Action Procedures, OUT Parameters and IN OUT Functions
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     PL/SQL as the platform's service layer -- write-path procedures and
     parameter-passing discipline:
       * Action-dispatcher procedure     : m_machine routes INSERT / UPDATE /
                                           DELETE through one governed entry
                                           point (DML encapsulated in PL/SQL).
       * OUT parameter                   : owner_name returns a scalar through
                                           the parameter list (call-by-result).
       * IN OUT parameter in a function  : mac_det returns the price as the
                                           function result while mutating the
                                           name argument -- a two-value
                                           answer without composite types.

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN
     P1 m_machine(pid, pname, p_price, p_action)
        IF/ELSIF dispatches on p_action; COMMIT finalises the unit of work.
        Demo cycle: INSERT 301 -> UPDATE 301 -> DELETE 301 (verified between
        steps; uses ID 301 to stay clear of seeded machines 1-8).
     P2 owner_name(pid, pname OUT)  : SELECT ... INTO the OUT variable.
     F3 mac_det(pid, pname IN OUT)  : result = price; the IN OUT slot carries
        the machine name back to the caller simultaneously.

   ----------------------------------------------------------------------------
   SAMPLE EXPECTED INPUT / OUTPUT
     Input : SQL> SET SERVEROUTPUT ON
             SQL> @04-plsql/04_procedures_dml_out_params.sql
     Output (driver block prints):
           after INSERT -> 301 / Demo Drill / 150
           after UPDATE -> 301 / Demo Drill Pro / 180
           after DELETE -> machine 301 no longer exists
           owner_name(1) -> Suresh Constructions
           mac_det(1)    -> name Electric Drill, price 50
   ============================================================================ */

SET SERVEROUTPUT ON

/* --- P1: Governed DML dispatcher ------------------------------------------- */
CREATE OR REPLACE PROCEDURE m_machine (
   pid      NUMBER,
   pname    VARCHAR2,
   p_price  NUMBER,
   p_action VARCHAR2)
IS
BEGIN
   IF p_action = 'INSERT' THEN
      INSERT INTO machine (machine_id, name, price)
      VALUES (pid, pname, p_price);
   ELSIF p_action = 'UPDATE' THEN
      UPDATE machine
      SET    name = pname, price = p_price
      WHERE  machine_id = pid;
   ELSIF p_action = 'DELETE' THEN
      DELETE FROM machine
      WHERE  machine_id = pid;
   END IF;
   COMMIT;
END;
/

/* --- P2: OUT-parameter look-up ---------------------------------------------- */
CREATE OR REPLACE PROCEDURE owner_name (
   pid    NUMBER,
   pname  OUT VARCHAR2)
IS
BEGIN
   SELECT owner_name
   INTO   pname
   FROM   owner
   WHERE  owner_id = pid;
END;
/

/* --- F3: function + IN OUT parameter (two values, no record type) ------------ */
CREATE OR REPLACE FUNCTION mac_det (
   pid    NUMBER,
   pname  IN OUT VARCHAR2)
RETURN NUMBER IS
   v_price machine.price%TYPE;
BEGIN
   SELECT name, price
   INTO   pname, v_price
   FROM   machine
   WHERE  machine_id = pid;
   RETURN v_price;
END;
/

/* --- Driver block: the complete write-path tour -------------------------------- */
DECLARE
   v_id    machine.machine_id%TYPE;
   v_name  machine.name%TYPE;
   v_price machine.price%TYPE;
   v_owner owner.owner_name%TYPE;
BEGIN
   /* CRUD cycle on a scratch row (id 301) */
   m_machine(301, 'Demo Drill', 150, 'INSERT');
   SELECT machine_id, name, price INTO v_id, v_name, v_price
   FROM   machine WHERE machine_id = 301;
   DBMS_OUTPUT.PUT_LINE(
      'after INSERT -> ' || v_id || ' / ' || v_name || ' / ' || v_price);

   m_machine(301, 'Demo Drill Pro', 180, 'UPDATE');
   SELECT machine_id, name, price INTO v_id, v_name, v_price
   FROM   machine WHERE machine_id = 301;
   DBMS_OUTPUT.PUT_LINE(
      'after UPDATE -> ' || v_id || ' / ' || v_name || ' / ' || v_price);

   m_machine(301, NULL, NULL, 'DELETE');
   BEGIN
      SELECT machine_id INTO v_id FROM machine WHERE machine_id = 301;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         DBMS_OUTPUT.PUT_LINE('after DELETE -> machine 301 no longer exists');
   END;

   /* OUT parameter */
   owner_name(1, v_owner);
   DBMS_OUTPUT.PUT_LINE('owner_name(1) -> ' || v_owner);

   /* IN OUT function */
   v_name  := NULL;
   v_price := mac_det(1, v_name);
   DBMS_OUTPUT.PUT_LINE(
      'mac_det(1)    -> name ' || v_name || ', price ' || v_price);
END;
/
