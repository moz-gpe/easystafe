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

O dataframe de entrada com `provincia` e `distrito` substituidas por
`provincia_id` e `distrito_id` (inteiros).

## Details

Codifica as seguintes dimensoes:

- provincia_id:

  Inteiro de dois digitos derivado de `provincia`. Valores nao
  reconhecidos ou `NA` sao codificados como `99L`. A coluna `provincia`
  original e removida.

- distrito_id:

  Inteiro de quatro digitos (prefixo de provincia mais numero sequencial
  do distrito) derivado de `distrito`. Valores nao reconhecidos ou `NA`
  sao codificados como `9999L`. A coluna `distrito` original e removida.

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
