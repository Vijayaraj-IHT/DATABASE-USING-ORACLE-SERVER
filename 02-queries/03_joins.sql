/* ============================================================================
   FILE      : 02-queries/03_joins.sql
   MODULE    : Joins - INNER / LEFT / RIGHT / FULL / SELF / CROSS
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     Recombine the normalized schema back into business documents (catalog
     cards, request pipelines, settlement ledgers) by navigating the FK graph
     in every direction. Concepts demonstrated:
       * INNER JOIN            : matched tuples only.
       * LEFT  OUTER JOIN      : keep the left relation, pad with NULLs.
       * RIGHT OUTER JOIN      : keep the right relation (idle owners show up).
       * FULL  OUTER JOIN      : keep both sides -- orphans on either side.
       * SELF JOIN             : same-district borrower pairing (u1.id < u2.id
                                 removes duplicate and reflexive pairs).
       * CROSS JOIN            : Cartesian product -- shown with a guard note.

     The seed dataset was designed for this file: users 8-9, owner 5,
     machine 8, request 99, invoice 8 and report 7 are deliberate
     "edge/orphan" rows that make every OUTER join produce visible NULLs.

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN / SAMPLE EXPECTED OUTPUT (full seed dataset)
     Q1  INNER machine-owner  : Electric Drill | Suresh Constructions (1 row)
     Q2  INNER request-machine: 7 rows (orphan request 99 drops out)
     Q3  LEFT invoice-payment : 8 rows; invoice 8 shows NULL payment cols
     Q4  LEFT user-request    : 9 rows; Vikram Singh & Anjali Rao -> NULL
     Q5  RIGHT request-user   : same 9 rows as Q4 (symmetry demo)
     Q6  RIGHT report-machine : 8 rows; Welding Machine + Hydraulic Press NULL
     Q7  RIGHT machine-owner  : 8 rows; Global Rent Corp NULL (idle owner)
     Q8  RIGHT payment-invoice: 8 rows; invoice 8 NULL payment side
     Q9  FULL user-report     : 10 rows (Divya/Vikram/Anjali NULL + 1 orphan)
     Q10 FULL machine-request : 10 rows (Excavator, Hydraulic Press,
         orphan request 99)
     Q11 FULL owner-invoice   : 9 rows (Global Rent Corp NULL + invoice 8)
     Q12 FULL payment-invoice : 8 rows (all matched on this dataset)
     Q13 SELF same-district pairs: 7 rows -- Coimbatore (3 pairs), Chennai
         (3 pairs), Madurai (1 pair)
     Q14 CROSS users x machine: 72 rows -- capacity matrix, use with care!

     (Lab printouts captured mid-build show fewer rows -- e.g. 49 for the
     CROSS product -- because users/machines were still 7x7 at that point.)
   ============================================================================ */

/* -- INNER JOINS ------------------------------------------------------------
   Q1: full catalog card for machine 1 (machine + owning company)            */
SELECT m.name AS machine_name, o.owner_name
FROM   machine m
       JOIN owner o ON m.owner_id = o.owner_id
WHERE  m.machine_id = 1;

/* Q2: which machine (and price) sits behind each request? ------------------- */
SELECT lr.request_id, m.name AS machine_name, m.price
FROM   lending_request lr
       JOIN machine m ON lr.machine_id = m.machine_id;

/* Bonus INNER: audit trail per machine (only machines WITH reports) -------- */
SELECT m.name AS machine_name, c.report_message, c.condition_status
FROM   machine m
       JOIN condition_report c ON m.machine_id = c.machine_id
ORDER  BY m.machine_id;

/* -- LEFT JOINS -------------------------------------------------------------
   Q3: settlement ledger -- every invoice, paid or not ---------------------- */
SELECT t.transaction_id, t.lending_type, p.payment_amount, p.payment_status
FROM   timesheet_invoice t
       LEFT JOIN payment p ON t.transaction_id = p.transaction_id
ORDER  BY t.transaction_id;

