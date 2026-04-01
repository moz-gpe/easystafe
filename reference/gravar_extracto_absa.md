# Gravar Extracto Bancario ABSA em Excel

Guarda o tibble devolvido por
[`processar_extracto_absa`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_absa.md)
num ficheiro Excel com um nome de ficheiro construido automaticamente a
partir dos metadados do proprio dataframe (ano, mes e data de execucao).

## Usage

``` r
gravar_extracto_absa(
  df,
  output_path = "Dataout",
  prefix = "extracto_absa",
  include_date = TRUE,
  overwrite = FALSE,
  verbose = TRUE
)
```

## Arguments

- df:

  `data.frame` ou `tibble`. O objecto devolvido por
  [`processar_extracto_absa`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_absa.md).
  Deve conter pelo menos as colunas `ano` e `mes`.

- output_path:

  `character(1)`. Caminho para a pasta de destino. A pasta e criada
  automaticamente se nao existir. Default: `"Dataout"`.

- prefix:

  `character(1)`. Prefixo do nome de ficheiro. Permite identificar o
  tipo de extracto. Default: `"extracto_absa"`.

- include_date:

  `logical(1)`. Se `TRUE`, acrescenta a data de execucao (`YYYYMMDD`) ao
  nome do ficheiro, evitando sobreescritas acidentais. Default: `TRUE`.

- overwrite:

  `logical(1)`. Se `FALSE` e o ficheiro ja existir, a funcao lanca um
  erro em vez de sobreescrever. Default: `FALSE`.

- verbose:

  `logical(1)`. Se `TRUE`, imprime o caminho completo do ficheiro
  gravado. Default: `TRUE`.

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
