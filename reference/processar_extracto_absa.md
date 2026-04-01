# Parse an ABSA Bank Statement PDF into a tidy dataframe

Reads an ABSA Bank account statement PDF and returns a tibble matching
the `df_razao` schema used in the `easystafe` pipeline. Line
reconstruction uses word-level coordinate data from
[`pdftools::pdf_data()`](https://docs.ropensci.org/pdftools//reference/pdftools.html)
rather than
[`pdftools::pdf_text()`](https://docs.ropensci.org/pdftools//reference/pdftools.html),
which silently truncates ABSA statement pages.

## Usage

``` r
processar_extracto_absa(pdf_path, y_tolerance = 2, verbose = TRUE)
```

## Arguments

- pdf_path:

  `character(1)`. Full or relative path to the ABSA statement PDF file.

- y_tolerance:

  `numeric(1)`. Vertical tolerance (in PDF points) used when grouping
  words onto the same line during coordinate-based reconstruction. The
  default of `2` works for standard ABSA statements. Increase if words
  from the same row are being split; decrease if adjacent rows are being
  merged. Default: `2`.

- verbose:

  `logical(1)`. If `TRUE`, prints a summary message with row count,
  totals and calculated closing balance after parsing. Default: `TRUE`.

## Value

A tibble with 12 columns:

- source_file:

  `character`. Basename of the source PDF file.

- unidade_gestao:

  `character`. Always `NA` — to be populated downstream.

- data:

  `Date`. Transaction date. The dummy opening-balance date
  (`01/01/1900`) is remapped to the first day of the statement period.

- ano:

  `integer`. Year extracted from `data`.

- mes:

  `character`. Full month name in English extracted from `data` (e.g.
  `"February"`).

- tipo:

  `character`. One of `"SALDO_INICIAL"`, `"MOVIMENTO"`, or
  `"SALDO_FINAL"`.

- codigo_documento:

  `character`. Reference number extracted from the statement, where
  present. `NA` otherwise.

- valor_lancamento:

  `double`. Signed transaction amount: positive for credits, negative
  for debits. `NA` for `SALDO_INICIAL` and `SALDO_FINAL` rows.

- dc1:

  `character`. Debit/credit indicator for the transaction amount: `"C"`
  (credit), `"D"` (debit), or `NA` for balance rows.

- saldo_atual:

  `double`. Running account balance after the transaction.

- dc2:

  `character`. Debit/credit indicator for the running balance. Always
  `"D"` for this account type.

- saldo_inicial_fim:

  `double`. Opening balance for `SALDO_INICIAL` rows; calculated closing
  balance (opening + credits - debits) for `SALDO_FINAL` rows; `NA` for
  `MOVIMENTO` rows.

## Details

The ABSA statement PDF layout has two known quirks that this function
handles:

1.  **Page truncation**:
    [`pdftools::pdf_text()`](https://docs.ropensci.org/pdftools//reference/pdftools.html)
    silently truncates the first page of ABSA statements. This function
    uses
    [`pdftools::pdf_data()`](https://docs.ropensci.org/pdftools//reference/pdftools.html)
    instead, reconstructing lines from word-level x/y coordinates.

2.  **Continuation lines**: Long descriptions and reference numbers wrap
    onto a second line with no leading date. These are detected and
    appended to their parent transaction row before parsing.

The closing balance row (`SALDO_FINAL`) is appended programmatically and
is not extracted from the PDF footer. Its `saldo_inicial_fim` value is
calculated as: `saldo_abertura + sum(credits) - sum(debits)`.

The `data` for the `SALDO_FINAL` row is set to the last calendar day of
the statement month, derived from the period end date in the PDF header.

## Examples

``` r
if (FALSE) { # \dontrun{
df_absa <- processar_extracto_absa("Data/razao_cont/2026_02/outro/EXTRACTO ABSA BANK MT.pdf")
glimpse(df_absa)

# Bind with other razao dataframes
df_razao <- bind_rows(df_razao, df_absa)
} # }
```
