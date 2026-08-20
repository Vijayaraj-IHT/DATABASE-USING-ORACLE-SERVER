/* ============================================================================
   FILE      : 01-schema/02_add_constraints.sql
   MODULE    : Referential Integrity (DDL)
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     Wire the seven lending-platform tables together with declarative FOREIGN
     KEY constraints so the database itself -- not application code -- guarantees
     that requests, invoices, payments and reports always reference real rows.

     Concepts demonstrated:
       * Referential integrity via ALTER TABLE ... ADD CONSTRAINT.
       * Named constraints (critical for readable ORA-02291 diagnostics).
       * Parent/child ordering at INSERT time (parents first, children last).
       * Nullable FK columns: MACHINE.OWNER_ID, LENDING_REQUEST.MACHINE_ID etc.
         stay nullable so "orphan" demonstration rows (an unassigned machine,
         a request not yet matched to a machine) remain expressible.

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN
     1. MACHINE.OWNER_ID          -> OWNER.OWNER_ID            (machine is owned)
     2. LENDING_REQUEST.MACHINE_ID-> MACHINE.MACHINE_ID        (request targets)
     3. LENDING_REQUEST.BORROWER_ID-> USERS.USER_ID            (request placed by)
     4. TIMESHEET_INVOICE has three FKs: machine / owner / borrower.
     5. PAYMENT.TRANSACTION_ID    -> TIMESHEET_INVOICE         (settles invoice)
     6. CONDITION_REPORT has two FKs: filing user + audited machine.
     No ON DELETE clause is supplied, so Oracle's default NO ACTION applies:
     parents cannot be deleted while children reference them (ORA-02292).

   ----------------------------------------------------------------------------
   SAMPLE EXPECTED INPUT / OUTPUT
     Input : SQL> @01-schema/02_add_constraints.sql
     Output: Table altered.   (x9)

     Sanity check that fails fast:
       INSERT INTO machine (machine_id, owner_id, name)
       VALUES (999, 77, 'Ghost Crane');
     Expected error:
       ORA-02291: integrity constraint (...FK_MACHINE_OWNER) violated
                  - parent key not found
   ========================================================================== */

/* Machine belongs to an owner ------------------------------------------- */
ALTER TABLE machine
   ADD CONSTRAINT fk_machine_owner
   FOREIGN KEY (owner_id) REFERENCES owner (owner_id);

/* Lending requests reference the machine and the borrowing user --------- */
ALTER TABLE lending_request
   ADD CONSTRAINT fk_lr_machine
   FOREIGN KEY (machine_id) REFERENCES machine (machine_id);

ALTER TABLE lending_request
   ADD CONSTRAINT fk_lr_borrower
   FOREIGN KEY (borrower_id) REFERENCES users (user_id);

/* Invoices reference machine, owner and borrower ------------------------ */
ALTER TABLE timesheet_invoice
   ADD CONSTRAINT fk_ti_machine
   FOREIGN KEY (machine_id) REFERENCES machine (machine_id);

ALTER TABLE timesheet_invoice
   ADD CONSTRAINT fk_ti_owner
   FOREIGN KEY (owner_id) REFERENCES owner (owner_id);

ALTER TABLE timesheet_invoice
   ADD CONSTRAINT fk_ti_borrower
   FOREIGN KEY (borrower_id) REFERENCES users (user_id);

/* Payments settle invoices ---------------------------------------------- */
ALTER TABLE payment
   ADD CONSTRAINT fk_payment_invoice
   FOREIGN KEY (transaction_id) REFERENCES timesheet_invoice (transaction_id);

/* Condition reports reference the filing user and the audited machine ---- */
ALTER TABLE condition_report
   ADD CONSTRAINT fk_cr_user
   FOREIGN KEY (user_id) REFERENCES users (user_id);

ALTER TABLE condition_report
   ADD CONSTRAINT fk_cr_machine
   FOREIGN KEY (machine_id) REFERENCES machine (machine_id);

/* --------------------------------------------------------------------------
   Verification: list the constraint catalog for this schema
   -------------------------------------------------------------------------- */
SELECT constraint_name, constraint_type, table_name, r_constraint_name
FROM   user_constraints
WHERE  table_name IN ('MACHINE','LENDING_REQUEST','TIMESHEET_INVOICE',
                      'PAYMENT','CONDITION_REPORT')
ORDER  BY table_name, constraint_name;
