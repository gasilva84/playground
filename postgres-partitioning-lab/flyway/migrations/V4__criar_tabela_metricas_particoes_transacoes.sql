CREATE TABLE store.transacoes_particoes_metricas (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    coletado_em timestamp with time zone NOT NULL DEFAULT clock_timestamp(),
    particoes_disponiveis integer NOT NULL,
    registros_na_default bigint NOT NULL,
    particoes_criadas_desde_ultima_coleta integer NOT NULL,
    novas_particoes_criadas boolean NOT NULL,
    ultima_particao_inicio timestamp with time zone,
    ultima_particao_fim timestamp with time zone,
    particoes text[] NOT NULL
);
