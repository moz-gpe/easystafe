# Detalhe de UGBs incompletas por periodo

Devolve um tibble com as UGBs de educacao que, em cada periodo, nao
possuem registos de Funcionamento com valor \> 0 em pelo menos uma das
variaveis financeiras chave (`dotacao_actualizada_da` e
`ad_fundos_desp_paga_vd_afdp`). Complementa
[`resumir_processamento_esistafe`](https://moz-gpe.github.io/easystafe/reference/resumir_processamento_esistafe.md),
cuja tabela-resumo mostra apenas as contagens; esta funcao expoe os
codigos concretos, que de outra forma seriam truncados na consola.

## Usage

``` r
ugb_incompletas_esistafe(df, lookup_ugb)
```

## Arguments

- df:

  O dataframe combinado do processamento e-SISTAFE. Deve conter as
  colunas `periodo`, `reporte_tipo`, `ugb_id`, `dotacao_actualizada_da`
  e `ad_fundos_desp_paga_vd_afdp`.

- lookup_ugb:

  Dataframe com a tabela de referencia das UGBs de educacao (coluna
  `codigo_ugb`).

## Value

Um tibble com uma linha por combinacao `periodo` x `codigo_ugb` que tem
pelo menos uma lacuna, com as colunas logicas `sem_dotacao` e
`sem_afdp`.

## See also

[`resumir_processamento_esistafe`](https://moz-gpe.github.io/easystafe/reference/resumir_processamento_esistafe.md),
[`verificar_ugb_completude`](https://moz-gpe.github.io/easystafe/reference/verificar_ugb_completude.md)

## Examples

``` r
if (FALSE) { # \dontrun{
ugb_incompletas_esistafe(df_esistafe, lookups$ugb)
} # }
```
