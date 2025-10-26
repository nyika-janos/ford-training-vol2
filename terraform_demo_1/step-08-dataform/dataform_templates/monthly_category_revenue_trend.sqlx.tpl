config {
  type: "table",
  schema: "${dataset_name}",
  name: "monthly_category_revenue_trend",
  description: "Kategória bevételi trendek és részesedés",
  tags: ["aggregated", "monthly", "categories"]
}

WITH monthly_totals AS (
  SELECT
    FORMAT_TIMESTAMP('%Y-%m', PARSE_TIMESTAMP('%d/%m/%Y', order_date)) AS year_month,
    SUM(sales) AS monthly_total
  FROM
    `${project_id}.${dataset_name}.${raw_table_name}`
  GROUP BY year_month
),

category_sales AS (
  SELECT
    FORMAT_TIMESTAMP('%Y-%m', PARSE_TIMESTAMP('%d/%m/%Y', order_date)) AS year_month,
    category,
    sub_category,
    SUM(sales) AS total_sales,
    COUNT(DISTINCT order_id) AS order_count
  FROM
    `${project_id}.${dataset_name}.${raw_table_name}`
  GROUP BY
    year_month,
    category,
    sub_category
)

SELECT
  cs.year_month,
  cs.category,
  cs.sub_category,
  cs.total_sales,
  cs.order_count,
  ROUND((cs.total_sales / mt.monthly_total) * 100, 2) AS category_share
FROM
  category_sales cs
JOIN
  monthly_totals mt
ON
  cs.year_month = mt.year_month
ORDER BY
  cs.year_month DESC,
  cs.total_sales DESC