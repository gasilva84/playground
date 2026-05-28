INSERT INTO store.transacoes (
    pedido,
    val_pedido,
    qtde,
    dat_compra
)
VALUES
    (
        'TESTE-INTERVALO-ATUAL',
        10.00,
        1,
        date_bin('10 minutes', CURRENT_TIMESTAMP, TIMESTAMP WITH TIME ZONE '2000-01-01 00:00:00+00') + interval '1 minute'
    ),
    (
        'TESTE-PROXIMO-INTERVALO',
        20.00,
        2,
        date_bin('10 minutes', CURRENT_TIMESTAMP, TIMESTAMP WITH TIME ZONE '2000-01-01 00:00:00+00') + interval '11 minutes'
    ),
    (
        'TESTE-QUARTA-PARTICAO',
        30.00,
        3,
        date_bin('10 minutes', CURRENT_TIMESTAMP, TIMESTAMP WITH TIME ZONE '2000-01-01 00:00:00+00') + interval '31 minutes'
    ),
    (
        'TESTE-PARTICAO-DEFAULT',
        99.99,
        1,
        date_bin('10 minutes', CURRENT_TIMESTAMP, TIMESTAMP WITH TIME ZONE '2000-01-01 00:00:00+00') + interval '30 days'
    );

SELECT store.coletar_metricas_particoes_transacoes();
