# Aplicar conversao de moeda a um tibble de extractos do e-SISTAFE

Calcula `valor_lancamento_mt`, `valor_lancamento_usd`,
`valor_lancamento_eur`, `saldo_inicial_fim_mt`, `saldo_inicial_fim_usd`
e `saldo_inicial_fim_eur` com base no nome do ficheiro de origem
(`source_file`), aplicando as taxas de cambio fornecidas. Pode ser
chamada de forma independente ou e invocada internamente por
[`processar_extracto_razao_c()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_razao_c.md)
e
[`processar_extracto_absa()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_absa.md).

## Usage

``` r
aplicar_conversao_moeda(
  df,
  usd_to_mt = 63.91,
  cut_usd_to_mt = 63.27,
  eur_to_mt = 70,
  eur_to_usd = 1.1
)
```

## Arguments

- df:

  Tibble. Output de
  [`processar_extracto_razao_c()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_razao_c.md)
  ou qualquer tibble com as colunas `source_file`, `valor_lancamento` e
  `saldo_inicial_fim`.

- usd_to_mt:

  Numerico. Taxa de cambio USD para MZN. Utilizada para ficheiros
  `"EXTRACTO ABSA BANK USD"` e como fallback geral para ficheiros MZN.
  Por padrao `63.91`.

- cut_usd_to_mt:

  Numerico. Taxa de cambio USD para MZN especifica para ficheiros
  `"CENTRAL USD"`. Por padrao `63.27`.

- eur_to_mt:

  Numerico. Taxa de cambio EUR para MZN. Utilizada para ficheiros
  `"CENTRAL EUR"`. Por padrao `70.00` (valor indicativo; actualizar
  conforme necessario).

- eur_to_usd:

  Numerico. Taxa de cambio EUR para USD. Utilizada para calcular
  conversoes EUR/USD. Por padrao `1.10` (valor indicativo; actualizar
  conforme necessario).

## Value

O tibble de entrada com seis colunas adicionais, posicionadas
imediatamente a direita das suas colunas de origem:

- valor_lancamento_mt:

  Valor do lancamento em MZN.

- valor_lancamento_usd:

  Valor do lancamento em USD.

- valor_lancamento_eur:

  Valor do lancamento em EUR.

- saldo_inicial_fim_mt:

  Saldo inicial ou final em MZN.

- saldo_inicial_fim_usd:

  Saldo inicial ou final em USD.

- saldo_inicial_fim_eur:

  Saldo inicial ou final em EUR.

## Details

A logica de conversao baseia-se no nome do ficheiro de origem. A tabela
abaixo resume as taxas aplicadas a cada tipo de ficheiro:

|  |  |  |  |
|----|----|----|----|
| **Ficheiro** | **\_mt** | **\_usd** | **\_eur** |
| CENTRAL USD | \* cut_usd_to_mt | = valor original | / eur_to_usd |
| EXTRACTO ABSA BANK USD | \* usd_to_mt | = valor original | / eur_to_usd |
| CENTRAL EUR | \* eur_to_mt | \* eur_to_usd | = valor original |
| EXTRACTO ABSA BANK MT/MZN | = valor original | / usd_to_mt | / eur_to_mt |

Para re-aplicar conversoes com taxas actualizadas sem re-processar os
PDFs, chame esta funcao directamente sobre o tibble ja processado,
removendo previamente as colunas de conversao existentes.

## Examples

``` r
if (FALSE) { # \dontrun{
# Uso independente sobre um tibble ja processado
df_com_moeda <- aplicar_conversao_moeda(
  df             = df_razao,
  usd_to_mt      = 63.91,
  cut_usd_to_mt  = 63.27,
  eur_to_mt      = 70.00,
  eur_to_usd     = 1.10
)

# Re-aplicar com taxas actualizadas
df_revalorizado <- df_razao |>
  dplyr::select(-valor_lancamento_mt, -valor_lancamento_usd,
                -valor_lancamento_eur, -saldo_inicial_fim_mt,
                -saldo_inicial_fim_usd, -saldo_inicial_fim_eur) |>
  aplicar_conversao_moeda(
    usd_to_mt     = 0.015700,
    cut_usd_to_mt = 0.015900,
    eur_to_mt     = 71.20,
    eur_to_usd    = 1.11
  )
} # }
```
