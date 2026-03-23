# Gravar extracto processado do e-SISTAFE em Excel

Grava um dataframe processado do e-SISTAFE num ficheiro Excel,
construindo automaticamente o nome do ficheiro a partir dos metadados do
relatorio (tipo, ano e mes) e da data actual. Cria a pasta de destino se
nao existir.

## Usage

``` r
gravar_extracto_sistafe(df, output_folder = "Dataout", quiet = TRUE)
```

## Arguments

- df:

  Um dataframe processado por `processar_extracto_sistafe()` com
  `include_meta = TRUE`. Deve conter as colunas `reporte_tipo`, `ano` e
  `mes`.

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
`<reporte_tipo>_<ano>_<mes>_<YYYYMMDD>.xlsx`

Por exemplo: `Funcionamento_2025_Dezembro_20260320.xlsx`

Se o dataframe contiver multiplos valores para `reporte_tipo`, `ano` ou
`mes` (por exemplo, quando se combinam varios meses), os valores sao
concatenados com `"-"` no nome do ficheiro.

Esta funcao requer que `processar_extracto_sistafe()` tenha sido chamado
com `include_meta = TRUE`. Se as colunas de metadados estiverem em
falta, a funcao para com uma mensagem de erro informativa.

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
