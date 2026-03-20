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
  source_path,
  ugb_lookup,
  include_percent = TRUE,
  include_meta = TRUE,
  quiet = TRUE
)
```

## Arguments

- source_path:

  Um vector de caracteres com um ou mais caminhos para ficheiros de
  exportacao e-SISTAFE no formato `.xlsx`.

- ugb_lookup:

  Um dataframe com a tabela de referencia de UGBs de educacao, carregado
  a partir do ficheiro Excel de codigos UGB (folha `"UGBS"`). Deve
  conter uma coluna `ugb_3` com os nomes completos dos UGBs validos.

- include_percent:

  Logico. Se `TRUE` (padrao), as colunas `percent` sao incluidas no
  output (preenchidas com `NA`). Se `FALSE`, essas colunas sao removidas
  do resultado final.

- include_meta:

  Logico. Se `TRUE` (padrao), os metadados extraidos do nome do ficheiro
  (tipo de relatorio, ano, mes, datas) sao adicionados ao dataframe
  imediatamente apos a coluna `file_name`. Se `FALSE`, os metadados nao
  sao adicionados e a coluna `file_name` e tambem removida do resultado
  final.

- quiet:

  Logico. Se `TRUE` (padrao), as mensagens de progresso sao suprimidas.
  Se `FALSE`, e emitida uma mensagem por cada etapa do processamento.
  Independentemente deste parametro, e sempre emitida uma mensagem final
  com o numero de ficheiros processados.

## Value

Um tibble com uma linha por entrada CED deduplificada, contendo as
colunas originais do extracto e-SISTAFE apos limpeza e subtraccao
hierarquica. As colunas de percentagem sao sempre incluidas na estrutura
original (preenchidas com `NA`) salvo se `include_percent = FALSE`.

## Details

O processamento segue as seguintes etapas principais:

1.  Carregamento e combinacao de todos os ficheiros em `source_path`.

2.  Adicao opcional de metadados via
    [`extrair_meta_extracto()`](https://moz-gpe.github.io/easystafe/reference/extrair_meta_extracto.md).

3.  Limpeza de nomes de colunas com
    [`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html).

4.  Remocao de colunas `percent`.

5.  Conversao de colunas numericas e extraccao do codigo `ugb_id`.

6.  Filtragem de UGBs validos de educacao a partir de `ugb_lookup`.

7.  Remocao de linhas com CED e campos-chave em branco.

8.  Classificacao de grupos CED (A, B, C, D) e remocao do grupo D.

9.  Criacao de variaveis hierarquicas auxiliares.

10. Subtraccao hierarquica em tres passos para eliminar dupla contagem:

    - Passo 1: Subtrair grupo A do grupo B (dentro de `ced_b4`).

    - Passo 2: Subtrair grupo B ajustado do grupo C (dentro de
      `ced_b3`).

    - Passo 3: Subtrair grupo A directamente do grupo C (dentro de
      `ced_b3`).

11. Restauracao da estrutura original de colunas.

## Examples

``` r
if (FALSE) { # \dontrun{
ugb_raw    <- readxl::read_excel("Data/ugb/Codigos de UGBs.xlsx", sheet = "UGBS")
path_files <- list.files("Data/", pattern = "\\.xlsx$", full.names = TRUE)

# Padrao -- com metadados e colunas percent
df <- processar_extracto_sistafe(
  source_path = path_files,
  ugb_lookup  = ugb_raw
)

# Sem metadados, sem colunas percent
df <- processar_extracto_sistafe(
  source_path     = path_files,
  ugb_lookup      = ugb_raw,
  include_percent = FALSE,
  include_meta    = FALSE
)

# Com mensagens de progresso
df <- processar_extracto_sistafe(
  source_path = path_files,
  ugb_lookup  = ugb_raw,
  quiet       = FALSE
)
} # }
```
