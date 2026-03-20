# Processar extractos de exportação e-SISTAFE

Carrega, limpa e processa um ou mais ficheiros de exportação do
e-SISTAFE no formato Excel, aplicando uma sequência de transformações
que inclui renomeação de colunas, filtragem de UGBs de educação,
classificação e subtracção hierárquica de códigos CED, e restauração da
estrutura original de colunas. Devolve um dataframe final desduplicado e
pronto para análise.

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
  exportação e-SISTAFE no formato `.xlsx`.

- ugb_lookup:

  Um dataframe com a tabela de referência de UGBs de educação, carregado
  a partir do ficheiro Excel de códigos UGB (folha `"UGBS"`). Deve
  conter uma coluna `ugb_3` com os nomes completos dos UGBs válidos.

- include_percent:

  Lógico. Se `TRUE` (padrão), as colunas `percent` são incluídas no
  output (preenchidas com `NA`). Se `FALSE`, essas colunas são removidas
  do resultado final.

- include_meta:

  Lógico. Se `TRUE` (padrão), os metadados extraídos do nome do ficheiro
  (tipo de relatório, ano, mês, datas) são adicionados ao dataframe
  imediatamente após a coluna `file_name`. Se `FALSE`, os metadados não
  são adicionados e a coluna `file_name` é também removida do resultado
  final.

- quiet:

  Lógico. Se `TRUE` (padrão), as mensagens de progresso são suprimidas.
  Se `FALSE`, é emitida uma mensagem por cada etapa do processamento.
  Independentemente deste parâmetro, é sempre emitida uma mensagem final
  com o número de ficheiros processados.

## Value

Um tibble com uma linha por entrada CED deduplificada, contendo as
colunas originais do extracto e-SISTAFE após limpeza e subtracção
hierárquica. As colunas de percentagem são sempre incluídas na estrutura
original (preenchidas com `NA`) salvo se `include_percent = FALSE`.

## Details

O processamento segue as seguintes etapas principais:

1.  Carregamento e combinação de todos os ficheiros em `source_path`.

2.  Adição opcional de metadados via
    [`extrair_meta_extracto()`](https://moz-gpe.github.io/easystafe/reference/extrair_meta_extracto.md).

3.  Limpeza de nomes de colunas com
    [`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html).

4.  Remoção de colunas `percent`.

5.  Conversão de colunas numéricas e extracção do código `ugb_id`.

6.  Filtragem de UGBs válidos de educação a partir de `ugb_lookup`.

7.  Remoção de linhas com CED e campos-chave em branco.

8.  Classificação de grupos CED (A, B, C, D) e remoção do grupo D.

9.  Criação de variáveis hierárquicas auxiliares.

10. Subtracção hierárquica em três passos para eliminar dupla contagem:

    - Passo 1: Subtrair grupo A do grupo B (dentro de `ced_b4`).

    - Passo 2: Subtrair grupo B ajustado do grupo C (dentro de
      `ced_b3`).

    - Passo 3: Subtrair grupo A directamente do grupo C (dentro de
      `ced_b3`).

11. Restauração da estrutura original de colunas.

## Examples

``` r
if (FALSE) { # \dontrun{
ugb_raw    <- readxl::read_excel("Data/ugb/Codigos de UGBs.xlsx", sheet = "UGBS")
path_files <- list.files("Data/", pattern = "\\.xlsx$", full.names = TRUE)

# Padrão — com metadados e colunas percent
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
