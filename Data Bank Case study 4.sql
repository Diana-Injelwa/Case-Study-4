-- CASE STUDY QUESTIONS
-- PART A. Customer Nodes Exploration
/* 1. How many unique nodes are there on 
the Data Bank system? */
SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;

/* 2. What is the number of nodes per region? */
SELECT region_name, COUNT(DISTINCT node_id) AS number_of_nodes
FROM regions r
JOIN customer_nodes cn
ON r.region_id = cn.region_id
GROUP BY region_name;

/* 3. How many customers are allocated to each region? */
SELECT region_name, COUNT(*) AS number_of_customers
FROM regions r
JOIN customer_nodes cn
ON r.region_id = cn.region_id
GROUP BY region_name;

/* 4. How many days on average are customers reallocated to a
 different node? */
SELECT ROUND(AVG(days), 0) AS avg_days_for_reallocation
FROM(
    SELECT
        customer_id,
        DATEDIFF(end_date, start_date) AS days
    FROM customer_nodes
) subquery;

/* 5. What is the median, 80th and 95th percentile for this same 
reallocation days metric for each region? */
WITH reallocation AS(
    SELECT
        region_name,
        customer_id,
        DATEDIFF(end_date, start_date) AS days
    FROM customer_nodes cn
    JOIN regions r ON cn.region_id = r.region_id
    ORDER BY region_name, days
),
ordered AS(
    SELECT
        region_name,
        days,
        ROW_NUMBER() OVER(PARTITION BY region_name ORDER BY days) rn
    FROM reallocation
),
max_rownumber AS(
    SELECT
        region_name,
        MAX(rn) AS max_rn
    FROM ordered
    GROUP BY region_name
)
SELECT
    o.region_name,
    o.days,
    CASE
        WHEN rn = ROUND(max_rn * 0.5,0) THEN 'Median'
        WHEN rn = ROUND(max_rn * 0.8,0) THEN '80th percentile'
        WHEN rn = ROUND(max_rn * 0.95,0) THEN '95th percentile'
    END AS metric
FROM ordered o
JOIN max_rownumber m ON m.region_name = o.region_name
WHERE rn IN(
    ROUND(max_rn / 2,0),
    ROUND(max_rn * 0.8,0),
    ROUND(max_rn * 0.95,0)   
);

-- PART B. CUSTOMER TRANSACTIONS
/* 1. What is the unique count and total amount 
for each transaction type? */
SELECT 
    txn_type,
    COUNT(*) AS count,
    SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type;

/* 2. What is the average total historical deposit 
counts and amounts for all customers? */
WITH deposits AS(
    SELECT 
        customer_id,
        COUNT(*) AS deposit_counts,
        SUM(txn_amount) AS total_amount
    FROM customer_transactions
    WHERE txn_type = 'deposit'
    GROUP BY customer_id
)
SELECT
    ROUND(AVG(deposit_counts), 2) AS avg_count,
    ROUND(AVG(total_amount), 2) AS avg_amount
FROM deposits;

/* 3, For each month - how many Data Bank customers make more 
than 1 deposit and either 1 purchase or 1 withdrawal in a 
single month? */
SELECT * FROM customer_transactions;
WITH customers AS(
    SELECT
        MONTHNAME(txn_date) AS month,
        SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit,
        SUM(CASE WHEN txn_type <> 'deposit' THEN 1 ELSE 0 END) AS purchase_or_withdrawal,
        customer_id,
        txn_type
    FROM customer_transactions
    GROUP BY MONTHNAME(txn_date), customer_id
    HAVING SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) > 1
    AND SUM(CASE WHEN txn_type <> 'deposit' THEN 1 ELSE 0 END) = 1
)
SELECT
    month,
    COUNT(customer_id) AS customer_count
FROM customers
GROUP BY month;


    



  