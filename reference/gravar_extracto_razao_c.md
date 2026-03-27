# Gravar extracto da razao contabilistico processado em Excel

Grava um dataframe processado por
[`processar_extracto_razao_c()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_razao_c.md)
num ficheiro Excel, construindo automaticamente o nome do ficheiro a
partir do intervalo de datas do relatorio e da data actual. Cria a pasta
de destino se nao existir.

## Usage

``` r
gravar_extracto_razao_c(df, output_folder = "Dataout", quiet = TRUE)
```

## Arguments

- df:

  Um tibble processado por
  [`processar_extracto_razao_c()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_razao_c.md).
  Deve conter o atributo `date_range_txt` gerado por essa funcao.

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
Pode ser capturado com `path <- gravar_extracto_razao_c(df)` para uso
posterior se necessario.

## Details

O nome do ficheiro e construido automaticamente no formato:
`Razao_C_<data_inicio>_a_<data_fim>_<YYYYMMDD>.xlsx`

Por exemplo: `Razao_C_2025-01-01_a_2025-12-31_20260323.xlsx`

Se o atributo `date_range_txt` nao estiver presente no dataframe (por
exemplo, se o objeto foi modificado apos o processamento), o nome do
ficheiro usa `"sem_datas"` como sufixo.

## Examples

``` r
if (FALSE) { # \dontrun{
# Gravar com pasta padrao
gravar_extracto_razao_c(df_razao)

# Gravar numa pasta personalizada
gravar_extracto_razao_c(df_razao, output_folder = "Data/processed")

# Gravar com mensagens de progresso
gravar_extracto_razao_c(df_razao, quiet = FALSE)

# Capturar o caminho do ficheiro gravado
path <- gravar_extracto_razao_c(df_razao, quiet = FALSE)
} # }
```
