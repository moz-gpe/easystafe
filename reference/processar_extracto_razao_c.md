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
  quiet = TRUE,
  usd_to_mt = 63.86,
  eur_to_mt = 70,
  eur_to_usd = 1.1
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

- usd_to_mt:

  Numerico. Taxa de cambio USD para MZN. Passado a
  [`aplicar_conversao_moeda`](https://moz-gpe.github.io/easystafe/reference/aplicar_conversao_moeda.md).
  Por padrao `63.86` (valor indicativo; actualizar conforme necessario).

- eur_to_mt:

  Numerico. Taxa de cambio EUR para MZN. Passado a
  [`aplicar_conversao_moeda`](https://moz-gpe.github.io/easystafe/reference/aplicar_conversao_moeda.md).
  Por padrao `70.00` (valor indicativo; actualizar conforme necessario).

- eur_to_usd:

  Numerico. Taxa de cambio EUR para USD. Passado a
  [`aplicar_conversao_moeda`](https://moz-gpe.github.io/easystafe/reference/aplicar_conversao_moeda.md).
  Por padrao `1.10` (valor indicativo; actualizar conforme necessario).

## Value

Um tibble com uma linha por registo (movimentos, saldo inicial e saldo
final) de todos os PDFs processados. Ver
[`aplicar_conversao_moeda`](https://moz-gpe.github.io/easystafe/reference/aplicar_conversao_moeda.md)
para descricao das colunas `valor_lancamento_mt` e
`valor_lancamento_usd`.

## Details

Apos extrair e combinar todos os PDFs, chama internamente
[`aplicar_conversao_moeda`](https://moz-gpe.github.io/easystafe/reference/aplicar_conversao_moeda.md)
com as taxas fornecidas. Para re-aplicar conversoes com taxas diferentes
sem re-processar os PDFs, use
[`aplicar_conversao_moeda`](https://moz-gpe.github.io/easystafe/reference/aplicar_conversao_moeda.md)
directamente sobre o tibble ja processado.

## Examples

``` r
if (FALSE) { # \dontrun{
df_razao <- processar_extracto_razao_c(
  source_path = path_folder_source,
  usd_to_mt   = 63.86,
  eur_to_mt   = 70.00,
  eur_to_usd  = 1.10
)
} # }
```
