SELECT cron.unschedule(jobid)
  FROM cron.job
 WHERE jobname IN (
       'partman_maintenance_transacoes',
       'monitoramento_particoes_transacoes'
 );

SELECT cron.schedule(
    'partman_maintenance_transacoes',
    '*/5 * * * *',
    $$CALL partman.run_maintenance_proc();$$
);

SELECT cron.schedule(
    'monitoramento_particoes_transacoes',
    '*/5 * * * *',
    $$SELECT store.coletar_metricas_particoes_transacoes();$$
);
