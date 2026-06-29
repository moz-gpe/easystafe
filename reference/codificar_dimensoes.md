# Codificar variaveis de dimensao geografica

Aplica identificadores numericos inteiros e nomes canonicos as colunas
`provincia` e `distrito` de qualquer dataframe. Util para preparar dados
para carregamento em DuckDB ou outras bases de dados relacionais, ou
para normalizar a ortografia de nomes geograficos.

## Usage

``` r
codificar_dimensoes(df, col_provincia = "provincia", col_distrito = "distrito")
```

## Arguments

- df:

  Um dataframe contendo colunas de provincia e/ou distrito. Se uma das
  colunas de join estiver ausente, e emitido um aviso e o respectivo
  join e ignorado; a outra dimensao continua a ser processada
  normalmente.

- col_provincia:

  Nome da coluna no `df` que sera usada para fazer join com
  `provincia_map`. Por defeito `"provincia"`.

- col_distrito:

  Nome da coluna no `df` que sera usada para fazer join com
  `distrito_map`. Por defeito `"distrito"`.

## Value

O dataframe de entrada com as colunas de provincia e distrito
sobrescritas com nomes canonicos (onde reconhecidos), e duas novas
colunas adicionadas: `provincia_id` e `distrito_id` (inteiros).

## Details

Codifica as seguintes dimensoes:

- provincia_id:

  Inteiro de dois digitos derivado de `provincia`. Valores nao
  reconhecidos ou `NA` sao codificados como `99L`. A coluna `provincia`
  e sobrescrita com a ortografia canonica quando o valor e reconhecido;
  caso contrario, o valor original e mantido.

- distrito_id:

  Inteiro de quatro digitos (prefixo de provincia mais numero sequencial
  do distrito) derivado de `distrito`. Valores nao reconhecidos ou `NA`
  sao codificados como `9999L`. A coluna `distrito` e sobrescrita com a
  ortografia canonica quando o valor e reconhecido; caso contrario, o
  valor original e mantido.

## Examples

``` r
if (FALSE) { # \dontrun{
# A partir do pipeline esistafe
lookups <- carregar_lookups_esistafe("Data/lookups.xlsx")

df <- processar_extracto_esistafe(
  source_path   = "Data/202602/",
  df_ugb_lookup = lookups$ugb
) |>
  adicionar_lookups_esistafe(lookups) |>
  codificar_dimensoes()

# Com qualquer dataframe que contenha colunas provincia e distrito
df_outro <- data.frame(provincia = "Nampula", distrito = "Angoche")
codificar_dimensoes(df_outro)

# Com nomes de colunas alternativos no dataframe de entrada
df_alt <- data.frame(prov = "Nampula", dist = "Angoche")
codificar_dimensoes(df_alt, col_provincia = "prov", col_distrito = "dist")
} # }
```
