# Gravar extracto processado do e-SISTAFE em Excel

Grava um dataframe processado do e-SISTAFE num ficheiro Excel,
construindo automaticamente o nome do ficheiro a partir dos metadados do
relatório (tipo, ano e mês) e da data actual. Cria a pasta de destino se
não existir.

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

  Caractere. Caminho para a pasta de destino onde o ficheiro Excel será
  gravado. Por padrão `"Dataout"`. A pasta é criada automaticamente se
  não existir.

- quiet:

  Lógico. Se `TRUE` (padrão), as mensagens de progresso são suprimidas.
  Se `FALSE`, são emitidas mensagens sobre a criação da pasta e o
  caminho do ficheiro gravado.

## Value

O caminho completo do ficheiro gravado, retornado de forma invisível.
Pode ser capturado com `path <- gravar_extracto_sistafe(df)` para uso
posterior se necessário.

## Details

O nome do ficheiro é construído automaticamente no formato:
`<reporte_tipo>_<ano>_<mes>_<YYYYMMDD>.xlsx`

Por exemplo: `Funcionamento_2025_Dezembro_20260320.xlsx`

Se o dataframe contiver múltiplos valores para `reporte_tipo`, `ano` ou
`mes` (por exemplo, quando se combinam vários meses), os valores são
concatenados com `"-"` no nome do ficheiro.

Esta função requer que `processar_extracto_sistafe()` tenha sido chamado
com `include_meta = TRUE`. Se as colunas de metadados estiverem em
falta, a função para com uma mensagem de erro informativa.

## Examples

``` r
if (FALSE) { # \dontrun{
# Gravar com pasta padrão
gravar_extracto_sistafe(df)

# Gravar numa pasta personalizada
gravar_extracto_sistafe(df, output_folder = "Data/processed")

# Gravar com mensagens de progresso
gravar_extracto_sistafe(df, quiet = FALSE)

# Capturar o caminho do ficheiro gravado
path <- gravar_extracto_sistafe(df, quiet = FALSE)
} # }
```
