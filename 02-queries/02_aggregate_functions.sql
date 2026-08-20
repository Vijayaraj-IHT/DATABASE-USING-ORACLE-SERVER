/* ============================================================================
   FILE      : 02-queries/02_aggregates.sql
   MODULE    : Aggregation - scalar rollups and GROUP BY partitioning
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     Distil the lending catalog and money trail into business metrics.
     Concepts demonstrated:
       * Scalar aggregates: COUNT / AVG / MAX / SUM over a single group.
       * Aggregates with a WHERE pre-filter (AVG over available machines only).
       * GROUP BY with a LEFT JOIN so zero-count entities survive (owners or
         machines with no requests still report 0, not an absent row).
       * Expression columns (price * 5) aliased for readability.

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN
     1.  Fleet size and request volume via COUNT(*).
     2.  Price intelligence: AVG(price) over the available fleet, MAX(price)
         over the whole catalog.
     3.  Revenue intelligence: SUM(payment_amount) across all settlements.
     4.  Rental simulation: 5-unit rental cost for every hour-priced machine.
     5.  GROUP BY rollups: requests per borrower and per machine. LEFT JOIN
         keeps entities whose request count is 0 (Vikram Singh, Anjali Rao,
         Excavator, Hydraulic Press) visible in the result.

   ----------------------------------------------------------------------------
   SAMPLE EXPECTED INPUT / OUTPUT  (full seed dataset)
     COUNT(*)  (machine)          -> 8
     AVG_ACTIVE_PRICE (Available) -> 8899.16667   -- (50+75+50000+120+650+2500)/6
     HIGHEST_PRICE                -> 50000
     COUNT(*)  (lending_request)  -> 8
     TOTAL_AMOUNT (payment)       -> 53975
     TOTAL_COST (price*5, Hour)   -> 250 / 375 / 600        (3 rows)
     Requests per user            -> 7 users x 1, Vikram Singh 0, Anjali Rao 0
     Requests per machine         -> Circular Saw 2, Excavator 0,
                                    Hydraulic Press 0, all others 1  (8 rows)

     Note: the original lab printout was captured mid-build (7 machines /
     7 requests / 7 payments), so counts such as 7 and 52975 appear there;
     values above assume the complete seed in 01-schema/03_seed_data.sql.
   ============================================================================ */

/* 1 -- Fleet size ---------------------------------------------------------- */
SELECT COUNT(*) AS total_machines
FROM   machine;

/* 2 -- Average daily rate across the *available* fleet --------------------- */
SELECT AVG(price) AS avg_active_price
FROM   machine
WHERE  status_available = 'Available';

/* 3 -- Flagship price ------------------------------------------------------ */
SELECT MAX(price) AS highest_price
FROM   machine;

/* 4 -- Request pipeline volume --------------------------------------------- */
SELECT COUNT(*) AS total_requests
FROM   lending_request;

/* 5 -- Gross settled + outstanding amount ---------------------------------- */
SELECT SUM(payment_amount) AS total_amount
FROM   payment;

/* 6 -- What does a 5-unit rental cost on every hour-priced machine? -------- */
SELECT name, price, price * 5 AS total_cost
FROM   machine
WHERE  price_type = 'Hour';

/* 7 -- Demand per borrower (0 counts must survive -> LEFT JOIN) ------------- */
SELECT u.name, COUNT(lr.request_id) AS total_requests
FROM   users u
       LEFT JOIN lending_request lr
              ON u.user_id = lr.borrower_id
GROUP  BY u.name
ORDER  BY total_requests DESC, u.name;

/* 8 -- Demand per machine (idle fleet detection) ---------------------------- */
SELECT m.name, COUNT(lr.request_id) AS total_requests
FROM   machine m
       LEFT JOIN lending_request lr
              ON m.machine_id = lr.machine_id
GROUP  BY m.name
ORDER  BY total_requests DESC, m.name;
