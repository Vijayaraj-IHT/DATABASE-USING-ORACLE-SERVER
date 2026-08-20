/* ============================================================================
   FILE      : 01-schema/03_seed_data.sql
   MODULE    : Reference / Seed Data (DML)
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     Populate the platform with a coherent Tamil-Nadu-based community dataset
     that is rich enough to exercise every downstream module: joins (including
     RIGHT / FULL / CROSS on deliberately "orphan" rows), aggregates, set
     operators, subqueries, views, PL/SQL cursors and triggers.

     Concepts demonstrated:
       * Parent-before-child INSERT order dictated by the FK graph.
       * ANSI DATE literals (DATE '2024-01-02') as a cleaner, NLS-independent
         replacement for TO_DATE('02-JAN-2024','DD-MON-YYYY').
       * Nullable FK columns used intentionally: machine 8 (Hydraulic Press)
         has no owner, request 99 / invoice 8 are unmatched "edge" rows. These
         power the OUTER-join teaching examples in 02-queries/03_joins.sql.

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN
     Insert order (respects FK dependencies):
       1. USERS              (9 rows: 7 active borrowers + 2 idle users)
       2. OWNER              (5 rows: 4 with machines + Global Rent Corp idle)
       3. MACHINE            (8 rows: ids 1-7 fully owned; 8 owner NULL)
       4. LENDING_REQUEST    (8 rows: 1..7 matched, 99 unmatched/orphan)
       5. TIMESHEET_INVOICE  (8 rows: 1..7 matched, 8 unmatched/orphan)
       6. PAYMENT            (8 rows: one per invoice)
       7. CONDITION_REPORT   (7 rows: 6 matched + 1 orphan admin report)
     A single COMMIT ends the transaction; a validation query prints per-table
     cardinalities at the end.

   ----------------------------------------------------------------------------
   SAMPLE EXPECTED INPUT / OUTPUT
     Input : SQL> @01-schema/03_seed_data.sql
     Output: 1 row created. (x53)  Commit complete.
             Final verification query:

             TABLE_NAME           ROW_COUNT
             ------------------- ---------
             USERS                       9
             OWNER                       5
             MACHINE                     8
             LENDING_REQUEST             8
             TIMESHEET_INVOICE           8
             PAYMENT                     8
             CONDITION_REPORT            7
   ========================================================================== */

/* --------------------------------------------------------------------------
   1. USERS (parents of lending_request, timesheet_invoice, condition_report)
   -------------------------------------------------------------------------- */
INSERT INTO users VALUES
   (1, 'Arjun Kumar',  'arjun.kumar@gmail.com',  '9876543210', 'Coimbatore',
    '12 MG Road',        'Coimbatore', 'Borrower', 4.8);
INSERT INTO users VALUES
   (2, 'Priya Sharma', 'priya.sharma@yahoo.com', '9123456780', 'Chennai',
    '45 Anna Salai',     'Chennai',    'Borrower', 4.2);
INSERT INTO users VALUES
   (3, 'Rahul Verma',  'rahul.verma@outlook.com','9988776655', 'Madurai',
    '78 Lake View Street','Madurai',   'Borrower', 3.9);
INSERT INTO users VALUES
   (4, 'Meena Reddy',  'meena.reddy@gmail.com',  '9090909090', 'Salem',
    '23 Green Park',     'Salem',      'Borrower', 4.5);
INSERT INTO users VALUES
   (5, 'Karthik Raj',  'karthik.raj@gmail.com',  '9000011111', 'Coimbatore',
    '9 Cross Cut Road',  'Coimbatore', 'Borrower', 4.1);
INSERT INTO users VALUES
   (6, 'Divya Nair',   'divya.nair@gmail.com',   '9887766554', 'Chennai',
    '21 T Nagar Street', 'Chennai',    'Borrower', 4.6);
INSERT INTO users VALUES
   (7, 'Sanjay Patel', 'sanjay.patel@gmail.com', '9776655443', 'Madurai',
    '56 Temple Road',    'Madurai',    'Borrower', 3.7);
