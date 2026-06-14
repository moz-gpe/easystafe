# LTabela de referência que associa os nomes dos ficheiros de origem da 'Razão Contabilística' às respetivas descrições

A reference table that maps the PDF filenames produced by the e-SISTAFE
razao contabilistica and ABSA bank extract exports to human-readable
descriptions and province names. Used to enrich the output of
[`processar_extracto_razao_c`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_razao_c.md)
and
[`processar_extracto_absa`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_absa.md)
via a `left_join` on `source_file`.

## Usage

``` r
lookup_razao
```

## Format

A tibble with 32 rows and 3 columns:

- source_file:

  `character`. The PDF filename as it appears in the `source_file`
  column of the processed output (e.g. `"MAPUTO PROVINCIA.pdf"`).

- descricao:

  `character`. Human-readable description of the account or province
  corresponding to the file.

- provincia:

  `character`. Province name, or `NA` for central/national accounts
  (CUT, ABSA, FOREX).
