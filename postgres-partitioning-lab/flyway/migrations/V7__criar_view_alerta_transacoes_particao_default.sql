CREATE OR REPLACE VIEW store.vw_alerta_transacoes_particao_default AS
SELECT
    count(*) AS registros_na_default,
    count(*) > 0 AS alertar
FROM store.transacoes_default;
