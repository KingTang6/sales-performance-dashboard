-- Business question:
-- What are the company's core sales, profit, and margin KPIs?

.headers on
.mode column

SELECT
    COUNT(*) AS transaction_rows,
    COUNT(DISTINCT OrderID) AS total_orders,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0), 4) AS profit_margin,
    SUM(Quantity) AS total_quantity,
    ROUND(AVG(Discount), 4) AS average_discount,
    SUM(CASE WHEN Profit < 0 THEN 1 ELSE 0 END) AS negative_profit_rows
FROM superstore_cleaned;
