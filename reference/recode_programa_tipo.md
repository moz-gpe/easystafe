# Recode programa column to programa_tipo

Adds a `programa_tipo` column to a dataframe by matching patterns in the
`programa` column against known e-SISTAFE programme descriptions.
Unmatched values are assigned `"Outro"`.

## Usage

``` r
recode_programa_tipo(df)
```

## Arguments

- df:

  A dataframe containing a column named `programa`.

## Value

The input dataframe with an additional column `programa_tipo`
(character).

## Examples

``` r
if (FALSE) { # \dontrun{
  df_clean <- df |> recode_programa_tipo()
} # }
```