/* Idle users: exist but have never requested a machine (OUTER-join demos) */
INSERT INTO users VALUES
   (8, 'Vikram Singh', 'vikram.singh@gmail.com', '9876501234', 'Coimbatore',
    '14 Avinashi Road',  'Coimbatore', 'Borrower', 4.0);
INSERT INTO users VALUES
   (9, 'Anjali Rao',   'anjali.rao@gmail.com',   '9765432109', 'Chennai',
    '88 Besant Nagar',   'Chennai',    'Borrower', 4.3);

/* --------------------------------------------------------------------------
   2. OWNER (parent of machine, timesheet_invoice)
   -------------------------------------------------------------------------- */
INSERT INTO owner VALUES (1, 'Suresh Constructions');
INSERT INTO owner VALUES (2, 'Metro Industrial Tools');
INSERT INTO owner VALUES (3, 'Vijay Infrastructure');
INSERT INTO owner VALUES (4, 'Elite Heavy Equipment');
/* Owner with no machines yet (powers RIGHT JOIN demonstration) */
INSERT INTO owner VALUES (5, 'Global Rent Corp');

/* --------------------------------------------------------------------------
   3. MACHINE (child of owner)
   -------------------------------------------------------------------------- */
INSERT INTO machine VALUES
   (1, 1, 10, 'Electric Drill',  'Hour', 50,    'Available',    'Good',
    4.7, 'Industrial drilling tool');
INSERT INTO machine VALUES
   (2, 2, 20, 'Circular Saw',    'Hour', 75,    'Available',    'Fair',
    4.3, 'Precision cutting machine');
INSERT INTO machine VALUES
   (3, 3, 30, 'Concrete Mixer',  'Day',  800,   'Not Available','Good',
    4.6, 'Heavy duty mixer');
INSERT INTO machine VALUES
   (4, 4, 40, 'Tower Crane',     'Month',50000, 'Available',    'Excellent',
    4.9, 'Large construction crane');
INSERT INTO machine VALUES
   (5, 2, 20, 'Welding Machine', 'Hour', 120,   'Available',    'Good',
    4.4, 'Arc welding tool');
INSERT INTO machine VALUES
   (6, 1, 10, 'Power Hammer',    'Day',  650,   'Available',    'Good',
    4.2, 'Heavy duty hammer');
INSERT INTO machine VALUES
   (7, 3, 30, 'Excavator',       'Day',  12000, 'Not Available','Excellent',
    4.8, 'Earth moving equipment');
/* Unassigned machine -- owner_id intentionally NULL (OUTER-join demos) */
INSERT INTO machine VALUES
   (8, NULL, 50, 'Hydraulic Press','Day', 2500, 'Available',    'Good',
    4.5, 'Industrial hydraulic press');

/* --------------------------------------------------------------------------
   4. LENDING_REQUEST (child of machine + users)
   -------------------------------------------------------------------------- */
INSERT INTO lending_request VALUES
   (1, 1, 1, DATE'2024-01-01', DATE'2024-01-02', DATE'2024-01-05','Approved');
INSERT INTO lending_request VALUES
   (2, 2, 2, DATE'2024-01-03', DATE'2024-01-04', DATE'2024-01-06','Approved');
INSERT INTO lending_request VALUES
   (3, 3, 3, DATE'2024-01-05', DATE'2024-01-06', DATE'2024-01-10','Rejected');
INSERT INTO lending_request VALUES
   (4, 4, 4, DATE'2024-01-08', DATE'2024-01-10', DATE'2024-02-10','Approved');
INSERT INTO lending_request VALUES
   (5, 5, 5, DATE'2024-01-12', DATE'2024-01-13', DATE'2024-01-15','Approved');
INSERT INTO lending_request VALUES
   (6, 6, 6, DATE'2024-01-15', DATE'2024-01-16', DATE'2024-01-20','Approved');
INSERT INTO lending_request VALUES
   (7, 2, 7, DATE'2024-01-18', DATE'2024-01-19', DATE'2024-01-22','Pending');
/* Orphan request: not yet matched to a machine or borrower (FULL JOIN demo) */
INSERT INTO lending_request VALUES
   (99, NULL, NULL, DATE'2024-02-20', DATE'2024-02-20', DATE'2024-02-25',
    'Pending');

