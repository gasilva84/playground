CREATE OR REPLACE VIEW store.vw_transacoes_ultimo_purge AS
SELECT
    id,
    iniciado_em,
    finalizado_em,
    particoes_antes,
    particoes_depois,
    particoes_excluidas,
    nomes_particoes_excluidas,
    status,
    mensagem
FROM store.transacoes_purge_metricas
ORDER BY iniciado_em DESC, id DESC
LIMIT 1;
