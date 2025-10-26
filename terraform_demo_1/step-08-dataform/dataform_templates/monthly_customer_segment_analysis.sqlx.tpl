config {
  type: "table",
  schema: "${dataset_name}",
  name: "monthly_customer_segment_analysis",
  description: "Ügyfél szegmens elemzés havi bontásban",
  tags: ["aggregated", "monthly", "customers"]
}

SELECT
  FORMAT_TIMESTAMP('%Y-%m', PARSE_TIMESTAMP('%d/%m/%Y', order_date)) AS year_month,
  segment,
  COUNT(DISTINCT order_id) AS order_count,
  SUM(sales) AS total_sales,
  ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS avg_order_value,
  COUNT(DISTINCT customer_id) AS unique_customers
FROM
  `${project_id}.${dataset_name}.${raw_table_name}`
GROUP BY
  year_month,
  segment
ORDER BY
  year_month DESC,
  total_sales DESC