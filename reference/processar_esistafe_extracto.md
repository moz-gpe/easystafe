# Deduplicação de múltiplos extractos do e-SISTAFE com inclusão automática de metadados

Esta função aplica
[`processar_esistafe_extracto_unico()`](https://moz-gpe.github.io/easystafe/reference/processar_esistafe_extracto_unico.md)
a vários ficheiros de extracto do e-SISTAFE, elimina duplicações ao
combinar os resultados e acrescenta metadados extraídos automaticamente
do nome de cada ficheiro através de
[`extrair_meta_extracto()`](https://moz-gpe.github.io/easystafe/reference/extrair_meta_extracto.md).

## Usage

``` r
processar_esistafe_extracto(caminhos, lista_ugb)
```

## Arguments

- caminhos:

  Vetor com os caminhos completos dos ficheiros a processar.

- lista_ugb:

  Vetor de UGBs válidas a passar para
  [`processar_esistafe_extracto_unico()`](https://moz-gpe.github.io/easystafe/reference/processar_esistafe_extracto_unico.md).

## Value

Um `tibble` consolidado contendo os dados processados de todos os
ficheiros, incluindo metadados adicionais.

## Details

O processo inclui:

- deduplicação após o processamento dos extractos individuais;

- extração e anexação automática de metadados (tipo de reporte, datas,
  mês, ano);

- gestão robusta de erros (ficheiros problemáticos não interrompem o
  fluxo).

## Examples

``` r
if (FALSE) { # \dontrun{
arquivos <- list.files("Data/", pattern = "\\\\.xlsx$", full.names = TRUE)
df <- processar_esistafe_extracto(
  caminhos   = arquivos,
  lista_ugb = c("010100001", "010100003")
)
} # }
```
