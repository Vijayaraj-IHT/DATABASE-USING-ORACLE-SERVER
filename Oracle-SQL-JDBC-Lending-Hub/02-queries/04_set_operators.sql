/* ============================================================================
   FILE      : 02-queries/04_set_operators.sql
   MODULE    : Set Operators - UNION / INTERSECT / MINUS
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     Combine compatible row sets vertically (not side-by-side like joins).
     Oracle's three classic set operators map directly onto set theory:
       * UNION     : de-duplicated merge (use UNION ALL when dups are wanted).
       * INTERSECT : rows common to both sets.
       * MINUS     : set difference (Oracle's name for EXCEPT).

     Both branches of a set query must be union-compatible: identical column
     count with pairwise-compatible datatypes. Column names come from the
     FIRST branch, and ORDER BY may appear only once, at the end.

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN / SAMPLE EXPECTED OUTPUT (full seed dataset)
     Q1 UNION     : borrower + owner contact directory -> 14 rows
                    (9 users + 5 owners, alphabetical by CONTACT_NAME)
     Q2 INTERSECT : machines that are BOTH requested and condition-reported
                    {1,2,3,4,6}                                    -> 5 rows
     Q3 MINUS     : borrowers who requested but never filed a report
                    {1,2,3,4,5,6,7} - {1,2,3,4,5,7} = {6}         -> 1 row
                    (Divya Nair -- a follow-up nudge candidate!)

     Set ops are also a practical data-quality tool: wrap two counts in
     MINUS/UNION ALL to test whether a child FK ever references a missing
     parent row without writing procedural code.
   ============================================================================ */

/* Q1 -- Consolidated contact list: every human/organisation on the platform */
SELECT name AS contact_name, 'User' AS category
FROM   users
UNION
SELECT owner_name, 'Owner'
FROM   owner
ORDER  BY contact_name;

/* Q2 -- Machines under active demand AND active surveillance --------------- */
SELECT machine_id
FROM   lending_request
INTERSECT
SELECT machine_id
FROM   condition_report
ORDER  BY machine_id;

/* Q3 -- Borrowers who requested a machine but never filed a condition report */
SELECT borrower_id
FROM   lending_request
MINUS
SELECT user_id
FROM   condition_report;

/* BONUS -- Referential spot-check using MINUS (should return 0 rows) ---------
   Any child FK value that does not exist in the parent would surface here. */
SELECT machine_id FROM lending_request WHERE machine_id IS NOT NULL
MINUS
SELECT machine_id FROM machine;
