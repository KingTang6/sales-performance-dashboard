-- Business question:
-- Which product categories and sub-categories are most profitable?

.headers on
.mode column

SELECT
    Category,
    SubCategory,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    SUM(Quantity) AS total_quantity,
    ROUND(AVG(Discount), 4) AS average_discount,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0), 4) AS profit_margin
FROM superstore_cleaned
GROUP BY Category, SubCategory
ORDER BY total_profit DESC;
