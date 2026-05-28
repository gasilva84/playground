SELECT cron.unschedule(jobid)
  FROM cron.job
 WHERE jobname = 'purge_particoes_transacoes';

SELECT cron.schedule(
    'purge_particoes_transacoes',
    '*/5 * * * *',
    $$SELECT store.purgar_particoes_transacoes();$$
);
