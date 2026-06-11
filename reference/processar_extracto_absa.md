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
  quiet = TRUE,
  usd_to_mt = 63.86,
  eur_to_mt = 70,
  eur_to_usd = 1.1
)
```

## Arguments

- source_path:

  `character(1)`. Caminho para a pasta que contem os ficheiros PDF dos
  extractos ABSA. Obrigatorio.

- pattern:

  `character(1)`. Padrao regex usado para identificar os ficheiros ABSA
  dentro de `source_path`. Nao faz distincao entre maiusculas e
  minusculas. Default: `"EXTRACTO ABSA"`.

- recursive:

  `logical(1)`. Se `TRUE`, pesquisa tambem nas subpastas de
  `source_path`. Default: `FALSE`.

- y_tolerance:

  `numeric(1)`. Tolerancia vertical (em pontos PDF) para agrupar
  palavras na mesma linha durante a reconstrucao por coordenadas. O
  valor predefinido de `2` funciona para os extractos ABSA padrao.
  Default: `2`.

- quiet:

  `logical(1)`. Se `TRUE` (padrao), suprime as mensagens emitidas por
  ficheiro durante o processamento. Se `FALSE`, e emitida uma mensagem
  por ficheiro processado. Independentemente deste parametro, e sempre
  emitida uma mensagem final com o numero de linhas e ficheiros
  processados. Default: `TRUE`.

- usd_to_mt:

  `numeric(1)`. Taxa de cambio USD para MZN. Passado a
  [`aplicar_conversao_moeda`](https://moz-gpe.github.io/easystafe/reference/aplicar_conversao_moeda.md).
  Por padrao `63.86` (valor indicativo; actualizar conforme necessario).

- eur_to_mt:

  `numeric(1)`. Taxa de cambio EUR para MZN. Passado a
  [`aplicar_conversao_moeda`](https://moz-gpe.github.io/easystafe/reference/aplicar_conversao_moeda.md).
  Por padrao `70.00` (valor indicativo; actualizar conforme necessario).

- eur_to_usd:

  `numeric(1)`. Taxa de cambio EUR para USD. Passado a
  [`aplicar_conversao_moeda`](https://moz-gpe.github.io/easystafe/reference/aplicar_conversao_moeda.md).
  Por padrao `1.10` (valor indicativo; actualizar conforme necessario).

## Value

Um tibble com 18 colunas: as 12 colunas base do esquema `df_razao` mais
as 6 colunas de conversao de moeda produzidas por
[`aplicar_conversao_moeda`](https://moz-gpe.github.io/easystafe/reference/aplicar_conversao_moeda.md):

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

  `character`. Nome completo do mes em portugues (ex: `"Fevereiro"`).

- tipo:

  `character`. Um de `"Saldo Inicial"`, `"Moviemento"` ou
  `"Saldo Final"`.

- codigo_documento:

  `character`. Numero de referencia do movimento, quando presente. `NA`
  caso contrario.

- valor_lancamento:

  `double`. Valor assinado do movimento: positivo para creditos,
  negativo para debitos. `NA` nas linhas de saldo.

- valor_lancamento_mt:

  `double`. Valor do lancamento em MZN.

- valor_lancamento_usd:

  `double`. Valor do lancamento em USD.

- valor_lancamento_eur:

  `double`. Valor do lancamento em EUR.

- dc1:

  `character`. Indicador debito/credito do movimento: `"C"`, `"D"` ou
  `NA`.

- saldo_atual:

  `double`. Saldo corrente apos o movimento.

- dc2:

  `character`. Indicador debito/credito do saldo. Sempre `"D"` para este
  tipo de conta.

- saldo_inicial_fim:

  `double`. Saldo de abertura em `SALDO_INICIAL`; saldo calculado em
  `Saldo Final`; `NA` nos movimentos.

- saldo_inicial_fim_mt:

  `double`. Saldo inicial ou final em MZN.

- saldo_inicial_fim_usd:

  `double`. Saldo inicial ou final em USD.

- saldo_inicial_fim_eur:

  `double`. Saldo inicial ou final em EUR.

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

A linha de fecho (`Saldo Final`) e acrescentada programaticamente e nao
extraida do rodape do PDF. O seu `saldo_inicial_fim` e calculado como
`saldo_abertura + sum(creditos) - sum(debitos)`.

Apos extrair e combinar todos os PDFs, chama internamente
[`aplicar_conversao_moeda`](https://moz-gpe.github.io/easystafe/reference/aplicar_conversao_moeda.md)
com as taxas fornecidas. Para re-aplicar conversoes com taxas diferentes
sem re-processar os PDFs, use
[`aplicar_conversao_moeda`](https://moz-gpe.github.io/easystafe/reference/aplicar_conversao_moeda.md)
directamente sobre o tibble ja processado.

O helper interno `parse_single_absa()` e definido dentro desta funcao e
nao e exportado.

## See also

[`aplicar_conversao_moeda`](https://moz-gpe.github.io/easystafe/reference/aplicar_conversao_moeda.md),
[`processar_extracto_razao_c`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_razao_c.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Processar todos os extractos ABSA numa pasta
df_absa <- processar_extracto_absa(
  source_path = "Data/razao_cont/2026_02/outro/",
  usd_to_mt   = 63.86,
  eur_to_mt   = 70.00,
  eur_to_usd  = 1.10
)

# Combinar com outros extractos do razao
df_razao <- dplyr::bind_rows(df_razao, df_absa)

# Pesquisar em subpastas com padrao alternativo
df_absa <- processar_extracto_absa(
  source_path = "Data/razao_cont/",
  pattern     = "ABSA",
  recursive   = TRUE,
  usd_to_mt   = 63.86,
  eur_to_mt   = 70.00,
  eur_to_usd  = 1.10
)

# Re-aplicar conversoes com taxas actualizadas sem re-processar PDFs
df_absa_revalorizado <- df_absa |>
  dplyr::select(-valor_lancamento_mt, -valor_lancamento_usd,
                -valor_lancamento_eur, -saldo_inicial_fim_mt,
                -saldo_inicial_fim_usd, -saldo_inicial_fim_eur) |>
  aplicar_conversao_moeda(usd_to_mt = 64.10, eur_to_mt = 71.20,
                          eur_to_usd = 1.11)
} # }
```
