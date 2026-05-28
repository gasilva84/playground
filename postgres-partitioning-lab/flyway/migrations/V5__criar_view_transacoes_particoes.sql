CREATE OR REPLACE VIEW store.vw_transacoes_particoes AS
SELECT
    child_ns.nspname AS schema_particao,
    child.relname AS nome_particao,
    pg_get_expr(child.relpartbound, child.oid) AS limite_particao,
    pg_get_expr(child.relpartbound, child.oid) = 'DEFAULT' AS particao_default,
    bounds.valores[1]::timestamp with time zone AS dat_inicio,
    bounds.valores[2]::timestamp with time zone AS dat_fim
FROM pg_inherits inh
JOIN pg_class parent
  ON parent.oid = inh.inhparent
JOIN pg_namespace parent_ns
  ON parent_ns.oid = parent.relnamespace
JOIN pg_class child
  ON child.oid = inh.inhrelid
JOIN pg_namespace child_ns
  ON child_ns.oid = child.relnamespace
LEFT JOIN LATERAL regexp_match(
    pg_get_expr(child.relpartbound, child.oid),
    'FROM \(''([^'']+)''\) TO \(''([^'']+)''\)'
) AS bounds(valores)
  ON true
WHERE parent_ns.nspname = 'store'
  AND parent.relname = 'transacoes';
