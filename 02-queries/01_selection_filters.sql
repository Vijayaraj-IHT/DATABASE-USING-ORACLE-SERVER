/* ============================================================================
   FILE      : 02-queries/01_selection_filters.sql
   MODULE    : Relational Algebra - SELECTION (sigma) + PROJECTION (pi)
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     Master the WHERE clause as the physical embodiment of the SELECTION
     operator, combined with column PROJECTION, across the platform tables:
       * equality on a VARCHAR2 column (DISTRICT)
       * range predicate on a NUMBER(3,2) rating
       * status flag filtering with column pruning
       * temporal filtering with an explicit, NLS-safe date literal

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN
     Q1  Borrowers living in Coimbatore (name + e-mail only).
     Q2  High-trust users: overall_rating > 4.2 (full row projection).
     Q3  Available fleet: restrict to status_available = 'Available' and
         project only name/price (document-lookup view of the catalog).
     Q4  Condition reports filed strictly after 02-JAN-2024. DATE '2024-01-02'
         is used instead of TO_DATE so the predicate never depends on the
         session NLS_DATE_FORMAT.

   ----------------------------------------------------------------------------
   SAMPLE EXPECTED INPUT / OUTPUT  (full seed dataset)
     Q1 -> Arjun Kumar  / arjun.kumar@gmail.com
           Karthik Raj  / karthik.raj@gmail.com
           Vikram Singh / vikram.singh@gmail.com          (3 rows)
     Q2 -> user 1 Arjun Kumar 4.8 | user 4 Meena Reddy 4.5 |
           user 6 Divya Nair 4.6 | user 9 Anjali Rao 4.3  (4 rows)
     Q3 -> Electric Drill 50 | Circular Saw 75 | Tower Crane 50000 |
           Welding Machine 120 | Power Hammer 650 | Hydraulic Press 2500
                                                           (6 rows)
     Q4 -> all 7 condition reports (every report_date is after 02-JAN-2024)
   ============================================================================ */

/* Q1 -- District lookup: who can I borrow from in Coimbatore? -------------- */
SELECT name, email
FROM   users
WHERE  district = 'Coimbatore';

/* Q2 -- Trust gate: users whose community rating clears 4.2 --------------- */
SELECT user_id, name, email, district, city, overall_rating
FROM   users
WHERE  overall_rating > 4.2
ORDER  BY overall_rating DESC;

/* Q3 -- Catalog view: currently rentable machines ------------------------- */
SELECT name, price
FROM   machine
WHERE  status_available = 'Available';

/* Q4 -- Audit sweep: reports filed after the first maintenance cycle ------ */
SELECT report_id, report_message, user_id, machine_id, condition_status,
       report_date
FROM   condition_report
WHERE  report_date > DATE '2024-01-02'
ORDER  BY report_date;
