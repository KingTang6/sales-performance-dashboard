# SQLite Analysis Layer

This folder adds a SQL analysis layer to the Sales Performance Analytics Dashboard project. The queries reproduce the same business questions behind the dashboard using the cleaned dataset in `data/superstore_cleaned.csv`.

## Files

| File | Purpose |
| --- | --- |
| `01_create_tables.sql` | Creates the `superstore_cleaned` table for the cleaned CSV data. |
| `02_sales_kpis.sql` | Calculates total sales, total profit, profit margin, order count, quantity, average discount, and negative-profit rows. |
| `03_monthly_trends.sql` | Summarizes monthly sales, profit, orders, and margin. |
| `04_region_analysis.sql` | Compares sales, profit, and margin by region. |
| `05_product_profitability.sql` | Reviews profitability by product category and sub-category. |
| `06_customer_segment_analysis.sql` | Compares sales, profit, and margin by customer segment. |
| `07_high_sales_low_profit.sql` | Identifies high-sales, low-margin sub-categories such as Tables and Bookcases. |

## How to Run with SQLite

Install SQLite and run these commands from the project root:

```powershell
sqlite3 superstore_analysis.db ".read sql/01_create_tables.sql"
sqlite3 superstore_analysis.db ".mode csv" ".import --skip 1 data/superstore_cleaned.csv superstore_cleaned"
sqlite3 superstore_analysis.db ".read sql/02_sales_kpis.sql"
sqlite3 superstore_analysis.db ".read sql/03_monthly_trends.sql"
sqlite3 superstore_analysis.db ".read sql/04_region_analysis.sql"
sqlite3 superstore_analysis.db ".read sql/05_product_profitability.sql"
sqlite3 superstore_analysis.db ".read sql/06_customer_segment_analysis.sql"
sqlite3 superstore_analysis.db ".read sql/07_high_sales_low_profit.sql"
```

Alternatively, if `sqlite3` is available in your PATH, run:

```powershell
powershell -ExecutionPolicy Bypass -File sql\run_sqlite_analysis.ps1
```

The SQL layer is included for portfolio readability and reproducibility. It is not a database-backed application.
