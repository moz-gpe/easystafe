# Gravar extracto processado do e-SISTAFE em Parquet e Excel

Grava um dataframe processado do e-SISTAFE em dois formatos (Parquet e
Excel), construindo automaticamente o nome dos ficheiros a partir de
todos os anos presentes nos dados. Cria a pasta de destino se nao
existir.

## Usage

``` r
gravar_esistafe(df, output_folder = "Dataout/", quiet = TRUE)
```

## Arguments

- df:

  Um dataframe processado contendo pelo menos a coluna `ano`.

- output_folder:

  Caractere. Caminho para a pasta de destino. Por padrao `"Dataout/"`. A
  pasta e criada automaticamente se nao existir.

- quiet:

  Logico. Se `TRUE` (padrao), as mensagens de progresso sao suprimidas.
  Se `FALSE`, sao emitidas mensagens sobre o progresso.

## Value

Um named list com os caminhos completos dos ficheiros gravados
(`parquet` e `excel`), retornado de forma invisivel.

## Details

O nome dos ficheiros e construido automaticamente no formato:
`e-SISTAFE_<YYYY-YYYY>_<YYYY-MM-DD>.parquet` e
`e-SISTAFE_<YYYY-YYYY>_<YYYY-MM-DD>.xlsx` onde os anos sao todos os
valores unicos presentes na coluna `ano`, ordenados e separados por
hifen.

Por exemplo, dados abrangendo 2025 e 2026 produzem:
`e-SISTAFE_2025-2026_2026-02-24.parquet` e
`e-SISTAFE_2025-2026_2026-02-24.xlsx`

Se um ficheiro com o mesmo nome ja existir, o utilizador e avisado antes
de ser substituido.

## Examples

``` r
if (FALSE) { # \dontrun{
# Gravar com pasta padrao
gravar_esistafe(df_esistafe)

# Gravar numa pasta personalizada
gravar_esistafe(df_esistafe, output_folder = "Data/final")

# Gravar com mensagens de progresso
gravar_esistafe(df_esistafe, quiet = FALSE)

# Capturar os caminhos dos ficheiros gravados
paths <- gravar_esistafe(df_esistafe, quiet = FALSE)
paths$parquet
paths$excel
} # }
```
