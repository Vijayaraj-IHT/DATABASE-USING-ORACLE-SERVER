/* ============================================================================
   FILE      : 01-schema/01_create_tables.sql
   MODULE    : Schema Definition (DDL)
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     Build the relational backbone of the Community Lending Platform: a peer-to-
     peer hub where owners list heavy machines and registered borrowers place
     lending requests that are invoiced, paid and condition-audited.

     Concepts demonstrated:
       * Entity integrity through NAMED PRIMARY KEY constraints.
       * Oracle-native typing: NUMBER / VARCHAR2 / CLOB / DATE.
       * Normalized design (3NF): OWNER and USERS are separated from MACHINE,
         and money flow is decomposed into TIMESHEET_INVOICE + PAYMENT.
       * Portability lesson captured from the raw lab log: TEXT / VARCHAR /
         DECIMAL are NOT Oracle types and raise ORA-00902; the equivalents
         (CLOB / VARCHAR2 / NUMBER(p,s)) are used here.

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN
     1. Idempotent teardown: an anonymous PL/SQL block drops any pre-existing
        copy of the seven tables (child-first order is unnecessary thanks to
        CASCADE CONSTRAINTS) so the script can be re-run safely.
     2. Seven CREATE TABLE statements define the entities with inline named
        PKs. Foreign keys are deliberately added in a separate script
        (02_add_constraints.sql) to mirror the classic "tables first,
        referential integrity second" teaching pattern.
     3. LOB columns (DESCRIPTION / REPORT / REPORT_MESSAGE) use CLOB so free
        text is stored inline with guaranteed Oracle semantics.

   ----------------------------------------------------------------------------
   SAMPLE EXPECTED INPUT / OUTPUT
     Input : SQL> @01-schema/01_create_tables.sql
     Output: PL/SQL procedure successfully completed.
             Table created.            (x7 -- one per entity)
             Verification count query reports 0 rows per table.
   ========================================================================== */

/* --------------------------------------------------------------------------
   0. Idempotent teardown (child + parent, constraints cascaded)
   -------------------------------------------------------------------------- */
BEGIN
   FOR t IN (
      SELECT table_name
      FROM   user_tables
      WHERE  table_name IN ('PAYMENT','CONDITION_REPORT','TIMESHEET_INVOICE',
                            'LENDING_REQUEST','MACHINE','OWNER','USERS')
   ) LOOP
      EXECUTE IMMEDIATE
         'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
   END LOOP;
END;
/

/* --------------------------------------------------------------------------
   1. USERS - registered platform members (borrowers and reviewers)
   -------------------------------------------------------------------------- */
CREATE TABLE users (
   user_id        NUMBER          CONSTRAINT pk_users PRIMARY KEY,
   name           VARCHAR2(100),
   email          VARCHAR2(100),
   phone          VARCHAR2(15),
   district       VARCHAR2(50),
   address        VARCHAR2(255),
   city           VARCHAR2(50),
   user_type      VARCHAR2(20),
   overall_rating NUMBER(3, 2)
);

/* --------------------------------------------------------------------------
   2. OWNER - organisations that list machines for rent/lease
   -------------------------------------------------------------------------- */
CREATE TABLE owner (
   owner_id   NUMBER         CONSTRAINT pk_owner PRIMARY KEY,
   owner_name VARCHAR2(100)
);

/* --------------------------------------------------------------------------
   3. MACHINE - rentable equipment offered by owners
   -------------------------------------------------------------------------- */
CREATE TABLE machine (
   machine_id          NUMBER         CONSTRAINT pk_machine PRIMARY KEY,
   owner_id            NUMBER,          -- FK added in 02_add_constraints.sql
   category_id         NUMBER,
   name                VARCHAR2(100),
   price_type          VARCHAR2(20),    -- Hour / Day / Month
   price               NUMBER(10, 2),
   status_available    VARCHAR2(20),    -- Available / Not Available
   conditional_status  VARCHAR2(20),    -- Good / Fair / Excellent ...
   machine_rating      NUMBER(3, 2),    -- 0.00 to 5.00
   description         CLOB
);

/* --------------------------------------------------------------------------
   4. LENDING_REQUEST - a borrower asking for a machine for a date window
   -------------------------------------------------------------------------- */
CREATE TABLE lending_request (
   request_id           NUMBER CONSTRAINT pk_lending_request PRIMARY KEY,
   machine_id           NUMBER,
   borrower_id          NUMBER,
   request_date         DATE,
   start_date           DATE,
   expected_return_date DATE,
   request_status       VARCHAR2(20)     -- Pending / Approved / Rejected ...
);

/* --------------------------------------------------------------------------
   5. TIMESHEET_INVOICE - commercial record of a fulfilled lending event
   -------------------------------------------------------------------------- */
CREATE TABLE timesheet_invoice (
   transaction_id NUMBER      CONSTRAINT pk_timesheet_invoice PRIMARY KEY,
   machine_id     NUMBER,
   owner_id       NUMBER,
   borrower_id    NUMBER,
   lending_type   VARCHAR2(20),          -- Rent / Lease
   payment_status VARCHAR2(20),          -- Paid / Unpaid / Pending
   report         CLOB
);

/* --------------------------------------------------------------------------
   6. PAYMENT - settlement of an invoice (1 invoice -> 0..n payments)
   -------------------------------------------------------------------------- */
CREATE TABLE payment (
   payment_id     NUMBER        CONSTRAINT pk_payment PRIMARY KEY,
   transaction_id NUMBER,
   payment_method VARCHAR2(20),          -- UPI / Credit Card / Net Banking / Cash
   payment_amount NUMBER(10, 2),
   payment_status VARCHAR2(20)
);

/* --------------------------------------------------------------------------
   7. CONDITION_REPORT - post-usage audit of a machine filed by a user
   -------------------------------------------------------------------------- */
CREATE TABLE condition_report (
   report_id        NUMBER CONSTRAINT pk_condition_report PRIMARY KEY,
   report_message   CLOB,
   user_id          NUMBER,
   machine_id       NUMBER,
   condition_status VARCHAR2(20),        -- Active / Maintenance / Repair
   report_date      DATE
);

/* --------------------------------------------------------------------------
   Verification: every table should exist and be empty at this stage
   -------------------------------------------------------------------------- */
SELECT 'USERS'             AS table_name, COUNT(*) AS row_count FROM users
UNION ALL SELECT 'OWNER',            COUNT(*) FROM owner
UNION ALL SELECT 'MACHINE',          COUNT(*) FROM machine
UNION ALL SELECT 'LENDING_REQUEST',  COUNT(*) FROM lending_request
UNION ALL SELECT 'TIMESHEET_INVOICE',COUNT(*) FROM timesheet_invoice
UNION ALL SELECT 'PAYMENT',          COUNT(*) FROM payment
UNION ALL SELECT 'CONDITION_REPORT', COUNT(*) FROM condition_report;
