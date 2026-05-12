# 项目进度记录：Sales Performance Analytics Dashboard

这个文件用于记录当前项目已经完成了什么、为什么这样做、以及下一步应该继续做什么。以后重新打开这个项目时，可以先读这个文件快速恢复上下文。

## 项目目标

这个项目是一个面向 entry-level Data Analyst 简历和 GitHub portfolio 的销售分析项目。目标是使用 Superstore 风格的公开销售数据，完成一个真实、稳妥、不夸大的分析案例。

最终希望项目能展示这些能力：

- 数据清洗
- KPI 设计
- SQL 分析
- 分组聚合分析
- Dashboard 设计
- 业务洞察总结
- GitHub 项目文档整理

## 当前项目位置

项目文件夹：

```text
C:\Users\admin\Desktop\销售数据分析仪表盘
```

当前 Mac 工作路径：

```text
/Users/kingtang01/Desktop/销售数据分析仪表盘
```

Power BI 导入用的英文路径副本：

```text
C:\Users\admin\Desktop\powerbi_import\superstore_cleaned.csv
```

## 数据来源

使用的是公开 Superstore-style 销售数据：

```text
https://raw.githubusercontent.com/curran/data/gh-pages/superstoreSales/superstoreSales.csv
```

项目里保存了两个数据文件：

- `data/superstore_raw.csv`：原始数据
- `data/superstore_cleaned.csv`：清洗后的数据

清洗后数据规模：

- 8,399 行交易记录
- 5,496 个唯一订单
- 20 个字段

主要字段包括：

- `OrderDate`
- `ShipDate`
- `Region`
- `CustomerSegment`
- `Category`
- `SubCategory`
- `Sales`
- `Profit`
- `Quantity`
- `Discount`
- `UnitPrice`
- `ShippingCost`
- `ProfitMargin`

## 已完成的项目结构

当前主要文件结构：

```text
.
|-- analysis/
|   |-- analysis_notes.md
|   |-- category_profitability.csv
|   |-- high_sales_low_profit_subcategories.csv
|   |-- monthly_sales_profit.csv
|   |-- region_performance.csv
|   |-- segment_contribution.csv
|   |-- subcategory_performance.csv
|   `-- summary_metrics.json
|-- assets/
|   `-- sales_performance_dashboard.png
|-- dashboard/
|   |-- powerbi_build_guide.md
|   `-- powerbi_measures.dax
|-- data/
|   |-- superstore_cleaned.csv
|   `-- superstore_raw.csv
|-- sql/
|   |-- 01_create_tables.sql
|   |-- 02_sales_kpis.sql
|   |-- 03_monthly_trends.sql
|   |-- 04_region_analysis.sql
|   |-- 05_product_profitability.sql
|   |-- 06_customer_segment_analysis.sql
|   |-- 07_high_sales_low_profit.sql
|   |-- README.md
|   `-- run_sqlite_analysis.ps1
|-- scripts/
|   `-- build_dashboard.ps1
|-- data_dictionary.md
|-- README.md
|-- PROJECT_PROGRESS_CN.md
`-- .gitignore
```

## 已完成的功能和文件

### 0. Mac 浏览器版 Dashboard

用户已更换为 Mac 环境，当前不再把 Power BI Desktop 作为必需工具。项目主线已经调整为 Mac 可直接打开的静态浏览器 dashboard。

新增文件：

```text
index.html
dashboard/index.html
dashboard/dashboard.css
dashboard/dashboard-data.js
```

特点：

- 不依赖 Power BI Desktop
- 不依赖 npm、React、Next.js、Plotly 或 Python server
- 可以直接在浏览器打开 `dashboard/index.html`
- 根目录 `index.html` 会自动跳转到 `dashboard/index.html`，方便 Vercel 部署后使用根路径访问
- 也可以用 `python3 -m http.server 8765 --bind 127.0.0.1` 后访问 `http://127.0.0.1:8765/` 做本地预览
- 使用 `analysis/` 中已有 summary 数据固化成前端常量
- 展示 KPI、月度趋势、地区销售、品类利润、客户类型贡献和高销售低利润子类别
- 已通过 Codex 浏览器插件用 localhost 预览验证：桌面端有 6 个 KPI、5 个面板、4 行风险表；移动端 390px 视口可正常显示；浏览器 console 无 error

