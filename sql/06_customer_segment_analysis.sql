-- Business question:
-- Which customer segments contribute the most sales and profit?

.headers on
.mode column

SELECT
    CustomerSegment,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    COUNT(DISTINCT OrderID) AS total_orders,
    SUM(Quantity) AS total_quantity,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0), 4) AS profit_margin
FROM superstore_cleaned
GROUP BY CustomerSegment
ORDER BY total_sales DESC;
