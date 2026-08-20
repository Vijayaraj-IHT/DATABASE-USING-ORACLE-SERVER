/* ============================================================================
   FILE      : 02-queries/06_correlated_and_cte.sql
   MODULE    : Correlated Subqueries, Inline Views and CTEs (WITH clause)
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     Three escalating ways to express per-group comparisons:
       * CORRELATED SUBQUERY : inner query references the outer row and is
         re-evaluated once per outer tuple (nested-loop semantics in logic).
       * INLINE VIEW : a named subquery in the FROM clause treated as a
         virtual table ("expensive_machines").
       * COMMON TABLE EXPRESSION (CTE): lift the aggregation into a readable
         WITH block, then join back -- the optimiser can materialise or
         flatten it, and the SQL reads top-down.

     Business question answered three ways: "Which machines are priced above
     the average of their OWN owner's fleet?" (a premium-per-owner analysis).

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN / SAMPLE EXPECTED OUTPUT (full seed dataset)
     Owner averages : o1 -> (50+650)/2   = 350   => Power Hammer  650   wins
                      o2 -> (75+120)/2   = 97.5  => Welding Machine 120 wins
                      o3 -> (800+12000)/2= 6400  => Excavator 12000    wins
                      o4 -> 50000 (single)       => nothing exceeds it
                      NULL owner (Hydraulic Press) -> AVG is NULL -> excluded
     Q1 correlated result : Power Hammer 650 | Welding Machine 120 |
                            Excavator 12000                            (3 rows)
     Q2 correlated count  : users with >2 requests -> 0 rows (max is 1)
     Q3 inline view       : machine 4 (50000) + machine 7 (12000)     (2 rows)
     Q4 CTE version of Q1 : identical 3 rows to Q1 (proof of equivalence)

     Why both? Q1 shows the engine's conceptual evaluation; Q4 is what you
     ship -- CTEs are testable fragments and avoid double-scanning MACHINE.
   ============================================================================ */

/* Q1 -- Premium-per-owner, correlated form ------------------------------------
   The inner AVG is scoped to the OUTER row's owner via the correlation
   predicate m.owner_id = m2.owner_id.                                       */
SELECT m.machine_id, m.name, m.price
FROM   machine m
WHERE  m.price > (
          SELECT AVG(m2.price)
          FROM   machine m2
          WHERE  m2.owner_id = m.owner_id
       );

/* Q2 -- Power users: correlated COUNT per borrower ----------------------------*/
SELECT u.user_id, u.name
FROM   users u
WHERE  (
          SELECT COUNT(*)
          FROM   lending_request lr
          WHERE  lr.borrower_id = u.user_id
       ) > 2;

/* Q3 -- Inline view: ad-hoc "expensive machines" relation priced above 1000 -- */
SELECT *
FROM   (
          SELECT machine_id, owner_id, price
          FROM   machine
          WHERE  price > 1000
       ) expensive_machines
ORDER  BY price DESC;

/* Q4 -- CTE form of Q1: compute per-owner averages once, then join -----------*/
WITH avg_price AS (
    SELECT owner_id, AVG(price) AS avgp
    FROM   machine
    GROUP  BY owner_id
)
SELECT m.machine_id, m.name, m.price
FROM   machine m
       JOIN avg_price a ON m.owner_id = a.owner_id
WHERE  m.price > a.avgp
ORDER  BY m.price;
