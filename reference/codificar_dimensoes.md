# Codificar variaveis de dimensao para modelacao dimensional

Substitui variaveis geograficas de texto por identificadores numericos
compactos adequados para carregamento em DuckDB ou outras bases de dados
relacionais. A funcao e aplicada apos
[`config_para_duckdb()`](https://moz-gpe.github.io/easystafe/reference/config_para_duckdb.md)
no pipeline de preparacao de dados.

## Usage

``` r
codificar_dimensoes(df)
```

## Arguments

- df:

  Um dataframe, tipicamente o resultado de
  [`config_para_duckdb()`](https://moz-gpe.github.io/easystafe/reference/config_para_duckdb.md).

## Value

O dataframe de entrada com `provincia` substituida por `provincia_id`
(inteiro). Valores de `provincia` nao reconhecidos ou `NA` sao
codificados como `99L`.

## Details

Actualmente codifica:

- provincia_id:

  Identificador numerico de dois digitos derivado de `provincia`. A
  coluna `provincia` original e removida.

## Examples

``` r
if (FALSE) { # \dontrun{
lookups <- carregar_lookups_esistafe("Data/lookups.xlsx")

df <- processar_extracto_esistafe(
  source_path   = "Data/202602/",
  df_ugb_lookup = lookups$ugb
) |>
  adicionar_lookups_esistafe(lookups) |>
  config_para_duckdb() |>
  codificar_dimensoes()
} # }
```
