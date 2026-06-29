# Province name mapping table for Mozambique

Maps variant province name spellings and abbreviations found in
e-SISTAFE exports to canonical official names and integer keys. Used to
normalise the `provincia` column before joining to other dimensional
tables.

## Usage

``` r
provincia_map
```

## Format

A tibble with 15 rows and 3 columns:

- provincia_fonte:

  `character`. Province name as it appears in the source data (may
  include spelling variants, missing accents, or abbreviations).

- provincia_oficial:

  `character`. Canonical official province name (with correct
  diacritics).

- provincia_id:

  `integer`. Numeric identifier for the province (1–11), consistent with
  the Mozambican administrative numbering scheme.
