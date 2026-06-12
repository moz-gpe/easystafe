# Compilar ficheiros eSISTAFE processados num unico Excel

Localiza todos os ficheiros Excel com o padrao `"eSISTAFE_"` numa pasta
de entrada, combina-os num unico tibble e grava o resultado em disco.

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

  Caractere. Caminho para a pasta de destino. Por padrao `"Dataout"`. A
  pasta e criada automaticamente se nao existir.

- quiet:

  Logico. Se `TRUE` (padrao), suprime as mensagens de progresso.

## Value

Invisivel: o caminho completo do ficheiro gravado (`character(1)`).

## Examples

``` r
if (FALSE) { # \dontrun{
gravar_compilacao_sistafe()
gravar_compilacao_sistafe(input_folder = "Data/processed", output_folder = "Dataout/compilado")
} # }
```
