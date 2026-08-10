-- =============================================================================
-- TEMPLATE: ids com gross margin no badge do site, POR CATEGORIA (escolha antes de rodar)
-- =============================================================================
-- COMO USAR - preencha antes de rodar:
-- 1) Troque ESCOLHA_A_CATEGORIA pelo nome exato da categoria nivel 1.
--    Exemplos: 'Pet products', 'Sports & Entertainment', 'Home & Kitchen'
-- 2) (Opcional) Para filtrar subcategoria, descomente a linha do nivel 2 ou 3.
--    Exemplo nivel 3: 'Outdoor Lighting'
-- 3) Ajuste o corte de margem se quiser (padrao: >= 60).
--
-- Para descobrir os nomes exatos das categorias, rode antes:
--   SELECT DISTINCT level_1_category_name, level_2_category_name, level_3_category_name
--   FROM b2b_mart.ss_assortment_products ORDER BY 1,2,3;
--
-- Criterio 'margem aparecendo no site': m2 preenchido, jpp > 0, mp > 0 e mpc > 0
-- (anuncios Meli comparaveis sustentando o badge). Valores identicos ao site com
-- ate ~1 dia de atraso (snapshot diario); margem_calculada_em mostra a data.
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
WHERE pp.p.brProdMin.margin.m2 >= 60
AND pp.p.brProdMin.margin.jpp.amount > 0
AND pp.p.brProdMin.margin.mp.amount > 0
AND pp.p.brProdMin.margin.mpc > 0
AND ap.level_1_category_name = 'ESCOLHA_A_CATEGORIA'
-- AND ap.level_2_category_name = 'ESCOLHA_A_SUBCATEGORIA_N2'
-- AND ap.level_3_category_name = 'ESCOLHA_A_SUBCATEGORIA_N3'
ORDER BY displayed_margin_pct DESC
