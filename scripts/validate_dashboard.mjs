import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";

const root = process.cwd();
const requiredFiles = [
  "index.html",
  "dashboard/index.html",
  "dashboard/dashboard.css",
  "dashboard/dashboard-data.js",
  "README.md",
  "PROJECT_PROGRESS_CN.md",
  "PROJECT_IDENTITY.md",
];

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function readText(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), "utf8");
}

function parseCsv(relativePath) {
  const text = readText(relativePath).replace(/^\uFEFF/, "").trim();
  const [headerLine, ...rows] = text.split(/\r?\n/);
  const headers = parseCsvLine(headerLine);
  return rows.map((line) => {
    const values = parseCsvLine(line);
    return Object.fromEntries(headers.map((header, index) => [header, values[index]]));
  });
}

function parseCsvLine(line) {
  const values = [];
  let value = "";
  let inQuotes = false;

  for (let index = 0; index < line.length; index += 1) {
    const char = line[index];
    const next = line[index + 1];

    if (char === '"' && inQuotes && next === '"') {
      value += '"';
      index += 1;
    } else if (char === '"') {
      inQuotes = !inQuotes;
    } else if (char === "," && !inQuotes) {
      values.push(value);
      value = "";
    } else {
      value += char;
    }
  }

  values.push(value);
  return values;
}

for (const file of requiredFiles) {
  assert(fs.existsSync(path.join(root, file)), `${file} is missing`);
}

const context = {};
vm.createContext(context);
vm.runInContext(readText("dashboard/dashboard-data.js"), context);

const data = context.dashboardData;
assert(data, "dashboardData global is missing");

const summary = JSON.parse(readText("analysis/summary_metrics.json").replace(/^\uFEFF/, ""));
assert(data.kpis.totalSales === summary.TotalSales, "Total Sales does not match summary metrics");
assert(data.kpis.totalProfit === summary.TotalProfit, "Total Profit does not match summary metrics");
assert(data.kpis.totalOrders === summary.Orders, "Total Orders does not match summary metrics");
assert(data.kpis.negativeProfitRows === summary.NegativeProfitRows, "Negative Profit Rows does not match summary metrics");

const monthly = parseCsv("analysis/monthly_sales_profit.csv");
assert(data.monthly.length === monthly.length, "Monthly trend length does not match CSV");
assert(data.monthly[0].yearMonth === monthly[0].YearMonth, "Monthly trend first month does not match CSV");

const riskRows = parseCsv("analysis/high_sales_low_profit_subcategories.csv");
assert(data.marginRisks.length === riskRows.length, "Margin risk row count does not match CSV");
assert(data.marginRisks[0].subCategory === "Tables", "Tables should be the top margin risk item");
assert(data.marginRisks[0].profitMargin < 0, "Tables should have a negative margin");

const html = readText("dashboard/index.html");
assert(html.includes("dashboard-data.js"), "HTML should load dashboard data");
assert(html.includes("High-Sales Low-Profit Review"), "HTML should include margin risk table section");

const rootHtml = readText("index.html");
assert(rootHtml.includes("dashboard/index.html"), "Root index should point to the dashboard page");
assert(rootHtml.includes("Sales Performance Analytics Dashboard"), "Root index should name the dashboard project");

const readme = readText("README.md");
assert(readme.includes("HTML/CSS/JavaScript"), "README should position the browser dashboard as a project tool");
assert(!readme.includes("Power BI-ready cleaned dataset, DAX measures, and build guide"), "README still uses old Power BI-ready positioning");
assert(!readme.includes("Built a Power BI dashboard"), "README should not claim a Power BI dashboard was built");
assert(readme.includes("Project Identity"), "README should document the first-version project identity");
assert(readme.includes("sales-performance-dashboard"), "README should point to the first-version GitHub repository");
assert(readme.includes("sales-data-auto-dashboard"), "README should distinguish the later CSV auto-analysis project");

const progressLog = readText("PROJECT_PROGRESS_CN.md");
assert(progressLog.includes("项目身份边界"), "Progress log should document project identity boundaries");
assert(progressLog.includes("8766"), "Progress log should reserve port 8766 for this first-version project");

const projectIdentity = readText("PROJECT_IDENTITY.md");
assert(projectIdentity.includes("Sales Performance Analytics Dashboard"), "Project identity should name the sales dashboard");
assert(projectIdentity.includes("https://github.com/KingTang6/sales-performance-dashboard"), "Project identity should point to the sales GitHub repo");
assert(projectIdentity.includes("https://sales-performance-dashboard-mauve.vercel.app/"), "Project identity should point to the sales Vercel demo");

console.log("Dashboard validation passed.");
