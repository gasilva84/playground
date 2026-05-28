CREATE TABLE store.transacoes_purge_metricas (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    iniciado_em timestamp with time zone NOT NULL DEFAULT clock_timestamp(),
    finalizado_em timestamp with time zone,
    particoes_antes integer NOT NULL,
    particoes_depois integer NOT NULL,
    particoes_excluidas integer NOT NULL,
    nomes_particoes_excluidas text[] NOT NULL,
    status text NOT NULL,
    mensagem text,
    CONSTRAINT transacoes_purge_metricas_status_ck
        CHECK (status IN ('succeeded', 'failed'))
);
