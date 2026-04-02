[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/LLfWflp4)
# Time-Series Analytics with Window Functions

**Module 3 — Thursday Stretch Assignment**

You are a Business Intelligence (BI) analyst at an e-commerce company. Leadership wants a quarterly executive report on revenue trends, customer retention, and product category performance. Your tool: advanced SQL window functions applied to 12 months of transactional data.

## Dataset

Four tables in a PostgreSQL database:

| Table | Rows | Description |
|---|---|---|
| `customers` | 5,000 | customer_id, signup_date, segment (Consumer, Business, Enterprise) |
| `products` | 300 | product_id, name, category, unit_price (list price) |
| `orders` | ~30,000 | order_id, customer_id, order_date, status (completed, returned, cancelled) |
| `order_items` | ~68,000 | order_item_id, order_id, product_id, quantity, unit_price (price at time of purchase) |

The data spans April 2025 through March 2026. Note that `order_items.unit_price` is the price at time of purchase — it may differ from the product's list price.

## Setup

Create a database and load the data from the CSV files in `data/`. If you need a refresher on creating a PostgreSQL database and loading data, refer to the **Setup** section of the Lab 3 Guide.

## Deliverables

### SQL Queries

Write your queries in the `queries/` directory. Each file should contain well-commented SQL that a colleague could read and understand:

| File | Analysis |
|---|---|
| `cohort_analysis.sql` | Define customer cohorts by first-purchase month using ROW_NUMBER. Analyze repeat-purchase behavior and retention patterns across cohorts. |
| `growth_analysis.sql` | Use LAG/LEAD to compute month-over-month and quarter-over-quarter revenue and order growth rates. |
| `trend_analysis.sql` | Calculate moving averages (7-day, 30-day) using window frame specifications (ROWS BETWEEN). Identify trend patterns. |
| `combined_analysis.sql` | At least two queries that combine multiple window functions in a single query — e.g., cohort retention rates with period-over-period change, or category revenue share with moving average and growth rate. |

### Executive Report

Write `report.md` — a business-facing executive report summarizing your findings. This is your primary deliverable. Structure it as a report to leadership, not a code walkthrough:

- **Revenue trends**: What happened over the 12-month period? Where is growth coming from?
- **Customer retention**: Which cohorts retain best? What does this mean for acquisition strategy?
- **Category performance**: Which categories are growing or declining? What are the implications?
- **Recommendations**: Based on your analysis, what should the business do next?

Support every claim with data from your queries. Include relevant numbers, percentages, and comparisons.

## What the Autograder Checks

The CI workflow validates mechanical requirements only:
- Required SQL files exist in `queries/`
- Each SQL file executes without errors
- Each SQL file uses at least one window function
- `report.md` exists with required section headers

**Green checks do not mean the stretch is complete.** Your submission is evaluated on analytical depth, query sophistication, and report quality. The autograder confirms your files are structurally sound — the substance is what earns your score.

## Portfolio Artifact

This stretch produces a strong portfolio piece. A polished executive report backed by sophisticated SQL demonstrates the analytical communication that hiring managers look for in BI and analytics roles. Your queries show technical depth; your report shows business judgment. Your queries show technical depth; your report shows business judgment.

## Submit

1. Create a branch (e.g., `stretch-time-series`)
2. Add your query files and report
3. Open a PR to `main`
4. Paste your PR URL into TalentLMS → Module 3 → Thursday Stretch to submit this assignment


---

## License

This repository is provided for educational use only. See [LICENSE](LICENSE) for terms.

You may clone and modify this repository for personal learning and practice, and reference code you wrote here in your professional portfolio. Redistribution outside this course is not permitted.
