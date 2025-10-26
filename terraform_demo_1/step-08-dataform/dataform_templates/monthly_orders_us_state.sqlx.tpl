config {
  type: "table",
  schema: "${dataset_name}",
  name: "monthly_orders_us_state",
  description: "USA államonkénti rendelések havi bontásban",
  tags: ["aggregated", "monthly", "usa"]
}

SELECT
  FORMAT_TIMESTAMP('%Y-%m', PARSE_TIMESTAMP('%d/%m/%Y', order_date)) AS year_month,
  state,
  COUNT(DISTINCT order_id) AS order_count
FROM
  `${project_id}.${dataset_name}.${raw_table_name}`
WHERE
  country = 'United States'
GROUP BY
  year_month,
  state
ORDER BY
  year_month DESC,
  order_count DESC