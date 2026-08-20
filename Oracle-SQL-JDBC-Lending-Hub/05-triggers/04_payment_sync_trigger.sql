/* ============================================================================
   FILE      : 05-triggers/04_payment_sync_trigger.sql
   MODULE    : Cross-Table State Propagation Trigger
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     Keep the invoice header consistent with its settlement row: when a
     payment flips status (Unpaid -> Paid, Pending -> Paid, ...), the parent
     TIMESHEET_INVOICE must follow automatically -- no human reconciliation.
       * AFTER UPDATE OF payment_status ON payment : column-scoped firing.
       * Cross-table UPDATE inside the trigger     : legal here because a
         trigger on PAYMENT may freely read/write TIMESHEET_INVOICE -- the
         mutating-table restriction (ORA-04091) only applies to the table the
         trigger is defined ON.
       * Denormalised-status synchronisation       : a pragmatic alternative
         to deriving invoice status via a view at read time.

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN
     1. Trigger fires per payment row whose payment_status column changes.
     2. :NEW.payment_status is pushed to every invoice whose transaction_id
        equals :NEW.transaction_id (FK link fk_payment_invoice).
     3. The demo updates payment 7 (Unpaid -> Paid) and shows invoice 7
        flipping in lockstep; a ROLLBACK restores the seed state.

   ----------------------------------------------------------------------------
   SAMPLE EXPECTED INPUT / OUTPUT
     Before : payment 7 = Unpaid      | timesheet_invoice 7 = Unpaid
       UPDATE payment SET payment_status = 'Paid' WHERE payment_id = 7;
     After  : payment 7 = Paid        | timesheet_invoice 7 = Paid
              (the verification SELECT prints both sides as Paid;
               ROLLBACK returns the dataset to its seeded state)
   ============================================================================ */

CREATE OR REPLACE TRIGGER trg_after_payment_update
AFTER UPDATE OF payment_status ON payment
FOR EACH ROW
BEGIN
   UPDATE timesheet_invoice
   SET    payment_status = :NEW.payment_status
   WHERE  transaction_id = :NEW.transaction_id;
END;
/

/* --- Proof: settle payment 7 and watch invoice 7 follow --------------------- */
SELECT p.payment_id, p.payment_status      AS payment_side,
       t.payment_status                    AS invoice_side
FROM   payment p
       JOIN timesheet_invoice t
         ON p.transaction_id = t.transaction_id
WHERE  p.payment_id = 7;                 -- expected: Unpaid / Unpaid

UPDATE payment
SET    payment_status = 'Paid'
WHERE  payment_id = 7;

SELECT p.payment_id, p.payment_status      AS payment_side,
       t.payment_status                    AS invoice_side
FROM   payment p
       JOIN timesheet_invoice t
         ON p.transaction_id = t.transaction_id
WHERE  p.payment_id = 7;                 -- expected: Paid / Paid

ROLLBACK;
