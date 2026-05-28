# PostgreSQL Partitioning Lab

Este projeto demonstra como criar uma tabela particionada a cada 10 minutos no
PostgreSQL 17.9, gerenciar particoes com `pg_partman`, agendar manutencao e
purge com `pg_cron`, versionar objetos com Flyway e monitorar particao default,
particoes futuras e execucoes de purge.

## Componentes

### Docker

O Docker Compose sobe dois servicos:

- `postgres`: PostgreSQL 17.9 customizado com pacotes `pg_partman` e `pg_cron`.
- `flyway`: container responsavel por aplicar as migrations.

O PostgreSQL fica disponivel em `localhost:5499`. As variaveis podem ser
sobrescritas por ambiente ou por arquivo `.env`:

```bash
POSTGRES_USER=usr_lab001
POSTGRES_PASSWORD=pdw_lab001
POSTGRES_DB=db_lab001
DB_TIMEZONE=America/Sao_Paulo
```

### Flyway

O Flyway versiona toda DDL, DML e DCL do lab. O schema default e `store`, entao
o historico fica em `store.flyway_schema_history`.

As migrations ficam em `flyway/migrations` e seguem a ordem:

1. schemas e extensoes
2. tabela particionada
3. configuracao do `pg_partman`
4. tabelas de metricas
5. views, uma por migration
6. funcoes de monitoramento e purge
7. jobs do `pg_cron`
8. massa de teste

### pg_partman

O `pg_partman` gerencia as particoes de `store.transacoes` usando:

- campo de controle: `dat_compra`
- intervalo: `10 minutes`
- particoes futuras: `premake = 4`
- particao default habilitada
- retencao: `30 minutes`

### pg_cron

O `pg_cron` agenda:

- criacao/manutencao de particoes via `partman.run_maintenance_proc`
- coleta de metricas
- purge de particoes antigas

O timezone do banco, logs e cron usa `America/Sao_Paulo` por padrao.

## Observabilidade automatica

As views de alerta e tabelas de metricas deste lab podem ser consumidas por
ferramentas externas. Algumas opcoes comuns:

- **Prometheus + postgres_exporter**: expor consultas SQL customizadas como
  metricas, por exemplo quantidade de registros na particao default, particoes
  futuras disponiveis e particoes excluidas no ultimo purge.
- **Grafana**: criar dashboards e alertas usando Prometheus ou o datasource
  PostgreSQL diretamente.
- **Grafana Alerting ou Alertmanager**: enviar notificacoes para Slack, e-mail,
  Microsoft Teams, PagerDuty ou webhooks quando uma view retornar `alertar = true`.
- **pgwatch2**: monitoramento especializado de PostgreSQL com coleta periodica
  de metricas SQL e dashboards prontos.
- **Zabbix ou Datadog**: executar checks SQL periodicos e centralizar alertas
  junto com metricas de infraestrutura.
- **Jobs externos simples**: um script em shell, Python ou Go pode consultar as
  views `store.vw_alerta_*` e publicar eventos em uma fila, webhook ou sistema
  de incidentes.

Consultas candidatas para observabilidade:

```sql
SELECT * FROM store.vw_alerta_transacoes_particao_default;
SELECT * FROM store.vw_alerta_transacoes_particoes_disponiveis;
SELECT * FROM store.vw_alerta_transacoes_manutencao_particoes;
SELECT * FROM store.vw_alerta_transacoes_particoes_criadas;
SELECT * FROM store.vw_transacoes_ultimo_purge;
```

## Executar do zero

```bash
docker compose down -v --rmi local
docker compose up --build --abort-on-container-exit flyway
docker compose up -d postgres
```

## Tutorial: purge de particoes no PostgreSQL

### 1. Instalar extensoes

As extensoes sao instaladas na imagem Docker e criadas por migration:

```sql
CREATE SCHEMA IF NOT EXISTS store;
CREATE SCHEMA IF NOT EXISTS partman;

CREATE EXTENSION IF NOT EXISTS pg_partman SCHEMA partman;
CREATE EXTENSION IF NOT EXISTS pg_cron;
```

