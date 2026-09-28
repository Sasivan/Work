SELECT m.name
FROM Employee e
JOIN Employee m ON e.managerId = m.id
GROUP BY m.id, m.name
HAVING COUNT(e.id) >= 5;

CREATE FUNCTION getNthHighestSalary(N INT) RETURNS INT
BEGIN
  SET N = N - 1;
  RETURN (
      SELECT DISTINCT salary
      FROM Employee
      ORDER BY salary DESC
      LIMIT 1 OFFSET N
  );
END

WITH AllFriends AS (
    SELECT requester_id AS id FROM RequestAccepted
    UNION ALL
    SELECT accepter_id AS id FROM RequestAccepted
)
SELECT id, COUNT(*) AS num
FROM AllFriends
GROUP BY id
ORDER BY num DESC
LIMIT 1;

SELECT
    CASE
        WHEN id % 2 != 0 AND id = (SELECT MAX(id) FROM Seat) THEN id
        WHEN id % 2 != 0 THEN id + 1
        ELSE id - 1
    END AS id,
    student
FROM Seat
ORDER BY id;

SELECT customer_id
FROM Customer
GROUP BY customer_id
HAVING COUNT(DISTINCT product_key) = (SELECT COUNT(*) FROM Product);

SELECT u.user_id AS buyer_id, u.join_date, COUNT(o.order_id) AS orders_in_2019
FROM Users u
LEFT JOIN Orders o ON u.user_id = o.buyer_id AND YEAR(o.order_date) = 2019
GROUP BY u.user_id, u.join_date;

WITH FirstLogins AS (
    SELECT 
        user_id,
        MIN(activity_date) AS first_login
    FROM Traffic
    WHERE activity = 'login'
    GROUP BY user_id
)
SELECT 
    first_login AS login_date,
    COUNT(user_id) AS user_count
FROM FirstLogins
WHERE first_login >= DATE '2019-06-30' - INTERVAL '90 days'
GROUP BY first_login
ORDER BY first_login;

SELECT 
    product_id, 
    new_price AS price
FROM Products
WHERE (product_id, change_date) IN (
    SELECT 
        product_id, 
        MAX(change_date)
    FROM Products
    WHERE change_date <= '2019-08-16'
    GROUP BY product_id
)

UNION

SELECT DISTINCT 
    product_id, 
    10 AS price
FROM Products
WHERE product_id NOT IN (
    SELECT product_id 
    FROM Products 
    WHERE change_date <= '2019-08-16'
);

WITH Approved AS (
    SELECT 
        TO_CHAR(trans_date, 'YYYY-MM') AS month,
        country,
        COUNT(*) AS approved_count,
        SUM(amount) AS approved_amount
    FROM Transactions
    WHERE state = 'approved'
    GROUP BY 
        TO_CHAR(trans_date, 'YYYY-MM'),
        country
),
Chargeback AS (
    SELECT 
        TO_CHAR(c.trans_date, 'YYYY-MM') AS month,
        t.country,
        COUNT(*) AS chargeback_count,
        SUM(t.amount) AS chargeback_amount
    FROM Chargebacks c
    JOIN Transactions t 
        ON c.trans_id = t.id
    GROUP BY 
        TO_CHAR(c.trans_date, 'YYYY-MM'),
        t.country
)
SELECT 
    month,
    country,
    COALESCE(approved_count, 0) AS approved_count,
    COALESCE(approved_amount, 0) AS approved_amount,
    COALESCE(chargeback_count, 0) AS chargeback_count,
    COALESCE(chargeback_amount, 0) AS chargeback_amount
FROM Approved
LEFT JOIN Chargeback 
    USING (month, country)

UNION

SELECT 
    month,
    country,
    COALESCE(approved_count, 0) AS approved_count,
    COALESCE(approved_amount, 0) AS approved_amount,
    COALESCE(chargeback_count, 0) AS chargeback_count,
    COALESCE(chargeback_amount, 0) AS chargeback_amount
FROM Chargeback
LEFT JOIN Approved 
    USING (month, country);

WITH Points AS (
    SELECT host_team AS team,
           CASE WHEN host_goals > guest_goals THEN 3 WHEN host_goals = guest_goals THEN 1 ELSE 0 END AS pts
    FROM Matches
    UNION ALL
    SELECT guest_team AS team,
           CASE WHEN guest_goals > host_goals THEN 3 WHEN guest_goals = host_goals THEN 1 ELSE 0 END AS pts
    FROM Matches
)
SELECT t.team_id, t.team_name, COALESCE(SUM(p.pts), 0) AS num_points
FROM Teams t
LEFT JOIN Points p ON t.team_id = p.team
GROUP BY t.team_id, t.team_name
ORDER BY num_points DESC, t.team_id ASC;