-- ============================================================================
-- Query-base: produtos BR validos com gross margin (o "% mrg" do site)
-- ============================================================================
-- O que responde: todos os produtos ativos no Brasil (Active + Active BR)
-- que possuem gross margin atrelada - a mesma do site:
--   displayed_margin_pct = o badge "% mrg" da pagina do produto (margin.m2)
--   preco_local_meli     = o "Preco local" da pagina (margin.mp)
--   joompro_price        = preco DDP unitario no lote (margin.jpp)
--
-- IMPORTANTE - sobre diferencas vs o site:
--   O site recalcula a margem continuamente. Esta query le o snapshot diario
--   do warehouse, entao o valor e o do ULTIMO CALCULO gravado (ver coluna
--   margem_calculada_em). Se a pagina recalculou depois disso, o numero do
--   site pode diferir alguns pontos ate o proximo snapshot. Nao existe tabela
--   no Zeppelin com o valor "ao vivo" da pagina.
--
-- Fonte / engine: Spark SQL no Zeppelin AWS (analytics.joom.ai/zeppelin-aws)
--   - mongo.b2b_product_product_prices_daily_snapshot  -> margens (struct margin)
--   - b2b_mart.ss_assortment_products                  -> nome, categorias, status
--
-- Volume de referencia (2026-08-10): 2.461.011 produtos.
-- Recortes: adicionar no WHERE, ex.:
--   AND pp.p.brProdMin.margin.m2 >= 60
--   AND ap.level_1_category_name = 'Pet products'
--
-- Notebook (roda + exporta XLSX/CSV):
--   https://analytics.joom.ai/zeppelin-aws/#/notebook/2MY1R4GWV
-- ============================================================================

SELECT
    pp._id                                        AS product_id,
    ap.orig_name                                  AS product_name,
    ap.level_1_category_name,
    ap.level_2_category_name,
    ap.level_3_category_name,
    ap.category_name                              AS leaf_category_name,
    pp.p.brProdMin.margin.m2                      AS displayed_margin_pct,
    pp.p.brProdMin.margin.jpp.amount / 1000000.0  AS joompro_price,
    pp.p.brProdMin.margin.mp.amount / 1000000.0   AS preco_local_meli,
    TO_TIMESTAMP(FROM_UNIXTIME(pp.utms / 1000.0)) AS margem_calculada_em
FROM mongo.b2b_product_product_prices_daily_snapshot pp
JOIN b2b_mart.ss_assortment_products ap
  ON pp._id = ap.product_id
 AND ap.status = 'Active'
 AND ap.status_br = 'Active'
WHERE pp.p.brProdMin.margin.m2 IS NOT NULL
  AND pp.p.brProdMin.margin.jpp.amount > 0
  AND pp.p.brProdMin.margin.mp.amount > 0
ORDER BY displayed_margin_pct DESC