O PostgreSQL precisa iniciar com `pg_cron` em `shared_preload_libraries`:

```yaml
command: >
  postgres
  -c shared_preload_libraries='pg_cron'
  -c cron.database_name='db_lab001'
  -c cron.timezone='America/Sao_Paulo'
```

### 2. Criar tabela particionada

A tabela usa particionamento nativo por range. Como o particionamento e por
janela de tempo, `dat_compra` usa `timestamp with time zone`.

```sql
CREATE TABLE store.transacoes (
    pk bigint GENERATED ALWAYS AS IDENTITY,
    pedido varchar(64) NOT NULL,
    val_pedido numeric(12, 2) NOT NULL,
    qtde integer NOT NULL,
    dat_compra timestamp with time zone NOT NULL,
    CONSTRAINT transacoes_pk PRIMARY KEY (pk, dat_compra)
) PARTITION BY RANGE (dat_compra);
```

### 3. Configurar o pg_partman

O `pg_partman` cria a particao default, as particoes futuras e aplica a retencao:

```sql
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
```

Neste lab, a retencao preserva particoes maiores que o horario corrente e as
particoes dos 30 minutos anteriores.

### 4. Criar monitoramento do purge

O purge chama a manutencao do `pg_partman` e registra auditoria em tabela:

```sql
CREATE TABLE store.transacoes_purge_metricas (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    iniciado_em timestamp with time zone NOT NULL DEFAULT clock_timestamp(),
    finalizado_em timestamp with time zone,
    particoes_antes integer NOT NULL,
    particoes_depois integer NOT NULL,
    particoes_excluidas integer NOT NULL,
    nomes_particoes_excluidas text[] NOT NULL,
    status text NOT NULL,
    mensagem text
);
```

A funcao `store.purgar_particoes_transacoes()`:

1. lista particoes antes da manutencao
2. executa `partman.run_maintenance`
3. lista particoes depois da manutencao
4. registra quantas particoes foram excluidas
5. atualiza metricas de monitoramento

### 5. Agendar o purge com pg_cron

Neste lab, o purge roda a cada minuto para facilitar a observacao:

```sql
SELECT cron.schedule(
    'purge_particoes_transacoes',
    '* * * * *',
    $$SELECT store.purgar_particoes_transacoes();$$
);
```

Em ambientes reais, ajuste a frequencia de acordo com a janela de retencao, o
volume de dados e o custo operacional.

### 6. Validar

Listar jobs:

```sql
SELECT jobid, jobname, schedule, command, active
FROM cron.job
ORDER BY jobid;
```

Listar particoes:

```sql
SELECT nome_particao, dat_inicio, dat_fim, particao_default
FROM store.vw_transacoes_particoes
ORDER BY particao_default, dat_inicio;
```

Ver ultimo purge:

```sql
SELECT *
FROM store.vw_transacoes_ultimo_purge;
```

Ver historico do cron:

```sql
SELECT jobid, runid, status, return_message, start_time, end_time
FROM cron.job_run_details
ORDER BY start_time DESC
LIMIT 20;
```

## Validacoes uteis

```bash
docker exec postgres-partitioning-lab psql -U usr_lab001 -d db_lab001 -c "select version, description, success from store.flyway_schema_history order by installed_rank;"
docker exec postgres-partitioning-lab psql -U usr_lab001 -d db_lab001 -c "select parent_table, partition_interval, premake, retention from partman.part_config where parent_table = 'store.transacoes';"
docker exec postgres-partitioning-lab psql -U usr_lab001 -d db_lab001 -c "select nome_particao, dat_inicio, dat_fim, particao_default from store.vw_transacoes_particoes order by particao_default, dat_inicio;"
docker exec postgres-partitioning-lab psql -U usr_lab001 -d db_lab001 -c "select * from cron.job order by jobid;"
docker exec postgres-partitioning-lab psql -U usr_lab001 -d db_lab001 -c "select * from store.vw_transacoes_ultimo_purge;"
```
