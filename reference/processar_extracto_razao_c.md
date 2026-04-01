# Processar extractos do razao contabilistico do e-SISTAFE a partir de ficheiros PDF

Le todos os ficheiros PDF de uma pasta, extrai as transaccoes e saldos
de cada extracto da razao contabilistico, e combina os resultados num
unico tibble. Ficheiros com formato FOREX (USD/EUR) sao excluidos por
padrao.

## Usage

``` r
processar_extracto_razao_c(
  source_path,
  exclude_pattern = "CENTRAL USD|EXTRACTO DA CONTA FOREX EUR|EXTRACTO DA CONTA FOREX USD",
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
  `"CENTRAL USD|EXTRACTO DA CONTA FOREX EUR|EXTRACTO DA CONTA FOREX USD"`.
  Para nao excluir nenhum ficheiro, usar `NULL`.

- recursive:

  Logico. Se `TRUE`, a pesquisa de ficheiros PDF inclui subpastas. Por
  padrao `FALSE`.

- quiet:

  Logico. Se `TRUE` (padrao), suprime as mensagens emitidas por ficheiro
  durante o processamento (por exemplo, quando um PDF nao contem
  transaccoes). Se `FALSE`, as mensagens sao apresentadas.

## Value

Um tibble com uma linha por registo (movimentos, saldo inicial e saldo
final) de todos os PDFs processados, contendo as colunas:

- source_file:

  Nome do ficheiro PDF de origem.

- unidade_gestao:

  Nome da unidade de gestao extraido do cabecalho.

- data:

  Data do registo (`Date`).

- ano:

  Ano extraido da data do registo (`integer`).

- mes:

  Mes extraido da data do registo (`integer`).

- tipo:

  Tipo de registo: `"MOVIMENTO"`, `"SALDO_INICIAL"` ou `"SALDO_FINAL"`.

- codigo_documento:

  Codigo do documento (apenas em movimentos).

- valor_lancamento:

  Valor do lancamento em MZN, negativo para creditos (C).

- dc1:

  Indicador debito/credito do lancamento (`"D"` ou `"C"`).

- saldo_atual:

  Saldo acumulado apos o lancamento.

- dc2:

  Indicador debito/credito do saldo.

- saldo_inicial_fim:

  Valor do saldo inicial ou final (apenas nessas linhas).

## Details

A logica de extraccao trata os seguintes casos:

- PDFs com transaccoes: extrai movimentos linha a linha e calcula saldos
  inicial e final.

- PDFs sem transaccoes: retorna apenas as linhas SALDO_INICIAL e
  SALDO_FINAL com base nos valores do cabecalho.

- Datas com espacos irregulares (ex: `"01 / 12 / 2025"`): sao
  normalizadas automaticamente.

- Valores em formato portugues (ponto como separador de milhares,
  virgula como decimal): convertidos correctamente.

- Creditos (C) sao convertidos para valores negativos.

O intervalo de datas do conjunto processado e guardado como atributo do
tibble retornado, acessivel via `attr(df, "date_range_txt")`.

## Examples

``` r
if (FALSE) { # \dontrun{
df_razao <- processar_extracto_razao_c(
  source_path = path_folder_source
)

# Com mensagens visiveis e subpastas incluidas
df_razao <- processar_extracto_razao_c(
  source_path = path_folder_source,
  recursive   = TRUE,
  quiet       = FALSE
)

# Sem exclusao de ficheiros FOREX
df_razao <- processar_extracto_razao_c(
  source_path     = path_folder_source,
  exclude_pattern = NULL
)
} # }
```
