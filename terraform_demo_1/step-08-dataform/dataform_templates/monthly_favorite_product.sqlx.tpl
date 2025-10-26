config {
  type: "table",
  schema: "${dataset_name}",
  name: "monthly_favorite_product",
  description: "Havi top termékek eladási darabszám szerint",
  tags: ["aggregated", "monthly", "products"]
}

WITH monthly_product_sales AS (
  SELECT
    FORMAT_TIMESTAMP('%Y-%m', PARSE_TIMESTAMP('%d/%m/%Y', order_date)) AS year_month,
    product_name,
    COUNT(*) AS order_count,
    SUM(sales) AS total_sales
  FROM
    `${project_id}.${dataset_name}.${raw_table_name}`
  GROUP BY
    year_month,
    product_name
)

SELECT
  year_month,
  product_name,
  order_count,
  total_sales,
  ROW_NUMBER() OVER (PARTITION BY year_month ORDER BY order_count DESC) AS rank
FROM
  monthly_product_sales
QUALIFY rank <= 10
ORDER BY
  year_month DESC,
  rank ASC