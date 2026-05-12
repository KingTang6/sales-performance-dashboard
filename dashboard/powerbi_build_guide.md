# Power BI Build Guide

## Data Import

1. Open Power BI Desktop.
2. Import `data/superstore_cleaned.csv`.
3. Set these data types:
   - `OrderDate`, `ShipDate`: Date
   - `Year`, `Month`, `OrderID`, `Quantity`: Whole number
   - `Sales`, `Profit`, `Discount`, `UnitPrice`, `ShippingCost`, `ProfitMargin`: Decimal number
4. Add the DAX measures from `dashboard/powerbi_measures.dax`.

## One-Page Dashboard Layout

Use a 16:9 report canvas.

Top KPI row:

- Total Sales
- Total Profit
- Profit Margin
- Total Orders
- Average Discount

Main analysis area:

- Line chart: `YearMonth` by `Total Sales`
- Bar chart: `Region` by `Total Sales`
- Bar chart: `Category` by `Total Profit`
- Bar chart: `CustomerSegment` by `Total Sales`
- Table or bar chart: `SubCategory`, `Total Sales`, `Total Profit`, `Profit Margin`, filtered to high-sales, low-profit items

Recommended slicers:

- Year
- Region
- Category
- Customer Segment

## Design Notes

- Use sales and profit together so the report does not overstate revenue growth.
- Highlight negative or low-margin sub-categories in red or amber.
- Keep the dashboard to one page for the portfolio version, then expand into product/customer detail pages later if needed.
