CREATE DATABASE credit_sesame;
USE credit_sesame;
SELECT * FROM test;

#1. What is the level (primary key) of the dataset. Bring it to 'customer*year*month' level
# customer*year*month*spend

#2. Show the first, second and last transaction for every customer
# Assumption: Transaction ID is ordered by time when transaction happened
SELECT customer, 
       transaction_id, 
	   month, 
       year, 
       spend,
       (CASE WHEN row_num = 1 THEN 'first'
			 WHEN row_num = 2 THEN 'second'
             ELSE 'last' END) AS `order`
FROM
(SELECT customer, 
        transaction_id, 
	    month, 
        year, 
        spend,
        ROW_NUMBER() OVER (PARTITION BY customer ORDER BY transaction_id) row_num
FROM test) tmp1
WHERE row_num = 1 OR row_num = 2
OR (customer, transaction_id) IN 
(SELECT customer, MAX(transaction_id)
FROM test
GROUP BY customer);


#3. Show the first, second and last transaction for every customer for every year
SELECT customer, 
       transaction_id, 
       month, 
       year, 
       spend,
       (CASE WHEN row_num = 1 THEN 'first'
			 WHEN row_num = 2 THEN 'second'
             ELSE 'last' END) AS `order`
FROM
(SELECT customer, 
        transaction_id, 
	    month, 
        year, 
		spend,
        ROW_NUMBER() OVER (PARTITION BY customer, year ORDER BY transaction_id) row_num
FROM test) tmp1
WHERE row_num = 1 OR row_num = 2
OR (customer, transaction_id) IN 
(SELECT customer, MAX(transaction_id)
FROM test
GROUP BY customer, year);

#4. What months do customers make their first transaction. How many make 1st transaction in Jan., how many in Feb. etc.
SELECT tmp3.month, 
       IFNULL(tmp2.num,0)
FROM
(SELECT month, 
        COUNT(*) AS num
FROM 
(SELECT customer, 
        transaction_id, 
	    month, 
        year, 
        spend,
        ROW_NUMBER() OVER (PARTITION BY customer ORDER BY transaction_id) row_num
FROM test) tmp1
WHERE row_num = 1
GROUP BY month
ORDER BY month) tmp2
RIGHT JOIN
(SELECT DISTINCT month 
 FROM test
 ORDER BY month) tmp3
ON tmp2.month = tmp3.month
ORDER BY tmp3.month;

#5. What is average time between first and second transaction month for a customer
SELECT AVG(PERIOD_DIFF(DATE_FORMAT(tmp6.date, '%Y%m'), DATE_FORMAT(tmp3.date, '%Y%m'))) AS avg_diff
FROM
(SELECT customer, transaction_id, date, spend AS first
FROM
(SELECT customer, transaction_id, date, spend,
        ROW_NUMBER() OVER (PARTITION BY customer ORDER BY transaction_id) row_num
FROM
(SELECT customer, 
		STR_TO_DATE(CONCAT(year,'-', month), '%Y-%m') AS date, 
		spend, 
        transaction_id
FROM test) tmp1
)tmp2
WHERE row_num = 1
)tmp3
JOIN 
(SELECT customer, transaction_id, date, spend AS second
FROM
(SELECT customer, transaction_id, date, spend,
        ROW_NUMBER() OVER (PARTITION BY customer ORDER BY transaction_id) row_num
FROM
(SELECT customer, 
		STR_TO_DATE(CONCAT(year,'-', month), '%Y-%m') AS date, 
		spend, 
        transaction_id
FROM test) tmp4
)tmp5
WHERE row_num = 2
)tmp6
ON tmp3.customer = tmp6.customer;

#6. What % of customers have YoY increase in spend
SELECT CONCAT(COUNT(CASE WHEN (IFNULL(tmp2.year_spend,0)-IFNULL(tmp1.year_spend,0))>0 THEN 1 ELSE 0 END)/COUNT(*)*100,'%') AS percentage
FROM
(SELECT customer, year, SUM(spend) AS year_spend
FROM test
GROUP BY customer, year) tmp1
CROSS JOIN 
(SELECT customer, year, SUM(spend) AS year_spend
FROM test
GROUP BY customer, year) tmp2
ON tmp1.customer = tmp2.customer
AND tmp1.year+1 = tmp2.year
;