WITH first_quote AS (
  SELECT
    q.quote_id,
    q.deal_id,
    q.delivery_channel,
    q.created_ts_msk,
    ROW_NUMBER() OVER (
      PARTITION BY q.deal_id
      ORDER BY q.created_ts_msk ASC
    ) AS rn
  FROM b2b_mart.fact_quotes q
  WHERE q.delivery_channel IN ('sea', 'aero')
),

quote_products AS (
  SELECT DISTINCT
    fq.quote_id,
    fq.deal_id,
    fq.delivery_channel,
    fq.created_ts_msk,
    qv.product_id
  FROM first_quote fq
  JOIN b2b_mart.fact_quotes_variants qv
    ON fq.quote_id = qv.quote_id
  WHERE fq.rn = 1
    AND qv.product_id IS NOT NULL
),

product_channels AS (
  SELECT
    product_id,
    COUNT(*) AS quote_rows,
    COUNT(DISTINCT deal_id) AS deals,
    SUM(CASE WHEN delivery_channel = 'sea' THEN 1 ELSE 0 END) AS sea_quotes,
    SUM(CASE WHEN delivery_channel = 'aero' THEN 1 ELSE 0 END) AS aero_quotes,
    MAX(created_ts_msk) AS last_quote_ts
  FROM quote_products
  GROUP BY product_id
)

SELECT
  product_id,
  quote_rows,
  deals,
  sea_quotes,
  aero_quotes,
  last_quote_ts,
  CASE
    WHEN sea_quotes > 0 AND aero_quotes = 0 THEN 'historically_sea_only'
    WHEN sea_quotes > 0 AND aero_quotes > 0 THEN 'historically_both'
    WHEN sea_quotes = 0 AND aero_quotes > 0 THEN 'historically_aero_only'
    ELSE 'unknown'
  END AS historical_shipping_type
FROM product_channels
WHERE sea_quotes > 0
  AND aero_quotes = 0
ORDER BY quote_rows DESC;
