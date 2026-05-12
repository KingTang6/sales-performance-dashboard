-- Business question:
-- Which sub-categories sell well but have weak or negative margins?

.headers on
.mode column

SELECT
    SubCategory,
    Category,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    SUM(Quantity) AS total_quantity,
    ROUND(AVG(Discount), 4) AS average_discount,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0), 4) AS profit_margin
FROM superstore_cleaned
GROUP BY SubCategory, Category
HAVING SUM(Sales) >= 100000
   AND (SUM(Profit) / NULLIF(SUM(Sales), 0)) < 0.05
ORDER BY profit_margin ASC, total_sales DESC;
