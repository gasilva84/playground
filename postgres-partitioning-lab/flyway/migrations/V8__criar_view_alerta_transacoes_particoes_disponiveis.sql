CREATE OR REPLACE VIEW store.vw_alerta_transacoes_particoes_disponiveis AS
SELECT
    count(*) AS particoes_disponiveis,
    count(*) <= 1 AS alertar
FROM store.vw_transacoes_particoes
WHERE particao_default = false
  AND dat_inicio > date_bin(
      '10 minutes',
      CURRENT_TIMESTAMP,
      TIMESTAMP WITH TIME ZONE '2000-01-01 00:00:00+00'
  );
