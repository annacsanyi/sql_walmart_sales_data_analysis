-- Examine basic structure of the dataset
SELECT *
FROM walmart_sales.sales_data
LIMIT 10;

-- Q1: Which year had the highest total sales?
SELECT
  EXTRACT (YEAR FROM Date) AS year,
  ROUND(SUM(weekly_sales), 0) AS total_sales,
  FORMAT("%'d", CAST(SUM(weekly_sales) AS INT64)) AS total_sales_formatted
FROM walmart_sales.sales_data
GROUP BY year;

-- Q2: Do sales always rise near the holiday season every year?
SELECT
  EXTRACT (YEAR FROM Date) AS year,
  CASE WHEN holiday_flag = 1 THEN 'Holiday week' ELSE 'Non-holiday week' END AS period_type,
  ROUND(AVG(weekly_sales), 0) AS average_sales,
  FORMAT("%'d", CAST(AVG(weekly_sales) AS INT64)) AS average_sales_formatted 
FROM walmart_sales.sales_data
GROUP BY holiday_flag, year;

-- Q3: Which stores generated the most revenue overall?
SELECT
  store,
  ROUND(SUM(weekly_sales), 0) AS total_sales,
  FORMAT("%'d", CAST(SUM(weekly_sales) AS INT64)) AS total_sales_formatted
FROM walmart_sales.sales_data
GROUP BY store
ORDER BY total_sales DESC
LIMIT 10;

-- Q4: Do extreme weather conditions affect sales?
SELECT
  CASE WHEN temperature < 40 THEN 'Cold (<4°C)'
       WHEN temperature > 85 THEN 'Hot (>29°C)'
       ELSE 'Moderate (4-29°C)'
  END AS temp_category,
  ROUND(AVG(weekly_sales), 0) AS average_sales,
  FORMAT("%'d", CAST(AVG(weekly_sales) AS INT64)) AS average_sales_formatted
FROM walmart_sales.sales_data
GROUP BY temp_category
ORDER BY average_sales;

-- Q5: How do sales vary with macroeconomic indicators such as CPI or Unemployment?
WITH macro_avgs AS (
  SELECT
    AVG(unemployment) AS avg_unemp,
    AVG(cpi) AS avg_inflation
  FROM walmart_sales.sales_data
)

SELECT
  ROUND(AVG(weekly_sales), 0) AS average_sales,
  FORMAT("%'d", CAST(AVG(weekly_sales) AS INT64)) AS average_sales_formatted,
  CASE WHEN s.unemployment > m.avg_unemp THEN 'High unemployment' ELSE 'Normal unemployment' END AS unemployment_status,
  CASE WHEN s.cpi > m.avg_inflation THEN 'High inflation' ELSE 'Normal inflation' END AS inflation_status
FROM walmart_sales.sales_data s
CROSS JOIN macro_avgs m
GROUP BY unemployment_status, inflation_status
ORDER BY average_sales;

-- Q6: Which stores show the most consistent sales performance?
SELECT
  store,
  ROUND(STDDEV(weekly_sales), 0) AS sales_std
FROM walmart_sales.sales_data
GROUP BY store
ORDER BY sales_std ASC;

-- Q7: Which weeks have unusually high or low sales compared to the store’s average?
SELECT
  s.store,
  s.date,
  average_sales,
  ROUND(weekly_sales) AS weekly_sales,
  ROUND(weekly_sales - average_sales) AS difference
FROM walmart_sales.sales_data s
INNER JOIN (
  SELECT
    store,
    ROUND(AVG(weekly_sales)) AS average_sales
  FROM walmart_sales.sales_data
  GROUP BY store) AS t
  ON s.store = t.store
WHERE weekly_sales > average_sales * 1.2
   OR weekly_sales < average_sales * 0.8
ORDER BY s.store, s.date;

-- Q8: Is there a relationship between fuel price and sales?
SELECT ROUND(CORR(fuel_price, weekly_sales), 4) AS correlation
FROM walmart_sales.sales_data;

-- Q9: What are the peak sales months across all stores?
SELECT
  EXTRACT (MONTH FROM date) AS month,
  ROUND(SUM(weekly_sales)) total_sales,
  FORMAT("%'d", CAST(SUM(weekly_sales) AS INT64)) AS total_sales_formatted
FROM walmart_sales.sales_data
GROUP BY month
ORDER BY total_sales DESC;

-- Q10: Which store contributes the most to total revenue as a percentage?
SELECT
  store,
  ROUND(SUM(weekly_sales)) AS total_sales,
  ROUND(SUM(weekly_sales) / SUM(SUM(weekly_sales)) OVER() * 100, 1) AS pct_of_total
FROM walmart_sales.sales_data
GROUP BY store
ORDER BY pct_of_total DESC
LIMIT 10;
