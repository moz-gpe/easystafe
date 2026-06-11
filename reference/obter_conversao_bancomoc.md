# Download and parse Banco de Mocambique exchange rate PDFs

Scrapes PDF links from the Banco de Mocambique website, downloads any
new files to `out_dir`, parses all files in that directory, and returns
a combined tidy tibble.

## Usage

``` r
obter_conversao_bancomoc(
  out_dir = "Data/pdfs_bancomoc",
  url_path = "/pt/tabelas-de-taxas-de-cambio-de-referencia-diarias/2026-2025/",
  keep_countries = c("Estados Unidos", "União Europeia"),
  wide = TRUE
)
```

## Arguments

- out_dir:

  Directory where PDFs are saved. Created if it does not exist. Defaults
  to `"Data/pdfs_bancomoc"`.

- url_path:

  URL path on <https://www.bancomoc.mz> for the page listing exchange
  rate PDFs.

- keep_countries:

  Character vector of country names to retain. Pass `character(0)` to
  return all countries. Defaults to
  `c("Estados Unidos", "Uni\u00e3o Europeia")`.

- wide:

  Logical. If `TRUE` (default), returns a daily wide-format table with
  one row per calendar date and one `taxa_*` column per currency (e.g.
  `taxa_dolar`, `taxa_euro`), with gaps filled by the preceding
  trading-day rate (LOCF). If `FALSE`, returns the raw long-format
  tibble.

## Value

When `wide = FALSE`: a tibble with columns `date`, `country`,
`currency`, `compra`, `venda`, `media`, and `per_1000`. When
`wide = TRUE`: a tibble with `date` and one `taxa_*` column per currency
present in the data.
