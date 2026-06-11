# Parse a Banco de Mocambique exchange rate PDF into a tidy tibble

Parse a Banco de Mocambique exchange rate PDF into a tidy tibble

## Usage

``` r
parse_bancomoc_pdf(filepath)
```

## Arguments

- filepath:

  Path to a PDF file downloaded from bancomoc.mz. The filename must
  contain an 8-digit date string in `DDMMYYYY` format.

## Value

A tibble with columns `date`, `country`, `currency`, `compra`, `venda`,
`media`, and `per_1000`.
