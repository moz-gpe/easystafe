# Carregar lookups descritivos para enriquecimento de dados e-SISTAFE

Le e processa as tabelas de referencia de UGBs, funcoes e programas a
partir de um ficheiro Excel, devolvendo uma lista nomeada pronta a ser
passada a
[`adicionar_lookups_esistafe()`](https://moz-gpe.github.io/easystafe/reference/adicionar_lookups_esistafe.md).

## Usage

``` r
carregar_lookups_esistafe(path)
```

## Arguments

- path:

  Um caracter com o caminho completo ou relativo para o ficheiro Excel
  que contem as folhas de lookup. Deve conter as folhas `"ugb"`,
  `"funcao"`, `"programa"`, `"ced"`, `"ced_2"`, `"ced_3"` e
  `"ced_nivel"`.

## Value

Uma lista nomeada com oito elementos:

- ugb:

  Dataframe com colunas `codigo_ugb`, `provincia`, `distrito`, `ambito`,
  colunas com prefixo `adm`, `nivel_da_instituicao` e `descricao`.
  Linhas com `codigo_ugb == "Total"` sao removidas.

- funcao:

  Dataframe com colunas `funcao` e `funcao_nivel`. Linhas com `funcao`
  em branco sao removidas.

- programa:

  Dataframe com colunas `programa_ambito_fr` e `programa_tipo`. Linhas
  com `programa_tipo` em branco sao removidas. Usado para anos
  diferentes de 2025.

- programa2025:

  Dataframe com colunas `programa_ambito_fr_funcao` e `programa_tipo`.
  Linhas com `programa_tipo` em branco sao removidas. Usado para o ano
  2025.

- ced:

  Dataframe com colunas `ced` e `ced_nome`.

- ced_2:

  Dataframe com colunas `ced_2` e `ced_2_nome`. Chave de 6 digitos
  construida com os 2 primeiros digitos do CED mais `"0000"`.

- ced_3:

  Dataframe com colunas `ced_3` e `ced_3_nome`. Chave de 6 digitos
  construida com os 3 primeiros digitos do CED mais `"000"`.

- ced_nivel:

  Dataframe com colunas `ced_3_nome` e `ced_nivel`. Classifica cada
  agrupamento de nivel 3 do CED com o seu nivel hierarquico.

## Details

A funcao valida a presenca de todas as folhas obrigatorias antes de
tentar ler qualquer dado. Se alguma folha estiver ausente, e emitido um
[`stop()`](https://rdrr.io/r/base/stop.html) imediato com o nome da
folha em falta.

A leitura e feita com
[`suppressMessages()`](https://rdrr.io/r/base/message.html) para
suprimir os avisos de tipo de coluna emitidos por
[`readxl::read_excel()`](https://readxl.tidyverse.org/reference/read_excel.html).

## Examples

``` r
if (FALSE) { # \dontrun{
lookups <- carregar_lookups_esistafe("Data/Metadados esistafe.xlsx")

# Usar directamente com adicionar_lookups_esistafe()
df <- adicionar_lookups_esistafe(df_esistafe, lookups)
} # }
```
