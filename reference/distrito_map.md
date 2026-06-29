# District name mapping table for Mozambique

Maps variant district name spellings found in e-SISTAFE exports to
canonical official names and integer keys. Includes encoding artefacts
(e.g. mojibake strings) as additional source variants so that raw data
can be reliably matched regardless of character-encoding provenance.

## Usage

``` r
distrito_map
```

## Format

A tibble with 210 rows and 3 columns:

- distrito_fonte:

  `character`. District name as it appears in the source data (may
  include encoding errors, spelling variants, or alternative
  administrative labels).

- distrito_oficial:

  `character`. Canonical official district name (with correct
  diacritics).

- distrito_id:

  `integer`. Numeric identifier for the district. The first two digits
  correspond to `provincia_id` in
  [`provincia_map`](https://moz-gpe.github.io/easystafe/reference/provincia_map.md).
