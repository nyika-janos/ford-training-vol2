config {
  type: "table",
  schema: "${dataset_name}",
  name: "monthly_orders_by_ship_mode",
  description: "Havi értékesítés szállítási módok szerint",
  tags: ["aggregated", "monthly"]
}

SELECT
  FORMAT_TIMESTAMP('%Y-%m', PARSE_TIMESTAMP('%d/%m/%Y', order_date)) AS year_month,
  ship_mode,
  SUM(sales) AS total_sales,
  COUNT(DISTINCT order_id) AS order_count
FROM
  `${project_id}.${dataset_name}.${raw_table_name}`
GROUP BY
  year_month,
  ship_mode
ORDER BY
  year_month DESC,
  total_sales DESC