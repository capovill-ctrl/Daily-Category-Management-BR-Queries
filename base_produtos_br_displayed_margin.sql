-- ============================================================================
-- Query-base: produtos BR validos com displayed margin
-- ============================================================================
-- O que responde: todos os produtos ativos no Brasil (Active + Active BR)
-- que possuem a informacao de margem exibida ao cliente (displayed margin).
--
-- Fonte / engine: Spark SQL no Zeppelin AWS (analytics.joom.ai/zeppelin-aws)
--   - mongo.b2b_product_product_prices_daily_snapshot  -> margens de producao
--   - b2b_mart.ss_assortment_products                  -> nome, categorias, status
--
-- Glossario (campos de producao, mesmos do notebook Margin Verification):
--   displayed_margin_pct = margin.m2  -> margem bruta % mostrada ao cliente:
--                                        (mediana Meli - preco JoomPro) / mediana * 100
--   joompro_price        = margin.jpp -> preco DDP por unidade no pedido minimo
--   stored_meli_median   = margin.mp  -> mediana do Meli usada no calculo
--
-- Filtros: SEM corte de margem (traz qualquer valor, incl. negativo).
--   Apenas: produto Active + Active BR e margem preenchida (m2 nao nulo,
--   jpp > 0, mp > 0).
--
-- Volume de referencia (2026-08-10): 2.461.011 produtos.
-- Recortes: adicionar no WHERE, ex.:
--   AND pp.p.brProdMin.margin.m2 >= 60
--   AND ap.level_1_category_name IN ('Home & Kitchen', 'Garden')
--
-- Notebook de origem (copia da Lais, com preview + export CSV/XLSX):
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
    pp.p.brProdMin.margin.mp.amount / 1000000.0   AS stored_meli_median
FROM mongo.b2b_product_product_prices_daily_snapshot pp
JOIN b2b_mart.ss_assortment_products ap
  ON pp._id = ap.product_id
 AND ap.status = 'Active'
 AND ap.status_br = 'Active'
WHERE pp.p.brProdMin.margin.m2 IS NOT NULL
  AND pp.p.brProdMin.margin.jpp.amount > 0
  AND pp.p.brProdMin.margin.mp.amount > 0
ORDER BY displayed_margin_pct DESC
