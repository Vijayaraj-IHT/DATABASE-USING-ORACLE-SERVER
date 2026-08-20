/* ============================================================================
   FILE      : 02-queries/05_subqueries.sql
   MODULE    : Subqueries - scalar, IN/NOT IN, ALL and ANY quantifiers
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     Push decision logic INTO the query: compare attributes not to constants
     but to values the database itself computes. Concepts demonstrated:
       * Scalar subqueries returning a comparable single value (AVG/MAX/MIN/SUM).
       * IN / NOT IN set-membership subqueries.
       * Quantified comparison: > ALL (greater than every row) and
         > ANY / < ANY / = ANY (at least one row suffices).
       * Empty-inner-set semantics: > ALL over an empty set is TRUE for every
         row, while > ANY over an empty set is FALSE -- shown intentionally.

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN / SAMPLE EXPECTED OUTPUT (full seed dataset)
     Q1  price > avg(all prices = 8274.38)  : Tower Crane 50000, Excavator 12000
     Q2  payment < avg payment (6746.88)    : txns 1,2,4,5,6,7,8     (7 rows)
     Q3  payment = max payment              : txn 3, 50000           (1 row)
     Q4  price <= min price                 : Electric Drill 50      (1 row)
     Q5  price = max price                  : Tower Crane 50000      (1 row)
     Q6  price <> avg price                 : all 8 machines
     Q7  users IN (borrowers)               : 7 names
     Q8  users NOT IN (borrowers)           : Vikram Singh, Anjali Rao (2 rows)
     Q9  price > ALL (owner 5 prices = {} ) : ALL machines qualify (8 rows)
     Q10 price < ALL (owner 5 prices = {} ) : 0 rows -- empty-set duality!
     Q11 payment > txn-3 total (50000)      : 0 rows
     Q12 payment < txn-3 total              : 7 rows
     Q13 price = ANY (owner 2: 75,120)      : Circular Saw, Welding Machine
     Q14 price < ANY (owner 2: 75,120)      : Electric Drill 50, Circular Saw 75
     Q15 price > ANY (owner 2: 75,120)      : Mixer 800, Crane 50000, Welding 120,
                                              Hammer 650, Excavator 12000,
                                              Hydraulic Press 2500   (6 rows)

     (The raw lab log shows slightly different row counts; its snapshots were
     captured before the seed dataset reached its final size.)
   ============================================================================ */

/* Q1 -- Premium fleet: above the catalog-wide average price ----------------- */
SELECT name, price
FROM   machine
WHERE  price > (SELECT AVG(price) FROM machine);

/* Q2 -- Small settlements: below-average payments --------------------------- */
SELECT transaction_id, payment_amount
FROM   payment
WHERE  payment_amount < (SELECT AVG(payment_amount) FROM payment);

/* Q3 -- The whale: the largest single settlement ---------------------------- */
SELECT transaction_id, payment_amount
FROM   payment
WHERE  payment_amount >= (SELECT MAX(payment_amount) FROM payment);

/* Q4 -- Budget champion(s) --------------------------------------------------- */
SELECT name, price
FROM   machine
WHERE  price <= (SELECT MIN(price) FROM machine);

/* Q5 -- Flagship machine ------------------------------------------------------ */
SELECT name, price
FROM   machine
WHERE  price = (SELECT MAX(price) FROM machine);

/* Q6 -- Everything that is NOT exactly average-priced ------------------------- */
SELECT name, price
FROM   machine
WHERE  price != (SELECT AVG(price) FROM machine);

/* Q7 -- Users who have placed at least one request ----------------------------- */
SELECT name
FROM   users
WHERE  user_id IN (SELECT borrower_id FROM lending_request);

/* Q8 -- Users who have NEVER requested (onboarding targets) ---------------------- */
SELECT name
FROM   users
WHERE  user_id NOT IN (SELECT borrower_id FROM lending_request);

/* Q9 -- Pricier than every machine of owner 5. Owner 5 owns NOTHING, so the
        inner set is empty and > ALL is vacuously TRUE for all rows.       */
SELECT name, price
FROM   machine
WHERE  price > ALL (SELECT price FROM machine WHERE owner_id = 5);

/* Q10 -- The dual: cheaper than every machine of owner 5 -> 0 rows ---------- */
SELECT name, price
FROM   machine
WHERE  price < ALL (SELECT price FROM machine WHERE owner_id = 5);

/* Q11 -- Any settlement bigger than transaction 3's total? ------------------- */
SELECT transaction_id, payment_amount
FROM   payment
WHERE  payment_amount > (SELECT SUM(payment_amount)
                         FROM   payment
                         WHERE  transaction_id = 3);

/* Q12 -- Settlements smaller than transaction 3's total ---------------------- */
SELECT transaction_id, payment_amount
FROM   payment
WHERE  payment_amount < (SELECT SUM(payment_amount)
                         FROM   payment
                         WHERE  transaction_id = 3);

/* Q13 -- Price-twins with anything owner 2 sells (= ANY is IN's cousin) ----- */
SELECT name, price
FROM   machine
WHERE  price = ANY (SELECT price FROM machine WHERE owner_id = 2);

/* Q14 -- Strictly below owner 2's most expensive unit ------------------------ */
SELECT name, price
FROM   machine
WHERE  price < ANY (SELECT price FROM machine WHERE owner_id = 2);

/* Q15 -- Anything pricier than owner 2's cheapest unit ------------------------*/
SELECT name, price
FROM   machine
WHERE  price > ANY (SELECT price FROM machine WHERE owner_id = 2);
