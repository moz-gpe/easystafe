# Gravar extracto da razao contabilistico processado em Parquet e Excel

Grava um dataframe processado por
[`processar_extracto_razao_c()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_razao_c.md)
em dois formatos (Parquet e Excel), construindo automaticamente o nome
dos ficheiros a partir de todos os anos presentes na coluna `ano`. Cria
a pasta de destino se nao existir.

## Usage

``` r
gravar_extracto_razao_c(df, output_folder = "Dataout", quiet = TRUE)
```

## Arguments

- df:

  Um tibble processado por
  [`processar_extracto_razao_c()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_razao_c.md).
  Deve conter pelo menos a coluna `ano`.

- output_folder:

  Caractere. Caminho para a pasta de destino onde os ficheiros serao
  gravados. Por padrao `"Dataout"`. A pasta e criada automaticamente se
  nao existir.

- quiet:

  Logico. Se `TRUE` (padrao), as mensagens de progresso sao suprimidas.
  Se `FALSE`, sao emitidas mensagens sobre a criacao da pasta e os
  caminhos dos ficheiros gravados.

## Value

Um named list com os caminhos completos dos ficheiros gravados
(`parquet` e `excel`), retornado de forma invisivel.

## Details

O nome dos ficheiros e construido automaticamente no formato:
`RazaoCont_<YYYY-YYYY>_<YYYY-MM-DD>.parquet` e
`RazaoCont_<YYYY-YYYY>_<YYYY-MM-DD>.xlsx`, onde os anos sao todos os
valores unicos presentes na coluna `ano`, ordenados e separados por
hifen.

Por exemplo, dados abrangendo 2025 e 2026 produzem:
`RazaoCont_2025-2026_2026-02-24.parquet` e
`RazaoCont_2025-2026_2026-02-24.xlsx`

Se um ficheiro com o mesmo nome ja existir, o utilizador e avisado antes
de ser substituido.

## Examples

``` r
if (FALSE) { # \dontrun{
# Gravar com pasta padrao
gravar_extracto_razao_c(df_razao)

# Gravar numa pasta personalizada
gravar_extracto_razao_c(df_razao, output_folder = "Dataout/subpasta")

# Gravar com mensagens de progresso
gravar_extracto_razao_c(df_razao, quiet = FALSE)

# Capturar os caminhos dos ficheiros gravados
paths <- gravar_extracto_razao_c(df_razao, quiet = FALSE)
paths$parquet
paths$excel
} # }
```
