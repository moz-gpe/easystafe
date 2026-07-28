# Resumo consolidado do processamento de extractos e-SISTAFE

Produz um resumo unico depois de todos os periodos terem sido
processados e combinados (por exemplo, com
[`purrr::map()`](https://purrr.tidyverse.org/reference/map.html) seguido
de
[`purrr::list_rbind()`](https://purrr.tidyverse.org/reference/list_c.html)).
Substitui as mensagens de completude que eram emitidas repetidamente por
cada pasta durante o processamento, apresentando em vez disso um
conjunto de tabelas-resumo no fim.

## Usage

``` r
resumir_processamento_esistafe(df, lookup_ugb, quiet = FALSE)
```

## Arguments

- df:

  O dataframe combinado devolvido pelo processamento de um ou mais
  periodos com
  [`processar_extracto_esistafe`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_esistafe.md)
  (antes ou depois de
  [`adicionar_lookups_esistafe`](https://moz-gpe.github.io/easystafe/reference/adicionar_lookups_esistafe.md)).
  Deve conter pelo menos as colunas `pasta_fonte`, `periodo`,
  `reporte_tipo`, `ugb_id`, `dotacao_actualizada_da` e
  `ad_fundos_desp_paga_vd_afdp`.

- lookup_ugb:

  Dataframe com a tabela de referencia das UGBs de educacao. Deve conter
  pelo menos a coluna `codigo_ugb`.

- quiet:

  Logico. Se `FALSE` (padrao), as tabelas-resumo sao impressas na
  consola. Se `TRUE`, nada e impresso e apenas a lista de tibbles e
  devolvida (invisivelmente).

## Value

Invisivelmente, uma lista nomeada de tibbles:

- `overview`: ficheiros e linhas por periodo.

- `completude`: completude de UGBs (Funcionamento) por periodo.

- `negativos`: correccao de valores negativos por periodo (`NULL` se
  `correct_negatives = FALSE` no processamento).

- `ugb_ausentes`: UGBs do lookup que nao aparecem em nenhum periodo dos
  dados.

- `ugb_incompletas`: detalhe por periodo x UGB das lacunas de completude
  (ver
  [`ugb_incompletas_esistafe`](https://moz-gpe.github.io/easystafe/reference/ugb_incompletas_esistafe.md)).

## Details

Todas as metricas sao recuperadas do dataframe combinado (abordagem
*post-hoc*). Nota: as UGBs presentes nos ficheiros de origem que foram
removidas por nao pertencerem ao sector da educacao (filtragem em
[`processar_extracto_esistafe()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_esistafe.md))
nao sao recuperaveis a partir do dataframe combinado; `ugb_ausentes`
reporta apenas o inverso – UGBs do lookup que nunca aparecem nos dados.

## See also

[`verificar_ugb_completude`](https://moz-gpe.github.io/easystafe/reference/verificar_ugb_completude.md),
[`ugb_incompletas_esistafe`](https://moz-gpe.github.io/easystafe/reference/ugb_incompletas_esistafe.md)

## Examples

``` r
if (FALSE) { # \dontrun{
lookups <- carregar_lookups_esistafe("Documents/lookup.xlsx")

df_esistafe <- paths_esistafe |>
  purrr::map(\(path) processar_extracto_esistafe(
    source_path   = path,
    df_ugb_lookup = lookups$ugb
  )) |>
  purrr::list_rbind()

resumir_processamento_esistafe(df_esistafe, lookups$ugb)
} # }
```
