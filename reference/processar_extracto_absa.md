# Processar Extractos Bancarios ABSA

Localiza todos os ficheiros PDF com o padrao `"EXTRACTO ABSA"` numa
pasta, processa cada um e devolve um unico tibble combinado compativel
com o esquema `df_razao` utilizado no pipeline do `easystafe`.

## Usage

``` r
processar_extracto_absa(
  source_path,
  pattern = "EXTRACTO ABSA",
  recursive = FALSE,
  y_tolerance = 2,
  verbose = TRUE
)
```

## Arguments

- source_path:

  `character(1)`. Caminho para a pasta que contem os ficheiros PDF dos
  extractos ABSA.

- pattern:

  `character(1)`. Padrao regex usado para identificar os ficheiros ABSA
  dentro de `source_path`. O padrao predefinido `"EXTRACTO ABSA"`
  corresponde ao nome de ficheiro padrao dos extractos ABSA Mocambique.
  Nao faz distincao entre maiusculas e minusculas. Default:
  `"EXTRACTO ABSA"`.

- recursive:

  `logical(1)`. Se `TRUE`, pesquisa tambem nas subpastas de
  `source_path`. Default: `FALSE`.

- y_tolerance:

  `numeric(1)`. Tolerancia vertical (em pontos PDF) para agrupar
  palavras na mesma linha durante a reconstrucao por coordenadas. O
  valor predefinido de `2` funciona para os extractos ABSA padrao.
  Default: `2`.

- verbose:

  `logical(1)`. Se `TRUE`, imprime uma linha de resumo por ficheiro
  processado e um total no final. Default: `TRUE`.

## Value

Um tibble com 12 colunas correspondentes ao esquema `df_razao`:

- source_file:

  `character`. Nome do ficheiro PDF de origem.

- unidade_gestao:

  `character`. Sempre `NA` – a preencher downstream.

- data:

  `Date`. Data do movimento. A data ficticia de abertura (`01/01/1900`)
  e remapeada para o primeiro dia do periodo do extracto.

- ano:

  `integer`. Ano extraido de `data`.

- mes:

  `character`. Nome completo do mes em ingles (e.g. `"February"`).

- tipo:

  `character`. Um de `"SALDO_INICIAL"`, `"MOVIMENTO"` ou
  `"SALDO_FINAL"`.

- codigo_documento:

  `character`. Numero de referencia do movimento, quando presente. `NA`
  caso contrario.

- valor_lancamento:

  `double`. Valor assinado do movimento: positivo para creditos,
  negativo para debitos. `NA` nas linhas de saldo.

- dc1:

  `character`. Indicador debito/credito do movimento: `"C"`, `"D"` ou
  `NA`.

- saldo_atual:

  `double`. Saldo corrente apos o movimento.

- dc2:

  `character`. Indicador debito/credito do saldo. Sempre `"D"` para este
  tipo de conta.

- saldo_inicial_fim:

  `double`. Saldo de abertura em `SALDO_INICIAL`; saldo calculado
  (abertura + creditos - debitos) em `SALDO_FINAL`; `NA` nos movimentos.

## Details

O layout dos PDFs ABSA apresenta dois problemas conhecidos que esta
funcao resolve:

1.  **Truncagem de pagina**:
    [`pdftools::pdf_text()`](https://docs.ropensci.org/pdftools//reference/pdftools.html)
    trunca silenciosamente a primeira pagina. A funcao usa
    [`pdftools::pdf_data()`](https://docs.ropensci.org/pdftools//reference/pdftools.html)
    em alternativa, reconstruindo as linhas a partir das coordenadas x/y
    de cada palavra.

2.  **Linhas de continuacao**: Descricoes longas e numeros de referencia
    podem continuar numa segunda linha sem data inicial. Essas linhas
    sao detectadas e concatenadas a linha de transaccao anterior.

A linha de fecho (`SALDO_FINAL`) e acrescentada programaticamente e nao
extraida do rodape do PDF. O seu `saldo_inicial_fim` e calculado como
`saldo_abertura + sum(creditos) - sum(debitos)`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Processar todos os extractos ABSA numa pasta
df_absa <- processar_extracto_absa("Data/razao_cont/2026_02/outro/")

# Combinar com outros extractos do razao
df_razao <- bind_rows(df_razao, df_absa)

# Usar um padrao diferente ou pesquisar em subpastas
df_absa <- processar_extracto_absa(
  source_path = "Data/razao_cont/",
  pattern     = "ABSA",
  recursive   = TRUE
)
} # }
```
