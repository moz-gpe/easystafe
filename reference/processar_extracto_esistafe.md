# Processar extractos de exportacao e-SISTAFE

Carrega, limpa e processa um ou mais ficheiros de exportacao do
e-SISTAFE no formato Excel, aplicando uma sequencia de transformacoes
que inclui renomeacao de colunas, filtragem de UGBs de educacao,
classificacao e subtraccao hierarquica de codigos CED, e restauracao da
estrutura original de colunas. Devolve um dataframe final desduplicado e
pronto para analise.

## Usage

``` r
processar_extracto_esistafe(
  source_path = "Data/",
  df_ugb_lookup,
  include_pattern = "DemonstrativoConsolidado",
  include_percent = TRUE,
  include_file_metadata = TRUE,
  include_metrica = TRUE,
  quiet = TRUE
)
```

## Arguments

- source_path:

  A character vector with one or more file paths to e-SISTAFE export
  files in `.xlsx` format.

- df_ugb_lookup:

  A dataframe with the education UGB reference table. Must contain at
  least the column `codigo_ugb` with 9-character UGB codes (e.g.
  `"50B105761"`). Only rows whose `ugb_id` matches a value in
  `codigo_ugb` are retained during processing.

- include_pattern:

  A character string with a regex pattern used to retain only files
  whose `file_name` matches the pattern. Defaults to
  `"DemonstrativoConsolidado"`, which retains only consolidated
  statement files. Set to `NULL` to skip filtering and process all
  loaded files regardless of name.

- include_percent:

  Logical. If `TRUE` (default), the `percent` columns are included in
  the output (filled with `NA`). If `FALSE`, those columns are removed
  from the final result.

- include_file_metadata:

  Logical. If `TRUE` (default), metadata extracted from the file name
  (report type, year, month, dates) are added to the dataframe
  immediately after the `file_name` column. If `FALSE`, metadata are not
  added and the `file_name` column is also removed from the final
  result.

- include_metrica:

  Logical. If `TRUE` (default), rows of type `"Metrica"` are excluded
  from the final output, retaining only `"Valor"` rows after
  hierarchical subtraction. If `TRUE`, `"Metrica"` rows are reincluded
  in the final output after processing, useful for comparisons and
  validation. The `data_tipo` column is always included in the output
  regardless of this parameter.

- quiet:

  Logical. If `TRUE` (default), progress messages are suppressed. If
  `FALSE`, a message is emitted for each processing step. Regardless of
  this parameter, a final message with the number of processed files is
  always emitted.

## Value

Um tibble com uma linha por entrada CED deduplificada, contendo as
colunas originais do extracto e-SISTAFE apos limpeza e subtraccao
hierarquica. A coluna `data_tipo` esta sempre presente e posicionada
imediatamente antes de `ugb`. As colunas de percentagem sao sempre
incluidas na estrutura original (preenchidas com `NA`) salvo se
`include_percent = FALSE`.

## Details

O processamento segue as seguintes etapas principais:

1.  Carregamento e combinacao de todos os ficheiros em `source_path`.

2.  Adicao opcional de metadados via
    [`extrair_meta_extracto()`](https://moz-gpe.github.io/easystafe/reference/extrair_meta_extracto.md).

3.  Limpeza de nomes de colunas com
    [`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html).

4.  Remocao de colunas `percent`.

5.  Conversao de colunas numericas e extraccao do codigo `ugb_id`.

6.  Filtragem de UGBs validos de educacao a partir de `df_ugb_lookup`.

7.  Remocao de linhas com CED e campos-chave em branco.

8.  Classificacao de grupos CED (A, B, C, D) e remocao do grupo D.

9.  Criacao de variaveis hierarquicas auxiliares.

10. Separacao de linhas `"Metrica"` e `"Valor"` antes da subtraccao
    hierarquica.

11. Subtraccao hierarquica em tres passos para eliminar dupla contagem
    (aplicada apenas a linhas `"Valor"`):

    - Passo 1: Subtrair grupo A do grupo B (dentro de `ced_b4`).

    - Passo 2: Subtrair grupo B ajustado do grupo C (dentro de
      `ced_b3`).

    - Passo 3: Subtrair grupo A directamente do grupo C (dentro de
      `ced_b3`).

12. Reinclusao opcional das linhas `"Metrica"` via `include_metrica`.

13. Seleccao das colunas finais a partir de um vector explicito,
    garantindo que `data_tipo` e sempre incluido antes de `ugb`.

## Examples

``` r
if (FALSE) { # \dontrun{
ugb_lookup    <- readxl::read_excel("Data/ugb/Codigos de UGBs.xlsx", sheet = "UGBS")
path_files <- list.files("Data/", pattern = "\\.xlsx$", full.names = TRUE)

# Padrao -- com metadados e colunas percent, sem linhas Metrica
df <- processar_extracto_esistafe(
  source_path = path_files,
  df_ugb_lookup  = ugb_lookup
)

# Sem metadados, sem colunas percent
df <- processar_extracto_esistafe(
  source_path     = path_files,
  df_ugb_lookup      = ugb_lookup,
  include_percent = FALSE,
  include_file_metadata    = FALSE
)

# Com linhas Metrica incluidas para comparacao
df <- processar_extracto_esistafe(
  source_path      = path_files,
  df_ugb_lookup       = ugb_lookup,
  include_metrica  = TRUE
)

# Com mensagens de progresso
df <- processar_extracto_esistafe(
  source_path = path_files,
  df_ugb_lookup  = ugb_lookup,
  quiet       = FALSE
)
} # }
```