/* Q4: borrower activity board -- idle borrowers must remain visible -------- */
SELECT u.name, lr.request_id, lr.request_status
FROM   users u
       LEFT JOIN lending_request lr ON u.user_id = lr.borrower_id
ORDER  BY u.name;

/* Bonus LEFT: fleet utilisation -- unrequested machines keep NULL ---------- */
SELECT m.name, lr.request_id
FROM   machine m
       LEFT JOIN lending_request lr ON m.machine_id = lr.machine_id
ORDER  BY m.name;

/* -- RIGHT JOINS ------------------------------------------------------------
   Q5: Q4 flipped (RIGHT anchor = users) -------------------------------------*/
SELECT u.name, lr.request_id, lr.request_status
FROM   lending_request lr
       RIGHT JOIN users u ON lr.borrower_id = u.user_id
ORDER  BY u.user_id;

/* Q6: every machine, audited or not ----------------------------------------*/
SELECT m.name, c.report_message, c.condition_status
FROM   condition_report c
       RIGHT JOIN machine m ON c.machine_id = m.machine_id
ORDER  BY m.machine_id;

/* Q7: every owner -- including Global Rent Corp, which lists nothing -------*/
SELECT o.owner_name, m.name AS machine_name, m.price
FROM   machine m
       RIGHT JOIN owner o ON m.owner_id = o.owner_id
ORDER  BY o.owner_id;

/* Q8: every invoice -- including orphan invoice 8 with no payment ----------*/
SELECT t.transaction_id, p.payment_amount, p.payment_status
FROM   payment p
       RIGHT JOIN timesheet_invoice t ON p.transaction_id = t.transaction_id
ORDER  BY t.transaction_id;

/* -- FULL OUTER JOINS -------------------------------------------------------
   Q9: users vs reports -- who never filed, plus reports with no user ------- */
SELECT u.name, c.report_date
FROM   users u
       FULL JOIN condition_report c ON u.user_id = c.user_id
ORDER  BY u.name NULLS LAST;

/* Q10: fleet vs demand -- unrequested machines AND unmatched requests ------ */
SELECT m.name, lr.request_id, lr.start_date
FROM   machine m
       FULL JOIN lending_request lr ON m.machine_id = lr.machine_id
ORDER  BY m.name NULLS LAST;

/* Q11: owners vs billing -- idle owners AND invoices with no owner --------- */
SELECT o.owner_name, t.transaction_id, t.lending_type
FROM   owner o
       FULL JOIN timesheet_invoice t ON o.owner_id = t.owner_id
ORDER  BY o.owner_name NULLS LAST;

/* Q12: payment vs invoice -- settlement reconciliation --------------------- */
SELECT p.payment_id, p.payment_amount, t.transaction_id
FROM   payment p
       FULL JOIN timesheet_invoice t ON p.transaction_id = t.transaction_id
ORDER  BY p.payment_id NULLS LAST;

/* -- SELF JOIN ----------------------------------------------------------------
   Q13: match borrowers living in the same district (carpool-style pairing).
        u1.user_id < u2.user_id removes both reflexive pairs (A,A) and the
        mirror duplicate (B,A).                                             */
SELECT u1.name AS borrower_1, u2.name AS borrower_2, u1.district
FROM   users u1
       JOIN users u2
         ON u1.district = u2.district
        AND u1.user_id < u2.user_id
ORDER  BY u1.district;

/* -- CROSS JOINS ----------------------------------------------------------------
   Q14: Cartesian capacity matrix. WARNING: |USERS| x |MACHINE| = 9 x 8 = 72
        rows; |LENDING_REQUEST| x |PAYMENT| = 8 x 8 = 64 rows. Never run a
        CROSS JOIN on production-sized tables -- shown for theory only.      */
SELECT u.name AS borrower, m.name AS machine
FROM   users u CROSS JOIN machine m
ORDER  BY u.name, m.name;

SELECT lr.request_id, p.payment_id
FROM   lending_request lr CROSS JOIN payment p
ORDER  BY lr.request_id, p.payment_id;
