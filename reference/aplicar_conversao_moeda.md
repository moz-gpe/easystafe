# Aplicar conversao de moeda a um tibble de extractos do e-SISTAFE

Calcula `valor_lancamento_mt`, `valor_lancamento_usd` e
`valor_lancamento_eur` com base no nome do ficheiro de origem
(`source_file`), aplicando as taxas de cambio fornecidas. Pode ser
chamada de forma independente ou e invocada internamente por
[`processar_extracto_razao_c()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_razao_c.md).

## Usage

``` r
aplicar_conversao_moeda(df, usd_to_mt, eur_to_mt, eur_to_usd)
```

## Arguments

- df:

  Tibble. Output de
  [`processar_extracto_razao_c()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_razao_c.md)
  ou qualquer tibble com as colunas `source_file` e `valor_lancamento`.

- usd_to_mt:

  Numerico. Taxa de cambio USD para MZN. Obrigatorio.

- eur_to_mt:

  Numerico. Taxa de cambio EUR para MZN. Obrigatorio.

- eur_to_usd:

  Numerico. Taxa de cambio EUR para USD. Obrigatorio.

## Value

O tibble de entrada com tres colunas adicionais imediatamente a direita
de `valor_lancamento`:

- valor_lancamento_mt:

  Valor do lancamento em MZN. Para ficheiros MZN, igual a
  `valor_lancamento`. Para ficheiros USD, calculado via
  `valor_lancamento * usd_to_mt`. Para ficheiros EUR, calculado via
  `valor_lancamento * eur_to_mt`.

- valor_lancamento_usd:

  Valor do lancamento em USD. Para ficheiros USD, igual a
  `valor_lancamento`. Para ficheiros MZN, calculado via
  `valor_lancamento / usd_to_mt`. Para ficheiros EUR, calculado via
  `valor_lancamento * eur_to_usd`.

- valor_lancamento_eur:

  Valor do lancamento em EUR. Para ficheiros EUR, igual a
  `valor_lancamento`. Para ficheiros MZN, calculado via
  `valor_lancamento / eur_to_mt`. Para ficheiros USD, calculado via
  `valor_lancamento / eur_to_usd`.

## Details

A logica de conversao baseia-se no nome do ficheiro de origem:

- `"CENTRAL USD"`: `valor_lancamento_mt = valor_lancamento * usd_to_mt`;
  `valor_lancamento_usd = valor_lancamento`;
  `valor_lancamento_eur = valor_lancamento / eur_to_usd`.

- `"CENTRAL EUR"`: `valor_lancamento_mt = valor_lancamento * eur_to_mt`;
  `valor_lancamento_usd = valor_lancamento * eur_to_usd`;
  `valor_lancamento_eur = valor_lancamento`.

- Todos os outros ficheiros (MZN):
  `valor_lancamento_mt = valor_lancamento`;
  `valor_lancamento_usd = valor_lancamento / usd_to_mt`;
  `valor_lancamento_eur = valor_lancamento / eur_to_mt`.

Para re-aplicar conversoes com taxas actualizadas sem re-processar os
PDFs, chame esta funcao directamente sobre o tibble ja processado
(removendo previamente as colunas existentes se necessario).

## Examples

``` r
if (FALSE) { # \dontrun{
# Uso independente sobre um tibble ja processado
df_com_moeda <- aplicar_conversao_moeda(
  df         = df_razao,
  usd_to_mt  = 63.86,
  eur_to_mt  = 70.00,
  eur_to_usd = 1.10
)

# Re-aplicar com taxas actualizadas
df_revalorizado <- df_razao |>
  dplyr::select(-valor_lancamento_mt, -valor_lancamento_usd, -valor_lancamento_eur) |>
  aplicar_conversao_moeda(usd_to_mt = 64.10, eur_to_mt = 71.20, eur_to_usd = 1.11)
} # }
```
