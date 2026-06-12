# Add daily exchange rate conversions to a razao contabilistica tibble

Joins a wide daily-rates table (from
`obter_conversao_bancomoc(wide = TRUE)`) to `df` on the transaction
date, then computes `_usd` and `_eur` variants of `valor_lancamento`,
`saldo_actual`, and `saldo_inicial_fim` using per-row `compra` rates.
The EUR/USD cross rate is derived as `taxa_euro / taxa_dolar`.
`taxa_dolar` and `taxa_euro` are relocated after `mes`. The three source
columns are renamed to their `_mzn` equivalents.

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
  `valor_lancamento`, `saldo_actual`, and `saldo_inicial_fim`.

- rates_diarias:

  Tibble. Wide daily-rates table returned by
  `obter_conversao_bancomoc(wide = TRUE)`, with columns `date`,
  `taxa_dolar`, and `taxa_euro`.

## Value

`df` enriched with `taxa_dolar` and `taxa_euro` positioned after `mes`,
and six currency columns appended at the end: `valor_lancamento_mzn`,
`valor_lancamento_eur`, `valor_lancamento_usd`, `saldo_actual_mzn`,
`saldo_actual_eur`, `saldo_actual_usd`, `saldo_inicial_fim_mzn`,
`saldo_inicial_fim_eur`, and `saldo_inicial_fim_usd`.
