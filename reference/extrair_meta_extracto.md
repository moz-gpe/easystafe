# Extrair metadados a partir do nome de um ficheiro de extracto e-SISTAFE

Esta função lê o nome de um ficheiro do e-SISTAFE e extrai metadados
estruturados, incluindo:

## Usage

``` r
extrair_meta_extracto(caminho)
```

## Arguments

- caminho:

  Caminho ou nome do ficheiro a partir do qual extrair metadados.

## Value

Um tibble com as seguintes colunas:

- file_name:

  Nome do ficheiro.

- reporte_tipo:

  Classificação do tipo de reporte.

- data_reporte:

  Data de referência (classe `Date`).

- data_extraido:

  Data de extração (classe `Date`).

- ano:

  Ano extraído da data de referência.

- mes:

  Nome do mês (Português) correspondente à data de referência.

## Details

- tipo de reporte (Funcionamento, Investimento Interno, Investimento
  Externo);

- data de referência (a primeira data YYYYMMDD presente no nome);

- data de extração (a segunda data YYYYMMDD, se existir);

- ano e mês de referência, com nome do mês em Português.

A função procura padrões `\d{8}` no nome do ficheiro. O primeiro padrão
encontrado é assumido como data de referência e o segundo como data de
extração.

## Examples

``` r
if (FALSE) { # \dontrun{
extrair_meta_extracto(
  "OrcamentoFuncionamento_20240101_20240115.xlsx"
)
} # }
```
