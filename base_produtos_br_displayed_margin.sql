-- =============================================================================
-- QUERY-BASE: todos os produtos BR validos com gross margin no badge do site
-- =============================================================================
-- O que responde: todos os produtos ativos no Brasil (Active + Active BR)
-- cuja gross margin aparece no site:
--   displayed_margin_pct = o badge '% mrg' da pagina do produto (margin.m2)
--   preco_local_meli     = o 'Preco local' da pagina (margin.mp)
--   joompro_price        = preco DDP unitario no lote (margin.jpp)
--   margem_calculada_em  = quando o valor foi calculado (campo utms)
--
-- Criterio 'margem aparecendo no site': m2 preenchido, jpp > 0, mp > 0 e
-- mpc > 0 (anuncios Meli comparaveis sustentando o badge).
--
-- IMPORTANTE: o site recalcula a margem continuamente; esta query le o snapshot
-- diario do warehouse, entao os valores sao os do site com ate ~1 dia de atraso.
-- Nao existe tabela no Zeppelin com o valor 'ao vivo' da pagina.
--
-- Volume de referencia (2026-08-10): 2.461.011 produtos.
-- Para recortes por categoria use o recorte_margem_por_categoria_TEMPLATE.sql.
--
-- Engine: Spark SQL no Zeppelin AWS (analytics.joom.ai/zeppelin-aws)
-- Notebook (roda + exporta XLSX): https://analytics.joom.ai/zeppelin-aws/#/notebook/2MY1R4GWV
-- =============================================================================

SELECT
pp._id AS product_id,
ap.orig_name AS product_name,
ap.level_1_category_name,
ap.level_2_category_name,
ap.level_3_category_name,
ap.category_name AS leaf_category_name,
pp.p.brProdMin.margin.m2 AS displayed_margin_pct,
pp.p.brProdMin.margin.jpp.amount / 1000000.0 AS joompro_price,
pp.p.brProdMin.margin.mp.amount / 1000000.0 AS preco_local_meli,
TO_TIMESTAMP(FROM_UNIXTIME(pp.utms / 1000.0)) AS margem_calculada_em
FROM mongo.b2b_product_product_prices_daily_snapshot pp
JOIN b2b_mart.ss_assortment_products ap
ON pp._id = ap.product_id
AND ap.status = 'Active'
AND ap.status_br = 'Active'
WHERE pp.p.brProdMin.margin.m2 IS NOT NULL
AND pp.p.brProdMin.margin.jpp.amount > 0
AND pp.p.brProdMin.margin.mp.amount > 0
AND pp.p.brProdMin.margin.mpc > 0
ORDER BY displayed_margin_pct DESC
