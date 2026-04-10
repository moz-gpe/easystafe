# Verificar completude de UGBs no extracto e-SISTAFE

Compara a lista de UGBs de educacao de um dataframe de referencia com os
dados processados do e-SISTAFE, verificando se cada UGB possui valores
registados para as variaveis financeiras chave. Os resultados sao
emitidos como mensagens no console.

## Usage

``` r
verificar_ugb_completude(df_esistafe, lookup_ugb, quiet = TRUE)
```

## Arguments

- df_esistafe:

  A dataframe of processed e-SISTAFE data, as returned by
  [`processar_extracto_esistafe()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_esistafe.md).
  Must contain at least the columns `ugb_id`, `reporte_tipo`,
  `dotacao_actualizada_da`, and `ad_fundos_desp_paga_vd_afdp`.

- lookup_ugb:

  A dataframe with the education UGB reference table. Must contain at
  least the column `codigo_ugb` with 9-character UGB codes (e.g.
  `"50B105761"`).

- quiet:

  Logical. If `TRUE` (default), the completude summary message is
  suppressed. If `FALSE`, a message is emitted to the console listing
  total UGBs and any missing values for each financial variable.

## Value

Invisibly returns `NULL`. Called for its side effect of printing a
completude summary message to the console.

## Details

The function filters `df_esistafe` to `reporte_tipo == "Funcionamento"`
and checks two financial variables for each UGB in `lookup_ugb`:

- `dotacao_actualizada_da`: dotacao actualizada (DA).

- `ad_fundos_desp_paga_vd_afdp`: despesa paga via directa e atraves de
  adiantamento de fundos (AFDP).

A UGB is considered complete for a given variable if at least one row
exists with a non-missing value greater than zero. UGBs failing either
check are listed by code in the console message.

## Examples

``` r
if (FALSE) { # \dontrun{
ugb_lookup <- readxl::read_excel("Data/ugb/Codigos de UGBs.xlsx", sheet = "UGBS")

df <- processar_extracto_esistafe(
  source_path   = "Data/",
  df_ugb_lookup = ugb_lookup
)

# Com mensagem de completude
verificar_ugb_completude(df, ugb_lookup, quiet = FALSE)
} # }
```
