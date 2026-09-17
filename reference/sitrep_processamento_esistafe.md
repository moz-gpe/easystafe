# Detecta e reporta lacunas de enriquecimento no dataframe produzido por `processar_extracto_esistafe() |> adicionar_lookups_esistafe()`: casos onde os *left joins* silenciosamente produziram `NA` por falta de correspondencia no ficheiro de lookup. Imprime um resumo em portugues com instrucoes de remediacao (qual folha actualizar, por que ordem), e grava um ficheiro Excel em disco com o detalhe de cada lacuna. Tambem apresenta um quadro de completude de UGBs (Funcionamento).

Detecta e reporta lacunas de enriquecimento no dataframe produzido por
`processar_extracto_esistafe() |> adicionar_lookups_esistafe()`: casos
onde os *left joins* silenciosamente produziram `NA` por falta de
correspondencia no ficheiro de lookup. Imprime um resumo em portugues
com instrucoes de remediacao (qual folha actualizar, por que ordem), e
grava um ficheiro Excel em disco com o detalhe de cada lacuna. Tambem
apresenta um quadro de completude de UGBs (Funcionamento).

## Usage

``` r
sitrep_processamento_esistafe(
  df,
  lookups,
  lookup_path = NULL,
  output_folder = "Dataout/sitrep",
  quiet = FALSE
)
```

## Arguments

- df:

  Tibble enriquecido, produzido por
  [`processar_extracto_esistafe()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_esistafe.md)
  seguido de
  [`adicionar_lookups_esistafe()`](https://moz-gpe.github.io/easystafe/reference/adicionar_lookups_esistafe.md).
  Deve conter as colunas: `funcao`, `funcao_nivel`, `programa`,
  `ambito`, `fr`, `programa_tipo`, `ced`, `ced_nome`, `ced_2`,
  `ced_2_nome`, `ced_3`, `ced_3_nome`, `ced_nivel`,
  `dotacao_actualizada_da`, `reporte_tipo`, `data_tipo`.

- lookups:

  Lista devolvida por
  [`carregar_lookups_esistafe`](https://moz-gpe.github.io/easystafe/reference/carregar_lookups_esistafe.md),
  carregada a partir da versao actual do ficheiro Excel de lookup.

- lookup_path:

  Caracter. Caminho para o ficheiro `esistafe_dim_lookup.xlsx`;
  apresentado nas instrucoes de consola. Quando `NULL` (padrao), as
  mensagens referem o ficheiro genericamente. Em `esistafe_processar.R`
  passe `lookup_path = metadata_lookup`.

- output_folder:

  Caracter. Pasta de destino do ficheiro Excel de diagnostico. Criada
  automaticamente se nao existir. Padrao: `"Dataout/sitrep"`.

- quiet:

  Logico. Se `FALSE` (padrao), imprime o resumo na consola. Se `TRUE`,
  suprime toda a saida mas continua a gravar o ficheiro Excel e a
  devolver a lista.

## Value

Uma lista nomeada (invisivelmente), com os seguintes elementos:

- funcao_em_falta:

  Tibble com uma linha por codigo `funcao` ausente do lookup. Colunas:
  `funcao`, `sugestao_funcao_nivel` (`NA` – analista preenche),
  `n_linhas`, `dotacao_total`, `reporte_tipos`.

- programa_em_falta:

  Tibble com uma linha por chave composta `programa_ambito_fr` ausente
  do lookup. Colunas: `programa_ambito_fr`, `sugestao_programa_tipo`
  (`NA`), `programa`, `ambito`, `fr`, `n_linhas`, `dotacao_total`,
  `reporte_tipos`.

- ced_em_falta:

  Tibble com uma linha por codigo CED ausente. Inclui flags de cascata:
  `ced_3_existe`, `ced_nivel_existe` (`NA` se `ced_3` tambem e novo),
  `ced_2_existe`, e colunas `sugestao_*` (`NA`) para o analista
  preencher.

- ugb_completude:

  Tibble com combinacoes `periodo` x `codigo_ugb` que tem lacunas de
  completude em Funcionamento. Ver
  [`ugb_incompletas_esistafe`](https://moz-gpe.github.io/easystafe/reference/ugb_incompletas_esistafe.md).

- n_afectados:

  Tibble-resumo das lacunas de lookup (A/B/C). Colunas: `gap_tipo`,
  `n_gap`, `n_linhas`, `dotacao_total`.

## Details

A funcao trabalha apenas sobre linhas `data_tipo == "Valor"`. Para o
CED, a cascata de actualizacao segue a ordem:

1.  `ced` – sempre.

2.  `ced_3` – apenas se `ced_3_existe = FALSE`.

3.  `ced_nivel` – se `ced_3` e novo ou `ced_nivel_existe = FALSE`.

4.  `ced_2` – apenas se `ced_2_existe = FALSE`.

O ficheiro Excel e gravado apenas quando existe pelo menos uma lacuna
(lookup ou completude). Se tudo estiver correcto, nenhum ficheiro e
criado.

## See also

[`verificar_ugb_completude`](https://moz-gpe.github.io/easystafe/reference/verificar_ugb_completude.md),
[`ugb_incompletas_esistafe`](https://moz-gpe.github.io/easystafe/reference/ugb_incompletas_esistafe.md),
[`resumir_processamento_esistafe`](https://moz-gpe.github.io/easystafe/reference/resumir_processamento_esistafe.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Apos correr o pipeline ETL (existafe_processar.R), na mesma sessao:
gaps <- sitrep_processamento_esistafe(
  df          = df_esistafe,
  lookups     = lookups,
  lookup_path = metadata_lookup
)

# Inspeccionar lacunas especificas
gaps$funcao_em_falta
gaps$ced_em_falta
gaps$n_afectados

# Apos corrigir o ficheiro de lookup, recarregar e verificar novamente
lookups     <- carregar_lookups_esistafe(metadata_lookup)
df_esistafe <- df_esistafe_raw |> adicionar_lookups_esistafe(lookups)
gaps        <- sitrep_processamento_esistafe(df_esistafe, lookups, lookup_path = metadata_lookup)
} # }
```
