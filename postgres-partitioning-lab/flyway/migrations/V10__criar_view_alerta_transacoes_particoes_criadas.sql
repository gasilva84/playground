CREATE OR REPLACE VIEW store.vw_alerta_transacoes_particoes_criadas AS
SELECT
    coalesce(particoes_criadas_desde_ultima_coleta, 0) AS particoes_criadas_desde_ultima_coleta,
    coalesce(novas_particoes_criadas, false) AS alertar,
    coletado_em
FROM store.transacoes_particoes_metricas
ORDER BY coletado_em DESC, id DESC
LIMIT 1;
