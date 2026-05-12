-- Business purpose:
-- Create a SQLite table that matches data/superstore_cleaned.csv.
-- The table supports KPI, trend, region, product, and customer segment analysis.

DROP TABLE IF EXISTS superstore_cleaned;

CREATE TABLE superstore_cleaned (
    RowID INTEGER,
    OrderID INTEGER,
    OrderDate TEXT,
    ShipDate TEXT,
    Year INTEGER,
    Month INTEGER,
    YearMonth TEXT,
    Region TEXT,
    Province TEXT,
    CustomerSegment TEXT,
    Category TEXT,
    SubCategory TEXT,
    ProductName TEXT,
    Sales REAL,
    Profit REAL,
    Quantity INTEGER,
    Discount REAL,
    UnitPrice REAL,
    ShippingCost REAL,
    ProfitMargin REAL
);