/* --------------------------------------------------------------------------
   5. TIMESHEET_INVOICE (child of machine + owner + users)
   -------------------------------------------------------------------------- */
INSERT INTO timesheet_invoice VALUES
   (1, 1, 1, 1, 'Rent',  'Paid',   'Returned in good condition');
INSERT INTO timesheet_invoice VALUES
   (2, 2, 2, 2, 'Rent',  'Paid',   'Minor delay in return');
INSERT INTO timesheet_invoice VALUES
   (3, 3, 3, 3, 'Lease', 'Unpaid', 'Payment pending');
INSERT INTO timesheet_invoice VALUES
   (4, 4, 4, 4, 'Lease', 'Paid',   'Delivered on schedule');
INSERT INTO timesheet_invoice VALUES
   (5, 5, 2, 5, 'Rent',  'Paid',   'Smooth transaction');
INSERT INTO timesheet_invoice VALUES
   (6, 6, 1, 6, 'Rent',  'Paid',   'Returned on time');
INSERT INTO timesheet_invoice VALUES
   (7, 2, 2, 7, 'Lease', 'Unpaid', 'Awaiting payment');
/* Orphan invoice -- created manually, no FK partners (OUTER-join demo) */
INSERT INTO timesheet_invoice VALUES
   (8, NULL, NULL, NULL, 'Rent', 'Pending', 'Awaiting confirmation');

/* --------------------------------------------------------------------------
   6. PAYMENT (child of timesheet_invoice)
   -------------------------------------------------------------------------- */
INSERT INTO payment VALUES (1, 1, 'UPI',          250,   'Paid');
INSERT INTO payment VALUES (2, 2, 'Credit Card',  450,   'Paid');
INSERT INTO payment VALUES (3, 3, 'Net Banking',  50000, 'Unpaid');
INSERT INTO payment VALUES (4, 4, 'UPI',          300,   'Paid');
INSERT INTO payment VALUES (5, 5, 'UPI',          600,   'Paid');
INSERT INTO payment VALUES (6, 6, 'Credit Card',  1300,  'Paid');
INSERT INTO payment VALUES (7, 7, 'Cash',         75,    'Unpaid');
INSERT INTO payment VALUES (8, 8, 'Cash',         1000,  'Pending');

/* --------------------------------------------------------------------------
   7. CONDITION_REPORT (child of users + machine)
   -------------------------------------------------------------------------- */
INSERT INTO condition_report VALUES
   (1, 'Working perfectly',         1, 1, 'Active',      DATE'2024-01-05');
INSERT INTO condition_report VALUES
   (2, 'Blade requires sharpening', 2, 2, 'Maintenance', DATE'2024-01-06');
INSERT INTO condition_report VALUES
   (3, 'Motor overheating issue',   3, 3, 'Repair',      DATE'2024-01-10');
INSERT INTO condition_report VALUES
   (4, 'Excellent performance',     4, 4, 'Active',      DATE'2024-02-10');
INSERT INTO condition_report VALUES
   (5, 'Minor vibration observed',  5, 6, 'Maintenance', DATE'2024-01-20');
INSERT INTO condition_report VALUES
   (6, 'Hydraulic leak detected',   7, 7, 'Repair',      DATE'2024-01-25');
/* Orphan admin report: filed centrally, not yet linked to a user/machine */
INSERT INTO condition_report VALUES
   (7, 'Scheduled maintenance inspection', NULL, NULL, 'Maintenance',
    DATE'2024-02-15');

COMMIT;

/* --------------------------------------------------------------------------
   Verification: expected cardinalities after seeding
   -------------------------------------------------------------------------- */
SELECT 'USERS'             AS table_name, COUNT(*) AS row_count FROM users
UNION ALL SELECT 'OWNER',            COUNT(*) FROM owner
UNION ALL SELECT 'MACHINE',          COUNT(*) FROM machine
UNION ALL SELECT 'LENDING_REQUEST',  COUNT(*) FROM lending_request
UNION ALL SELECT 'TIMESHEET_INVOICE',COUNT(*) FROM timesheet_invoice
UNION ALL SELECT 'PAYMENT',          COUNT(*) FROM payment
UNION ALL SELECT 'CONDITION_REPORT', COUNT(*) FROM condition_report;
