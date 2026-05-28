CREATE OR REPLACE FUNCTION store.purgar_particoes_transacoes()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_iniciado_em timestamp with time zone := clock_timestamp();
    v_particoes_antes text[];
    v_particoes_depois text[];
    v_particoes_excluidas text[];
    v_mensagem text;
BEGIN
    SELECT coalesce(array_agg(nome_particao ORDER BY dat_inicio), ARRAY[]::text[])
      INTO v_particoes_antes
      FROM store.vw_transacoes_particoes
     WHERE particao_default = false;

    BEGIN
        PERFORM partman.run_maintenance(
            p_parent_table := 'store.transacoes',
            p_analyze := false,
            p_jobmon := true
        );

        SELECT coalesce(array_agg(nome_particao ORDER BY dat_inicio), ARRAY[]::text[])
          INTO v_particoes_depois
          FROM store.vw_transacoes_particoes
         WHERE particao_default = false;

        SELECT coalesce(array_agg(particao ORDER BY particao), ARRAY[]::text[])
          INTO v_particoes_excluidas
          FROM unnest(v_particoes_antes) AS antes(particao)
         WHERE NOT antes.particao = ANY (v_particoes_depois);

        INSERT INTO store.transacoes_purge_metricas (
            iniciado_em,
            finalizado_em,
            particoes_antes,
            particoes_depois,
            particoes_excluidas,
            nomes_particoes_excluidas,
            status
        )
        VALUES (
            v_iniciado_em,
            clock_timestamp(),
            cardinality(v_particoes_antes),
            cardinality(v_particoes_depois),
            cardinality(v_particoes_excluidas),
            v_particoes_excluidas,
            'succeeded'
        );

        PERFORM store.coletar_metricas_particoes_transacoes();
    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS v_mensagem = MESSAGE_TEXT;

            INSERT INTO store.transacoes_purge_metricas (
                iniciado_em,
                finalizado_em,
                particoes_antes,
                particoes_depois,
                particoes_excluidas,
                nomes_particoes_excluidas,
                status,
                mensagem
            )
            VALUES (
                v_iniciado_em,
                clock_timestamp(),
                cardinality(v_particoes_antes),
                cardinality(v_particoes_antes),
                0,
                ARRAY[]::text[],
                'failed',
                v_mensagem
            );

            RAISE;
    END;
END;
$$;
