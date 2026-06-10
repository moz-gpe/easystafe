# Adicionar metados ao dataframe e-SISTAFE com lookups descritivos

Junta informacao descritiva de UGB, funcao e programa a um dataframe ja
processado por
[`processar_extracto_esistafe()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_esistafe.md),
adicionando colunas de provincia, distrito, ambito, nivel da
instituicao, descricao, nivel funcional e tipo de programa. As colunas
adicionadas sao reposicionadas imediatamente apos as colunas de
identificacao orcamental.

## Usage

``` r
adicionar_lookups_esistafe(df, lookups)
```

## Arguments

- df:

  Um dataframe processado por
  [`processar_extracto_esistafe()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_esistafe.md).
  Deve conter as colunas `ugb_id`, `funcao`, `programa` e `fr`.

- lookups:

  Uma lista com quatro elementos nomeados:

  ugb

  :   Dataframe com a tabela de referencia de UGBs. Deve conter
      `codigo_ugb` como chave de ligacao, mais as colunas `provincia`,
      `distrito`, `ambito`, colunas com prefixo `adm`,
      `nivel_da_instituicao` e `descricao`.

  funcao

  :   Dataframe com a tabela de referencia de funcoes. Deve conter
      `funcao` como chave de ligacao e `funcao_nivel`.

  programa

  :   Dataframe com a tabela de referencia de programas. Deve conter
      `programa_ambito_fr` como chave de ligacao e `programa_tipo`.

## Value

O dataframe `df` enriquecido com as colunas descritivas dos quatro
lookups. As colunas de UGB (`provincia`, `distrito`, `ambito`, colunas
`adm*`, `nivel_da_instituicao`, `descricao`) e de programa
(`programa_tipo`) sao posicionadas apos `ced`. A coluna `funcao_nivel` e
posicionada apos `funcao`.

## Details

A funcao valida a presenca dos tres elementos obrigatorios na lista
`lookups` antes de executar qualquer join. Se algum elemento estiver
ausente, e emitido um [`stop()`](https://rdrr.io/r/base/stop.html)
imediato com o nome do elemento em falta.

As ligacoes sao feitas por:

- `ugb_id == codigo_ugb` para o lookup de UGBs.

- `funcao == funcao` para o lookup de funcoes.

- Para programas, uma chave e construida internamente e removida apos o
  join: `programa_ambito_fr` (concatenacao de `programa`, `ambito` e
  `fr`). Todas as linhas sao ligadas a `lookups$programa` via
  `programa_ambito_fr`.

## Examples

``` r
if (FALSE) { # \dontrun{
lookups <- list(
  ugb = readxl::read_excel("Data/lookups.xlsx", sheet = "ugb") |>
    janitor::clean_names() |>
    dplyr::select(codigo_ugb, provincia, distrito, ambito,
                  dplyr::starts_with("adm"),
                  nivel_da_instituicao, descricao) |>
    dplyr::filter(!codigo_ugb == "Total"),
  funcao = readxl::read_excel("Data/lookups.xlsx", sheet = "funcao") |>
    janitor::clean_names() |>
    dplyr::select(funcao, funcao_nivel = classificacao_funcional_por_nivel) |>
    dplyr::filter(!is.na(funcao)),
  programa = readxl::read_excel("Data/lookups.xlsx", sheet = "programa") |>
    janitor::clean_names() |>
    dplyr::select(programa_ambito_fr, programa_tipo) |>
    dplyr::filter(!is.na(programa_tipo))
)

df_enriched <- adicionar_lookups_esistafe(df_esistafe, lookups)
} # }
```
