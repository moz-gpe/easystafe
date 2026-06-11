# Add daily exchange rate conversions to a razao contabilistica tibble

Joins a wide daily-rates table (from
`obter_conversao_bancomoc(wide = TRUE)`) to `df` on the transaction
date, then overwrites the `_usd` and `_eur` columns using per-row
`compra` rates. The EUR/USD cross rate is derived as
`taxa_euro / taxa_dolar`. `taxa_dolar` and `taxa_euro` are appended and
relocated after `mes`.

## Usage

``` r
adicionar_conversao_moeda(df, rates_diarias)
```

## Arguments

- df:

  Tibble. Output of
  [`processar_extracto_razao_c()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_razao_c.md)
  or
  [`processar_extracto_absa()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_absa.md),
  containing at minimum the columns `source_file`, `data`, `mes`,
  `valor_lancamento`, `valor_lancamento_usd`, `valor_lancamento_eur`,
  `saldo_inicial_fim`, `saldo_inicial_fim_usd`, and
  `saldo_inicial_fim_eur`.

- rates_diarias:

  Tibble. Wide daily-rates table returned by
  `obter_conversao_bancomoc(wide = TRUE)`, with columns `date`,
  `taxa_dolar`, and `taxa_euro`.

## Value

`df` with `valor_lancamento_usd`, `valor_lancamento_eur`,
`saldo_inicial_fim_usd`, and `saldo_inicial_fim_eur` overwritten using
daily rates, plus `taxa_dolar` and `taxa_euro` columns positioned after
`mes`.
