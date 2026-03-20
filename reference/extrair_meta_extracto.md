# Extrair metadados de ficheiros de extracto e-SISTAFE

Extrai metadados relevantes a partir dos nomes de ficheiros de
exportação do e-SISTAFE, incluindo o tipo de relatório, datas de
referência e de extracção, ano e mês em português. Suporta um ou
múltiplos ficheiros.

## Usage

``` r
extrair_meta_extracto(caminho)
```

## Arguments

- caminho:

  Um vector de caracteres com um ou mais caminhos completos ou relativos
  para ficheiros de exportação e-SISTAFE. Os nomes dos ficheiros devem
  seguir a convenção de nomenclatura padrão do e-SISTAFE, contendo
  padrões de data no formato `YYYYMMDD`.

## Value

Um tibble com uma linha por ficheiro e as seguintes colunas:

- file_name:

  Nome do ficheiro sem o caminho completo.

- reporte_tipo:

  Tipo de relatório classificado a partir do nome do ficheiro. Um de
  `"Funcionamento"`, `"Investimento Externo"`, `"Investimento Interno"`,
  ou `NA` se não reconhecido.

- data_reporte:

  Data de referência do relatório como objecto `Date`, extraída do
  primeiro padrão `YYYYMMDD` no nome do ficheiro.

- data_extraido:

  Data de extracção do ficheiro como objecto `Date`, extraída do segundo
  padrão `YYYYMMDD` no nome do ficheiro.

- ano:

  Ano da data de referência como inteiro.

- mes:

  Mês da data de referência em português (ex. `"Janeiro"`).

## Details

A classificação do tipo de relatório é feita por detecção de padrões no
nome do ficheiro:

- `"InvestimentoCompExterna"` → `"Investimento Externo"`

- `"InvestimentoCompInterna"` → `"Investimento Interno"`

- `"OrcamentoFuncionamento"` → `"Funcionamento"`

Se nenhum padrão for reconhecido, `reporte_tipo` é `NA`.

As datas são extraídas pelo padrão regex `\d{8}` — espera-se que o
primeiro match corresponda à data de referência do relatório e o segundo
à data de extracção.

## Examples

``` r
if (FALSE) { # \dontrun{
# Ficheiro único
extrair_meta_extracto("Data/DemonstrativoConsolidadoOrcamentoFuncionamento_20251231_20260205.xlsx")

# Múltiplos ficheiros
path_files <- list.files("Data/", pattern = "\\.xlsx$", full.names = TRUE)
extrair_meta_extracto(path_files)
} # }
```
