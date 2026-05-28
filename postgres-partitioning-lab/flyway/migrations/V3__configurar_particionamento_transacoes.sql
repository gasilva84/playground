SELECT partman.create_parent(
    p_parent_table := 'store.transacoes',
    p_control := 'dat_compra',
    p_interval := '10 minutes',
    p_premake := 4,
    p_start_partition := date_bin(
        '10 minutes',
        CURRENT_TIMESTAMP,
        TIMESTAMP WITH TIME ZONE '2000-01-01 00:00:00+00'
    )::text,
    p_default_table := true
);

UPDATE partman.part_config
   SET premake = 4,
       infinite_time_partitions = true,
       retention = '30 minutes',
       retention_keep_table = false,
       retention_keep_index = false
 WHERE parent_table = 'store.transacoes';