README 的项目定位也应以 browser-based analytics dashboard 为主，Power BI 只作为 optional recreation notes。

### 1. 数据清洗脚本

文件：

```text
scripts/build_dashboard.ps1
```

这个脚本会：

- 读取 `data/superstore_raw.csv`
- 清洗日期字段
- 转换销售额、利润、折扣、数量等数值字段
- 创建 `Year`、`Month`、`YearMonth`
- 计算 `ProfitMargin`
- 导出 `data/superstore_cleaned.csv`
- 生成多个 summary CSV
- 生成 dashboard 图片

运行方式：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_dashboard.ps1
```

### 2. 分析输出

文件夹：

```text
analysis/
```

已经生成的分析输出包括：

- 月度销售和利润趋势
- 地区表现
- 品类盈利能力
- 客户类型贡献
- 子类别表现
- 高销售低利润子类别
- 总结指标 JSON

关键指标：

- Total Sales: $14.92M
- Total Profit: $1.52M
- Profit Margin: 10.2%
- Total Orders: 5,496
- Total Quantity: 214,777
- Average Discount: 5.0%
- Negative Profit Rows: 4,264

重要发现：

- West 是销售额最高地区，销售额约 $3.60M
- Technology 是利润最高品类，利润约 $886.3K
- Corporate 是销售额最高客户类型，销售额约 $5.50M
- Tables 销售额高，但利润率为 -5.2%
- Bookcases 也是高销售低利润风险子类别

### 3. Dashboard 截图

文件：

```text
assets/sales_performance_dashboard.png
```

这是用脚本生成的静态 dashboard 图片。它不是 Power BI 截图，但用于 README 预览目前是可接受的。

注意：如果之后完成真实 `.pbix` 文件，最好从 Power BI Desktop 导出新的截图替换这个文件。

### 4. README mini case study

文件：

```text
README.md
```

README 已经从普通项目介绍升级为 mini case study，包含：

- Business Problem
- Business Questions
- Dataset
- Tools
- Data Cleaning Steps
- Analysis Approach
- Dashboard KPIs
- Key Findings
- Business Recommendations
- Limitations
- Next Steps
- Project Structure
- How to Reproduce
- SQL Analysis
- Optional Power BI Implementation Notes
- Resume Bullet Points

README 的语气已经调整为 entry-level Data Analyst 项目，不夸大。

目前 README 明确说明：

- 项目当前没有 `.pbix` 文件
- dashboard image 是静态图
- Power BI 文件需要后续手动完成

### 5. SQL 分析层

文件夹：

```text
sql/
```

新增了 SQLite 分析文件，用来增强项目的 Data Analyst 真实感。

文件包括：

- `01_create_tables.sql`
- `02_sales_kpis.sql`
- `03_monthly_trends.sql`
- `04_region_analysis.sql`
- `05_product_profitability.sql`
- `06_customer_segment_analysis.sql`
- `07_high_sales_low_profit.sql`
- `run_sqlite_analysis.ps1`
- `README.md`

这些 SQL 文件覆盖的问题：

- 总销售额、利润、利润率、订单数
- 月度趋势
- 地区表现
- 产品品类和子类别利润
- 客户类型贡献
- 高销售低利润子类别

本机目前没有 `sqlite3`，所以 SQL 文件尚未在本机实际运行；但是已用 PowerShell 复算过关键 KPI 和高销售低利润逻辑。

### 6. 数据字典

文件：

```text
data_dictionary.md
```

这个文件解释了 cleaned dataset 每个字段的：

- 字段名
- 数据类型
- 含义
- 分析用途

已经验证覆盖 `data/superstore_cleaned.csv` 的全部字段。

这是为了让项目更像真实公司的分析交付物，也更适合 entry-level Data Analyst 简历项目。

## Power BI 当前进度

重要更新：

用户目前使用 Mac，没有 Power BI Desktop。Power BI 不再是当前项目完成的必要路径。

下面内容保留为历史记录和可选扩展说明。如果之后用户重新使用 Windows 或 Power BI Desktop，可以继续参考。

用户已经安装了中文版 Power BI Desktop。

用户已经成功导入 CSV 数据。为了避免中文路径问题，使用的是这个文件：

```text
C:\Users\admin\Desktop\powerbi_import\superstore_cleaned.csv
```

Power BI 中的数据表名称：

```text
superstore_cleaned
```

已经创建或正在创建的 DAX measures：

```DAX
Total Sales = SUM(superstore_cleaned[Sales])
```

```DAX
Total Profit = SUM(superstore_cleaned[Profit])
```

```DAX
Profit Margin = DIVIDE([Total Profit], [Total Sales])
```

```DAX
Total Orders = DISTINCTCOUNT(superstore_cleaned[OrderID])
```

```DAX
Total Quantity = SUM(superstore_cleaned[Quantity])
```

```DAX
Average Discount = AVERAGE(superstore_cleaned[Discount])
```

```DAX
Negative Profit Rows =
COUNTROWS(
    FILTER(
        superstore_cleaned,
        superstore_cleaned[Profit] < 0
    )
)
```

用户曾经一次性粘贴多个 measure，导致 Power BI 里出现一个错误的旧 measure，名字是中文：

```text
度量值
```

处理建议：

- 删除带红色三角形的错误 measure `度量值`
- 保留正确创建的 measures

## Power BI 下一步

当前不建议优先继续 Power BI。Mac 环境下优先使用 `dashboard/index.html` 作为最终展示层。

如果未来重新使用 Power BI Desktop，再继续以下步骤。

接下来应该在 Power BI 里创建 dashboard 页面。

推荐布局：

### 第一行 KPI Cards

做 4 个卡片：

- Total Sales
- Total Profit
- Profit Margin
- Total Orders

中文版 Power BI 中，卡片图标是可视化面板里带 `123` 的图标。

### 第二行趋势和地区

做两个图：

1. 折线图：
   - X 轴：`YearMonth`
   - Y 轴：`Total Sales`

2. 条形图：
   - Y 轴：`Region`
   - X 轴：`Total Sales`

### 第三行产品和客户

做三个图：

1. 条形图：
   - Category
   - Total Profit

2. 条形图：
   - CustomerSegment
   - Total Sales

3. 表格：
   - SubCategory
   - Sales 或 Total Sales
   - Profit 或 Total Profit
   - Profit Margin

表格用于展示 high-sales low-profit 子类别，例如：

- Tables
- Bookcases

## 重要注意事项

在真正保存出 `.pbix` 文件之前，不要在 README 或简历 bullet 里写：

```text
Built a Power BI dashboard
```

目前只能说：

```text
Power BI-ready cleaned dataset, DAX measures, and build guide
```

等用户在 Power BI Desktop 中完成 dashboard，并保存为：

```text
dashboard/sales_performance_dashboard.pbix
```

之后才可以把 README 和简历 bullet 改成真正的 Power BI dashboard 项目。

## Git 状态

项目已经初始化为 Git 仓库。

由于 Codex sandbox 用户和 Windows 用户不同，普通 `git status` 可能会触发 dubious ownership。使用这个命令查看状态：

```powershell
git -c safe.directory=C:/Users/admin/Desktop/销售数据分析仪表盘 status --short
```

目前大部分文件还未 commit。

## 后续建议

优先级建议：

1. 使用浏览器打开 `dashboard/index.html`，确认 Mac 上展示正常。
2. 检查 README 是否准确描述 browser-based dashboard。
3. 不要写 “Built a Power BI dashboard”，除非未来真的保存出 `.pbix` 文件。
4. 可以把 `dashboard/index.html` 作为 GitHub portfolio 的主要展示成果。
5. 最后检查 GitHub 项目结构并 commit。

## 给未来 Codex 的提醒

- 用户希望中文解释计划和步骤。
- GitHub/README/简历 bullet 建议保持英文。
- 用户是 UCSB PSTAT 毕业生，没有实习经验，希望用项目补简历。
- 回答要稳妥，不要夸大项目。
- 用户现在使用 Mac，没有 Power BI Desktop；优先走 browser-based dashboard 路线。
- 如果用户发 Power BI 截图，直接根据截图告诉他下一步点哪里。
- 不要说已经完成 `.pbix`，除非文件真实存在。
