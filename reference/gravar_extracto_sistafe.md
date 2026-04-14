# Gravar extracto processado do e-SISTAFE em Excel

Grava um dataframe processado do e-SISTAFE num ficheiro Excel,
construindo automaticamente o nome do ficheiro a partir do ano e mes
mais recentes presentes nos dados. Cria a pasta de destino se nao
existir.

## Usage

``` r
gravar_extracto_sistafe(df, output_folder = "Data/processed/", quiet = TRUE)
```

## Arguments

- df:

  Um dataframe processado contendo pelo menos as colunas `ano` e `mes`.

- output_folder:

  Caractere. Caminho para a pasta de destino onde o ficheiro Excel sera
  gravado. Por padrao `"Dataout"`. A pasta e criada automaticamente se
  nao existir.

- quiet:

  Logico. Se `TRUE` (padrao), as mensagens de progresso sao suprimidas.
  Se `FALSE`, sao emitidas mensagens sobre a criacao da pasta e o
  caminho do ficheiro gravado.

## Value

O caminho completo do ficheiro gravado, retornado de forma invisivel.
Pode ser capturado com `path <- gravar_extracto_sistafe(df)` para uso
posterior se necessario.

## Details

O nome do ficheiro e construido automaticamente no formato:
`eSISTAFE_<YYYYMM>.xlsx`, onde `YYYY` e o ano mais recente e `MM` o mes
mais recente presentes no dataframe.

Por exemplo: `eSISTAFE_202512.xlsx`

Se o dataframe abranger varios meses ou anos, e sempre utilizado o valor
mais recente para construir o nome do ficheiro.

## Examples

``` r
if (FALSE) { # \dontrun{
# Gravar com pasta padrao
gravar_extracto_sistafe(df)

# Gravar numa pasta personalizada
gravar_extracto_sistafe(df, output_folder = "Data/processed")

# Gravar com mensagens de progresso
gravar_extracto_sistafe(df, quiet = FALSE)

# Capturar o caminho do ficheiro gravado
path <- gravar_extracto_sistafe(df, quiet = FALSE)
} # }
```
