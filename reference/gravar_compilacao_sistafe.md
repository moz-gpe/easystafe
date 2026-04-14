# Compilar ficheiros eSISTAFE processados num unico Excel

Localiza todos os ficheiros Excel com o padrao `"eSISTAFE_"` numa pasta
de entrada, combina-os num unico tibble e grava o resultado em disco. O
nome do ficheiro de saida e construido automaticamente a partir do
intervalo de anos presente nos dados.

## Usage

``` r
gravar_compilacao_sistafe(
  input_folder = "Data/processed",
  output_folder = "Dataout",
  quiet = TRUE
)
```

## Arguments

- input_folder:

  Caractere. Caminho para a pasta que contem os ficheiros Excel a
  compilar. Por padrao `"Data/processed"`.

- output_folder:

  Caractere. Caminho para a pasta de destino onde o ficheiro compilado
  sera gravado. Por padrao `"Dataout"`. A pasta e criada automaticamente
  se nao existir.

- quiet:

  Logico. Se `TRUE` (padrao), suprime as mensagens de progresso. Se
  `FALSE`, sao emitidas mensagens detalhadas sobre os ficheiros
  encontrados e o caminho do ficheiro gravado.

## Value

Invisivel: o caminho completo do ficheiro gravado (`character(1)`).

## Details

A funcao pesquisa ficheiros cujo nome comeca com `"eSISTAFE_"` na pasta
`input_folder` (apenas o nivel de topo, sem subpastas). Todos os
ficheiros encontrados sao lidos e combinados por
[`dplyr::bind_rows()`](https://dplyr.tidyverse.org/reference/bind_rows.html).

O nome do ficheiro de saida segue o formato:

    eSISTAFE_<ano_min>-<ano_max>.xlsx  # quando ha multiplos anos
    eSISTAFE_<ano>.xlsx                # quando todos os dados sao do mesmo ano

Se um ficheiro com o mesmo nome ja existir em `output_folder`, sera
substituido com aviso.

## Examples

``` r
if (FALSE) { # \dontrun{
# Compilar com pastas predefinidas
gravar_compilacao_sistafe()

# Pastas personalizadas
gravar_compilacao_sistafe(
  input_folder  = "Data/processed",
  output_folder = "Dataout/compilado"
)

# Com mensagens de progresso
gravar_compilacao_sistafe(quiet = FALSE)
} # }
```
