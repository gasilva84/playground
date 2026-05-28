CREATE OR REPLACE FUNCTION store.coletar_metricas_particoes_transacoes()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_particoes text[];
    v_ultima_particao_inicio timestamp with time zone;
    v_ultima_particao_fim timestamp with time zone;
    v_particoes_disponiveis integer;
    v_registros_na_default bigint;
    v_particoes_anteriores text[];
    v_particoes_criadas integer;
BEGIN
    SELECT
        coalesce(array_agg(nome_particao ORDER BY dat_inicio), ARRAY[]::text[]),
        max(dat_inicio),
        max(dat_fim) FILTER (WHERE dat_inicio = (SELECT max(dat_inicio) FROM store.vw_transacoes_particoes WHERE particao_default = false))
      INTO v_particoes, v_ultima_particao_inicio, v_ultima_particao_fim
      FROM store.vw_transacoes_particoes
     WHERE particao_default = false;

    SELECT count(*)
      INTO v_particoes_disponiveis
      FROM store.vw_transacoes_particoes
     WHERE particao_default = false
       AND dat_inicio > date_bin(
           '10 minutes',
           CURRENT_TIMESTAMP,
           TIMESTAMP WITH TIME ZONE '2000-01-01 00:00:00+00'
       );

    SELECT count(*)
      INTO v_registros_na_default
      FROM store.transacoes_default;

    SELECT particoes
      INTO v_particoes_anteriores
      FROM store.transacoes_particoes_metricas
     ORDER BY coletado_em DESC, id DESC
     LIMIT 1;

    SELECT count(*)
      INTO v_particoes_criadas
      FROM unnest(v_particoes) AS atual(nome_particao)
     WHERE v_particoes_anteriores IS NOT NULL
       AND NOT atual.nome_particao = ANY (v_particoes_anteriores);

    INSERT INTO store.transacoes_particoes_metricas (
        particoes_disponiveis,
        registros_na_default,
        particoes_criadas_desde_ultima_coleta,
        novas_particoes_criadas,
        ultima_particao_inicio,
        ultima_particao_fim,
        particoes
    )
    VALUES (
        v_particoes_disponiveis,
        v_registros_na_default,
        v_particoes_criadas,
        v_particoes_criadas > 0,
        v_ultima_particao_inicio,
        v_ultima_particao_fim,
        v_particoes
    );
END;
$$;
