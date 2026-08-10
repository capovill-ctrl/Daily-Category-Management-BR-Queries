-- ============================================================================
-- Recorte: Pet products com displayed margin >= 60% e CALCULO FRESCO (<= 2 dias)
-- ============================================================================
-- Derivada da query-base (base_produtos_br_displayed_margin.sql).
-- Por que o filtro de frescor: margin.m2/mp sao gravados no momento do calculo
-- (campo utms). A pagina do produto recalcula continuamente; filtrando por
-- calculo <= 2 dias, os valores do arquivo batem com o "% mrg" e o
-- "Preco local" exibidos no site.
--
-- Engine: Spark SQL no Zeppelin AWS (analytics.joom.ai/zeppelin-aws)
-- Notebook: https://analytics.joom.ai/zeppelin-aws/#/notebook/2MY1R4GWV
-- Volume de referencia (2026-08-10): 1.449 produtos (de 3.461 no total >= 60%).
-- Para outra categoria: trocar o level_1_category_name.
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
WHERE pp.p.brProdMin.margin.m2 >= 60
  AND pp.p.brProdMin.margin.jpp.amount > 0
  AND pp.p.brProdMin.margin.mp.amount > 0
  AND ap.level_1_category_name = 'Pet products'
  AND TO_TIMESTAMP(FROM_UNIXTIME(pp.utms / 1000.0)) >= CURRENT_TIMESTAMP() - INTERVAL 2 DAYS
ORDER BY displayed_margin_pct DESC
