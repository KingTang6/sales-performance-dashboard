-- Business question:
-- How do sales and profit trend over time by month?

.headers on
.mode column

SELECT
    YearMonth,
    ROUND(SUM(Sales), 2) AS monthly_sales,
    ROUND(SUM(Profit), 2) AS monthly_profit,
    COUNT(DISTINCT OrderID) AS monthly_orders,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0), 4) AS monthly_profit_margin
FROM superstore_cleaned
GROUP BY YearMonth
ORDER BY YearMonth;
