# Processar extractos do razao contabilistico do e-SISTAFE a partir de ficheiros PDF

Le todos os ficheiros PDF de uma pasta, extrai as transaccoes e saldos
de cada extracto da razao contabilistico, e combina os resultados num
unico tibble. Ficheiros com formato FOREX (USD/EUR) sao excluidos por
padrao.

## Usage

``` r
processar_extracto_razao_c(
  source_path,
  exclude_pattern = "CAMBIO|FOREX|EXTRACTO|DemonstrativoConsolidado",
  recursive = FALSE,
  quiet = TRUE
)
```

## Arguments

- source_path:

  Caractere. Caminho para a pasta que contem os ficheiros PDF a
  processar. Obrigatorio.

- exclude_pattern:

  Caractere. Expressao regular para excluir ficheiros pelo nome. Por
  padrao exclui ficheiros FOREX:
  `"CAMBIO|FOREX|EXTRACTO|DemonstrativoConsolidado"`. Para nao excluir
  nenhum ficheiro, usar `NULL`.

- recursive:

  Logico. Se `TRUE`, a pesquisa de ficheiros PDF inclui subpastas. Por
  padrao `FALSE`.

- quiet:

  Logico. Se `TRUE` (padrao), suprime as mensagens emitidas por ficheiro
  durante o processamento (por exemplo, quando um PDF nao contem
  transaccoes). Se `FALSE`, as mensagens sao apresentadas.

## Value

Um tibble com uma linha por registo (movimentos, saldo inicial e saldo
final) de todos os PDFs processados. Aplique
[`adicionar_conversao_moeda`](https://moz-gpe.github.io/easystafe/reference/adicionar_conversao_moeda.md)
ao resultado para adicionar as colunas de conversao de moeda com taxas
diarias.

## Examples

``` r
if (FALSE) { # \dontrun{
df_razao <- processar_extracto_razao_c(
  source_path = path_folder_source
)
} # }
```
