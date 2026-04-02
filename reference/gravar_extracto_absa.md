# Gravar Extracto Bancario ABSA em Excel

Guarda o tibble devolvido por
[`processar_extracto_absa`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_absa.md)
num ficheiro Excel com um nome de ficheiro construido automaticamente a
partir dos metadados do proprio dataframe (ano, mes e data de execucao).

## Usage

``` r
gravar_extracto_absa(df, output_folder = "Dataout", quiet = TRUE)
```

## Arguments

- df:

  Um dataframe processado por
  [`processar_extracto_absa()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_absa.md).
  Deve conter as colunas `ano` e `mes`.

- output_folder:

  Caractere. Caminho para a pasta de destino onde o ficheiro Excel sera
  gravado. Por padrao `"Dataout"`. A pasta e criada automaticamente se
  nao existir.

- quiet:

  Logico. Se `TRUE` (padrao), suprime as mensagens de progresso. Se
  `FALSE`, sao emitidas mensagens sobre a criacao da pasta e o caminho
  do ficheiro gravado. Independentemente deste parametro, e sempre
  emitida uma mensagem final com o caminho do ficheiro gravado.

## Value

Invisivel: o caminho completo do ficheiro gravado (`character(1)`).
Permite encadear com `|>` se necessario.

## Details

O nome do ficheiro e construido da seguinte forma:

    <prefix>_<ano>_<mes>_<YYYYMMDD>.xlsx
    # exemplo: extracto_absa_2026_February_20260401.xlsx

Os valores de `ano` e `mes` sao extraidos das linhas `MOVIMENTO` do
dataframe (excluindo as linhas de saldo, que podem ter datas atipicas).
Se o dataframe nao contiver movimentos, os valores sao retirados de
todas as linhas.

## Examples

``` r
if (FALSE) { # \dontrun{
df_absa <- processar_extracto_absa("Data/razao_cont/2026_02/outro/")

# Gravar com as definicoes predefinidas
gravar_extracto_absa(df_absa)
# -> Dataout/extracto_absa_2026_February_20260401.xlsx

# Pasta de destino personalizada, sem data no nome
gravar_extracto_absa(df_absa, output_path = "Dataout/banco", include_date = FALSE)
# -> Dataout/banco/extracto_absa_2026_February.xlsx
} # }
```
