# Prepare enriched e-SISTAFE output for loading into DuckDB

Filters rows to `data_tipo == "Valor"` and selects a fixed set of
columns from the dataframe produced by the pipeline
[`processar_extracto_esistafe()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_esistafe.md)
\|\>
[`adicionar_lookups_esistafe()`](https://moz-gpe.github.io/easystafe/reference/adicionar_lookups_esistafe.md).

## Usage

``` r
config_para_duckdb(df)
```

## Arguments

- df:

  A dataframe produced by
  [`processar_extracto_esistafe()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_esistafe.md)
  followed by
  [`adicionar_lookups_esistafe()`](https://moz-gpe.github.io/easystafe/reference/adicionar_lookups_esistafe.md).
  Must contain the column `data_tipo` and the standard budget identifier
  and lookup columns.

## Value

A tibble filtered to `data_tipo == "Valor"` rows, containing the
following columns when present: `reporte_tipo`, `periodo`, `ugb_id`,
`funcao`, `funcao_nivel`, `programa`, `fr`, `ced`, `ced_nome`,
`ced_nivel`, `ced_2_nome`, `ced_3_nome`, `provincia`, `distrito`,
`ambito`, `nivel_da_instituicao`, `descricao`, `programa_tipo`, and the
11 numeric budget execution columns from `dotacao_inicial` to
`liq_ad_fundos_via_directa_lafvd`.

## Details

Column selection uses
[`dplyr::any_of()`](https://tidyselect.r-lib.org/reference/all_of.html)
so the function does not error when optional columns are absent – for
example `reporte_tipo`, which is only present when
`include_file_metadata = TRUE` in
[`processar_extracto_esistafe()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_esistafe.md).

## Examples

``` r
if (FALSE) { # \dontrun{
lookups <- carregar_lookups_esistafe("Data/lookups.xlsx")

df <- processar_extracto_esistafe(
  source_path   = "Data/202602/",
  df_ugb_lookup = lookups$ugb
) |>
  adicionar_lookups_esistafe(lookups) |>
  config_para_duckdb()
} # }
```
