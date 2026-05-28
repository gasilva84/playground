SELECT cron.unschedule(jobid)
  FROM cron.job
 WHERE jobname = 'purge_particoes_transacoes';

SELECT cron.schedule(
    'purge_particoes_transacoes',
    '* * * * *',
    $$SELECT store.purgar_particoes_transacoes();$$
);
