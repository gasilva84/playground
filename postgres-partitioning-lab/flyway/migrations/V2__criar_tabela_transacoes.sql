CREATE TABLE store.transacoes (
    pk bigint GENERATED ALWAYS AS IDENTITY,
    pedido varchar(64) NOT NULL,
    val_pedido numeric(12, 2) NOT NULL,
    qtde integer NOT NULL,
    dat_compra timestamp with time zone NOT NULL,
    CONSTRAINT transacoes_pk PRIMARY KEY (pk, dat_compra),
    CONSTRAINT transacoes_val_pedido_ck CHECK (val_pedido >= 0),
    CONSTRAINT transacoes_qtde_ck CHECK (qtde > 0),
    CONSTRAINT transacoes_pedido_not_blank_ck CHECK (length(btrim(pedido)) > 0)
) PARTITION BY RANGE (dat_compra);

CREATE INDEX transacoes_pedido_idx
    ON store.transacoes (pedido);

CREATE INDEX transacoes_dat_compra_idx
    ON store.transacoes (dat_compra);
