# Recodificar variaveis padrao de exportacoes e-SISTAFE

A wrapper function that detects the presence of known e-SISTAFE columns
and applies standard recoding transformations to each one found. Columns
not present in the dataframe are silently skipped.

Currently handles:

- `distrito`: applies title case with lowercase prepositions (de, da,
  do, dos, das)

- `programa`: recodes to standardised `programa_tipo` categories via
  [`recode_programa_tipo()`](https://moz-gpe.github.io/easystafe/reference/recode_programa_tipo.md)

## Usage

``` r
recodificar_esistafe_vars(df)
```

## Arguments

- df:

  A dataframe containing one or more standard e-SISTAFE columns.

## Value

The input dataframe with transformations applied to detected columns. A
`programa_tipo` column is added if `programa` is present.

## See also

[`recode_programa_tipo`](https://moz-gpe.github.io/easystafe/reference/recode_programa_tipo.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  df_clean <- df |>
    dplyr::left_join(ugb_lookup, by = dplyr::join_by(ugb_id == codigo_ugb)) |>
    recodificar_esistafe_vars()
} # }
```
