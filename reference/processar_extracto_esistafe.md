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
  correct_negatives = TRUE,
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
  (report type, dates) are added to the dataframe immediately after the
  `file_name` column. If `FALSE`, metadata are not added and the
  `file_name` column is also removed from the final result.

- include_metrica:

  Logical. If `TRUE` (default), rows of type `"Metrica"` are reincluded
  in the final output after hierarchical subtraction, useful for
  comparisons and validation. If `FALSE`, only `"Valor"` rows are
  retained in the final output. The `data_tipo` column is always
  included in the output regardless of this parameter.

- correct_negatives:

  Logical. If `TRUE` (default), negative values in the 11 main numeric
  columns are detected and corrected: they are set to zero in the
  original `"Valor"` rows, audit copies of the affected rows are
  appended with `data_tipo == "Corregido"`, and two flag columns are
  added – `valor_corregido` (`1L` for any row whose `ugb_funcao_prog_fr`
  contained a negative of any magnitude) and `valor_negativo` (`1L` only
  where the absolute value of the negative was \\\geq 1\\). If `FALSE`,
  this entire block is skipped: negative values are left as-is, no
  `"Corregido"` rows are added, and the two flag columns are not
  created.

- quiet:

  Logical. If `TRUE` (default), progress messages are suppressed. If
  `FALSE`, a message is emitted for each processing step. Regardless of
  this parameter, a final message with the number of processed files is
  always emitted.

## Value

Um tibble com uma linha por entrada CED deduplificada, contendo as
colunas originais do extracto e-SISTAFE apos limpeza e subtraccao
hierarquica. A coluna `data_tipo` esta sempre presente e posicionada
imediatamente antes de `ugb`. Tres colunas hierarquicas derivadas de
`ced` sao sempre incluidas imediatamente a seguir a `ced`: `ced_2`
(primeiros 2 digitos com sufixo `"0000"`), `ced_3` (primeiros 3 digitos)
e `ced_4` (primeiros 4 digitos); todas sao `NA` nas linhas `"Metrica"`.
As colunas de percentagem sao sempre incluidas na estrutura original
(preenchidas com `NA`) salvo se `include_percent = FALSE`. A coluna
`pasta_fonte` contem o nome da pasta imediata de onde os dados foram
carregados. As colunas `ano` (numerico) e `mes` (caracter em portugues)
sao derivadas do nome da pasta quando este segue o formato `YYYYMM`;
caso contrario sao preenchidas com `NA` e e emitido um aviso.

## Details

O processamento segue as seguintes etapas principais:

1.  Carregamento e combinacao de todos os ficheiros em `source_path`.

2.  Adicao de `pasta_fonte`, `ano` e `mes` derivados do nome da pasta de
    origem. Se o nome da pasta nao seguir o formato `YYYYMM`, `ano` e
    `mes` sao `NA` e e emitido um
    [`warning()`](https://rdrr.io/r/base/warning.html).

3.  Adicao opcional de metadados via
    [`extrair_meta_extracto()`](https://moz-gpe.github.io/easystafe/reference/extrair_meta_extracto.md)
    (reporte_tipo, data_reporte, data_extraido – sem ano nem mes).

4.  Limpeza de nomes de colunas com
    [`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html).

5.  Remocao de colunas `percent`.

6.  Conversao de colunas numericas e extraccao do codigo `ugb_id`.

7.  Filtragem de UGBs validos de educacao a partir de `df_ugb_lookup`.

8.  Remocao de linhas com CED e campos-chave em branco.

9.  Classificacao de grupos CED (A, B, C, D) e remocao do grupo D.

10. Criacao de variaveis hierarquicas: `ced_4` (primeiros 4 digitos de
    `ced`), `ced_3` (primeiros 3 digitos), `ced_2` (primeiros 2 digitos
    com sufixo `"0000"`), e chaves compostas auxiliares `id_ced_b4` e
    `id_ced_b3` (usadas internamente e removidas no output final).

11. Separacao de linhas `"Metrica"` e `"Valor"` antes da subtraccao
    hierarquica.

12. Subtraccao hierarquica em tres passos para eliminar dupla contagem
    (aplicada apenas a linhas `"Valor"`):

    - Passo 1: Subtrair grupo A do grupo B (dentro de `ced_4`).

    - Passo 2: Subtrair grupo B ajustado do grupo C (dentro de `ced_3`).

    - Passo 3: Subtrair grupo A directamente do grupo C (dentro de
      `ced_3`).

13. Reinclusao opcional das linhas `"Metrica"` via `include_metrica`.

14. Seleccao das colunas finais a partir de um vector explicito,
    garantindo que `data_tipo` e sempre incluido antes de `ugb`.

15. Deteccao e correccao de valores negativos (apenas quando
    `correct_negatives = TRUE`):

    - Calculo do denominador: soma total das colunas numericas em linhas
      `"Valor"` antes de qualquer correccao.

    - Identificacao dos `ugb_funcao_prog_fr` distintos com pelo menos um
      valor negativo em qualquer coluna numerica.

    - Criacao de uma copia dessas linhas com `data_tipo` recodificado
      para `"Corregido"`, preservando os valores negativos originais
      como registo de auditoria.

    - Substituicao dos valores negativos por zero nas linhas originais
      `"Valor"` (cirurgicamente, coluna a coluna).

    - Anexacao da copia `"Corregido"` ao dataset final.

    - Criacao de `valor_corregido`: `1L` para todas as linhas cujo
      `ugb_funcao_prog_fr` continha pelo menos um valor negativo
      (qualquer magnitude); `0L` caso contrario.

    - Criacao de `valor_negativo`: `1L` apenas para linhas onde pelo
      menos uma coluna numerica tinha valor \\\leq -1\\ (valor absoluto
      \\\geq 1\\); `0L` caso contrario.

    - Emissao de mensagem de resumo com o numero de grupos corrigidos, a
      soma absoluta dos valores corrigidos, e a respectiva percentagem
      da soma total `"Valor"`.

## Examples

``` r
if (FALSE) { # \dontrun{
ugb_lookup <- readxl::read_excel("Data/ugb/Codigos de UGBs.xlsx", sheet = "UGBS")

# Padrao -- pasta com formato YYYYMM, correccao de negativos activa
df <- processar_extracto_esistafe(
  source_path   = "Data/202602/",
  df_ugb_lookup = ugb_lookup
)

# Sem correccao de negativos
df <- processar_extracto_esistafe(
  source_path        = "Data/202602/",
  df_ugb_lookup      = ugb_lookup,
  correct_negatives  = FALSE
)

# Sem metadados, sem colunas percent
df <- processar_extracto_esistafe(
  source_path           = "Data/202602/",
  df_ugb_lookup         = ugb_lookup,
  include_percent       = FALSE,
  include_file_metadata = FALSE
)

# Com mensagens de progresso
df <- processar_extracto_esistafe(
  source_path   = "Data/202602/",
  df_ugb_lookup = ugb_lookup,
  quiet         = FALSE
)
} # }
```
