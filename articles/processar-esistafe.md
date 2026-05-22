# Processar dados do e-SISTAFE

## Introdução

Este documento explica como utilizar o pacote `easystafe` para
automatizar a criação de um conjunto de dados analíticos a partir de
exportações do e-SISTAFE. Com um conjunto reduzido de funções
encadeadas, o pacote elimina a necessidade de realizar trabalhos manuais
morosos, tais como filtrar exportações para obter apenas os dados
sectoriais, eliminar duplicações hierárquicas e adicionar metadados
descritivos para análise.

O pipeline actual do `easystafe` permite:

- Carregar e processar múltiplas pastas de extractos e-SISTAFE em
  sequência, juntando os resultados automaticamente;
- Limpar, padronizar e filtrar os dados por UGB do sector;
- Classificar e desduplicar as entradas CED através de subtracção
  hierárquica;
- Enriquecer o dataset com informação descritiva (província, distrito,
  nível funcional, tipo de programa);
- Gravar os dados processados em formato Parquet e Excel, prontos para
  análise.

Esta abordagem baseada em código processa vários periodos de dados em
segundos, em comparação com os dias ou semanas necessárias para realizar
o mesmo trabalho manualmente em Excel.

------------------------------------------------------------------------

## Etapas do Processamento

    Ficheiros e-SISTAFE (em pastas YYYYMM/)
              │
              ▼
      2. Detectar extractos e-SISTAFE gravados em pastas
              │
              ▼
      3. Para cada pasta:
         a. Carregar ficheiros
         b. Extrair ano/mês do nome da pasta
         c. Extrair metadados do nome do ficheiro
         d. Limpar e padronizar colunas
         e. Filtrar UGBs do sector
         f. Classificação CED
         g. Subtracção hierárquica (desduplicação)
         h. Identificação e correcção de valores negativos
              │
              ▼
      4. Juntar dados dos periodos contidos nos ficheiros
              │
              ▼
      5. Enriquecer com metadados descritivos
              │
              ▼
      6. Gravar ficheiro final (Parquet + Excel)

------------------------------------------------------------------------

## Pré-requisitos

Antes de executar o pipeline, certifique-se de que:

1.  O pacote `easystafe` está instalado e carregado.
2.  Os ficheiros de extracto do e-SISTAFE estão organizados em pastas
    com o formato `YYYYMM` (por exemplo, `Data/202602/`). Este formato é
    obrigatório para que o pacote consiga derivar automaticamente o ano
    e o mês de cada extracto.
3.  O ficheiro de lookup (`lookup.xlsx`) está disponível e contém as
    folhas `ugb`, `funcao` e `programa`.

## Carregar Pacotes

``` r

library(dplyr)
library(purrr)
library(readxl)
library(writexl)
library(janitor)
library(glue)
library(arrow)
library(easystafe)
```

------------------------------------------------------------------------

## Passo 1: Definir Variáveis Globais

O pipeline começa com a definição de dois objectos: o caminho para o
ficheiro de lookup e um vector com os caminhos das pastas de extractos a
processar.

``` r

# Ficheiro Excel com as tabelas de referência
metadata_lookup <- "Documents/lookup.xlsx"

# Vector de pastas — cada uma corresponde a um mês de extractos
paths_esistafe <- c(
  "Data/202601",
  "Data/202602",
  "Data/202603",
  "Data/202604"
)
```

A convenção de nomenclatura `YYYYMM` não é apenas organização. O pacote
lê o nome da pasta para extrair automaticamente `ano` e `mes` para cada
linha do dataset. Se uma pasta não seguir este formato, as colunas serão
preenchidas com `NA` e será emitido um aviso.

------------------------------------------------------------------------

## Passo 2: Carregar os Lookups

A função
[`carregar_lookups_esistafe()`](https://moz-gpe.github.io/easystafe/reference/carregar_lookups_esistafe.md)
lê as três folhas obrigatórias do ficheiro de referência e devolve uma
lista pronta a ser utilizada no resto do pipeline.

``` r

lookups <- carregar_lookups_esistafe(metadata_lookup)
```

A lista `lookups` contém três elementos:

| Elemento | Folha Excel | Chave de ligação | Colunas principais adicionadas |
|----|:--:|:--:|----|
| `lookups$ugb` | `ugb` | `codigo_ugb` | `provincia`, `distrito`, `ambito`, `descricao` |
| `lookups$funcao` | `funcao` | `funcao` | `funcao_nivel` |
| `lookups$programa` | `programa` | `programa` | `programa_tipo` |

A função valida a presença das três folhas antes de tentar ler qualquer
dado. Se alguma estiver ausente, é emitido um erro claro com o nome da
folha em falta.

------------------------------------------------------------------------

## Passo 3: Processar os Extractos

Esta é a etapa central do pipeline. A função
[`processar_extracto_esistafe()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_esistafe.md)
é aplicada a cada pasta através de
[`map()`](https://purrr.tidyverse.org/reference/map.html), e os
resultados são combinados com
[`list_rbind()`](https://purrr.tidyverse.org/reference/list_c.html).

``` r

df_esistafe <- paths_esistafe |>
  map(\(path) processar_extracto_esistafe(
    source_path           = path,
    df_ugb_lookup         = lookups$ugb,
    include_percent       = FALSE,
    include_file_metadata = TRUE,
    include_metrica       = TRUE,
    correct_negatives     = TRUE,
    quiet                 = FALSE
  )) |>
  list_rbind()
```

### Argumentos Principais

| Argumento | Argumento port Defeito | O que faz |
|----|:--:|----|
| `source_path` | cada `path` | Pasta com os ficheiros `.xlsx` a processar |
| `df_ugb_lookup` | `lookups$ugb` | Tabela de referência de UGBs do MEC |
| `include_percent` | `FALSE` | Remove as colunas de percentagem do output |
| `include_file_metadata` | `TRUE` | Adiciona `reporte_tipo`, `data_reporte` e `data_extraido` ao dataset |
| `include_metrica` | `TRUE` | Mantém as linhas de métrica (para validação) além das linhas de valor |
| `correct_negatives` | `TRUE` | Detecta e corrige valores negativos, criando linhas de auditoria |
| `quiet` | `FALSE` | Mostra mensagens de progresso durante o processamento |

### Exemplo de Mensagens de Progresso (`quiet = FALSE`)

Enquanto cada pasta é processada, verá mensagens como:

    A identificar ficheiros...
    3 ficheiro(s) encontrado(s). A carregar...
    Ficheiros carregados: 3 | Linhas: 18 204
    A adicionar pasta_fonte, ano e mes...
    A extrair e adicionar metadados...
    A limpar nomes de colunas...
    A filtrar UGB's de educação...
    A classificar grupos CED e remover grupo D...
    A executar subtracção hierárquica — Passo 1 (A → B)...
    A executar subtracção hierárquica — Passo 2 (B → C)...
    A executar subtracção hierárquica — Passo 3 (A directo → C)...
    Correcção de negativos: 4 ugb_funcao_prog_fr(s) identificado(s) e corrigido(s).
      Soma absoluta dos valores negativos convertidos a zero: 12,340 (0.03% da soma total)
    Processamento concluído: 3 ficheiro(s) processado(s) com sucesso.

------------------------------------------------------------------------

## Passo 4: Enriquecer com Metadados Descritivos

Após combinar todos os meses, a função
[`adicionar_lookups_esistafe()`](https://moz-gpe.github.io/easystafe/reference/adicionar_lookups_esistafe.md)
junta informação descritiva ao dataset.

``` r

df_esistafe <- df_esistafe |>
  adicionar_lookups_esistafe(lookups)
```

As colunas adicionadas e o seu posicionamento no dataset:

| Origem | Colunas adicionadas |
|----|----|
| `lookups$ugb` | `provincia`, `distrito`, `ambito`, `nivel_da_instituicao`, `descricao` |
| `lookups$funcao` | `funcao_nivel` |
| `lookups$programa` | `programa_tipo` |

------------------------------------------------------------------------

## Passo 5: Gravar o Resultado

A função
[`gravar_esistafe()`](https://moz-gpe.github.io/easystafe/reference/gravar_esistafe.md)
grava o dataset final em dois formatos simultaneamente: Parquet (para
análise eficiente) e Excel (para partilha e revisão manual).

``` r

gravar_esistafe(
  df            = df_esistafe,
  output_folder = "Dataout/",
  quiet         = TRUE
)
```

O nome dos ficheiros é construído automaticamente a partir dos anos
presentes nos dados e da data de hoje. Por exemplo, para dados de 2025 e
2026 processados a 21 de Maio de 2026:

    Dataout/e-SISTAFE_2025-2026_2026-05-21.parquet
    Dataout/e-SISTAFE_2025-2026_2026-05-21.xlsx

Não é necessário definir o nome manualmente — o pacote trata disso com
base nos metadados já presentes no dataset.

A função devolve invisivelmente uma lista com os dois caminhos, que pode
capturar se necessário:

``` r

paths <- gravar_esistafe(df_esistafe, output_folder = "Dataout/", quiet = FALSE)
paths$parquet  # caminho do ficheiro Parquet
paths$excel    # caminho do ficheiro Excel
```

------------------------------------------------------------------------

## O Que Acontece Por Dentro? Uma Visão Detalhada

Esta secção explica cada etapa interna do processamento executado por
[`processar_extracto_esistafe()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_esistafe.md)
para quem quiser compreender o que acontece em cada chamada de
[`map()`](https://purrr.tidyverse.org/reference/map.html).

### Derivação de Ano e Mês

O pacote extrai `ano` e `mes` directamente do nome da pasta de origem.
Por exemplo, a pasta `"Data/202602"` produz `ano = 2026` e
`mes = "Fevereiro"` em todas as linhas do extracto correspondente.

Uma coluna `pasta_fonte` é também adicionada, contendo apenas o nome da
pasta (sem o caminho completo), o que facilita a rastreabilidade da
origem dos dados.

### Extracção de Metadados do Ficheiro

Quando `include_file_metadata = TRUE`, a função
[`extrair_meta_extracto()`](https://moz-gpe.github.io/easystafe/reference/extrair_meta_extracto.md)
analisa o **nome de cada ficheiro** para extrair o tipo de relatório e
as datas de referência e extracção. Por exemplo, a partir de:

    DemonstrativoConsolidadoOrcamentoFuncionamento_20251231_20260205.xlsx

…são extraídos:

| Campo           | Valor extraído |
|-----------------|----------------|
| `reporte_tipo`  | Funcionamento  |
| `data_reporte`  | 2025-12-31     |
| `data_extraido` | 2026-02-05     |

### Limpeza de Colunas

Os ficheiros exportados do e-SISTAFE têm nomes de colunas com espaços,
acentos e maiúsculas inconsistentes. O pipeline padroniza
automaticamente todos os nomes para o formato `snake_case` com
[`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html),
tornando o código mais fiável.

### Filtragem de UGBs do Sector da Educação

O extracto bruto contém dados de UGBs de todos os sectores. Esta etapa
compara cada linha com `lookups$ugb` e remove as linhas que não
correspondem a UGBs do MEC. O resultado é apresentado nas mensagens de
progresso:

| Classificação | Nº de Linhas (exemplo) |
|---------------|:----------------------:|
| Manter        |         8 341          |
| Remover       |         15 766         |
| **Total**     |       **24 107**       |

### Remoção de Linhas de Agregação e Classificação `data_tipo`

Os extractos contêm linhas de subtotal e cabeçalho sem dados analíticos.
O pipeline remove-as e classifica as linhas restantes na coluna
`data_tipo`:

- **`"Valor"`** — linha com código CED preenchido; representa execução
  orçamental.
- **`"Métrica"`** — linha sem CED mas com `funcao`, `programa` e `fr`
  preenchidos; útil para validação cruzada (incluída quando
  `include_metrica = TRUE`).

### Classificação dos Grupos CED (A, B, C, D)

O e-SISTAFE organiza as dotações numa hierarquia de quatro níveis:

| Grupo | Descrição                          |   Acção no pipeline   |
|-------|------------------------------------|:---------------------:|
| A     | Nível mais granular (sub-item CED) |        Manter         |
| B     | Agregação de nível intermédio      |  Manter (com ajuste)  |
| C     | Agregação de nível superior        |  Manter (com ajuste)  |
| D     | Totais gerais                      | Remover imediatamente |

### Subtracção Hierárquica (Eliminação de Dupla Contagem)

Esta é a etapa mais crítica — e a mais difícil de replicar manualmente.
Os grupos B e C incluem nos seus valores os montantes dos grupos
subordinados, o que causaria dupla contagem numa soma directa. O
pipeline resolve isto em três passos sequenciais:

**Passo 1:** Subtrair os valores do Grupo A do Grupo B correspondente
(dentro do mesmo `ced_b4`).

**Passo 2:** Subtrair o Grupo B ajustado (resultado do Passo 1) do Grupo
C correspondente (dentro do mesmo `ced_b3`).

**Passo 3:** Subtrair o Grupo A directamente do Grupo C nos casos em que
não existe um Grupo B intermédio (dentro do mesmo `ced_b3`).

Após estes três passos, a soma de todos os valores no dataframe final
representa o total real de execução orçamental, sem qualquer duplicação.

### Correcção de Valores Negativos

Quando `correct_negatives = TRUE`, o pipeline detecta e corrige valores
negativos nas 11 colunas numéricas principais:

1.  Identifica todos os `ugb_funcao_prog_fr` que contêm pelo menos um
    valor negativo.
2.  Cria uma **cópia de auditoria** dessas linhas com
    `data_tipo = "Corregido"`, preservando os valores originais para
    rastreabilidade.
3.  Substitui os valores negativos por zero nas linhas `"Valor"`
    originais.
4.  Adiciona dois indicadores binários:
    - `valor_corregido`: `1` para qualquer linha cujo grupo de
      identificação continha um negativo (independentemente da
      magnitude).
    - `valor_negativo`: `1` apenas para linhas com pelo menos um valor ≤
      −1.

Uma mensagem de resumo é sempre emitida após esta etapa, mesmo com
`quiet = TRUE`:

    Correcção de negativos: 4 ugb_funcao_prog_fr(s) identificado(s) e corrigido(s).
      Soma absoluta dos valores negativos convertidos a zero: 12,340 (0.03% da soma total
      de colunas numéricas [data_tipo == 'Valor']).

------------------------------------------------------------------------

## Resumo: Pipeline Completo

O pipeline completo para processar oito meses de extractos do e-SISTAFE
cabe em menos de 20 linhas de código:

``` r

library(dplyr)
library(purrr)
library(readxl)
library(writexl)
library(janitor)
library(glue)
library(arrow)
library(easystafe)

# Variáveis globais
metadata_lookup <- "Documents/lookup.xlsx"
paths_esistafe <- c(
  "Data/202502", "Data/202503", "Data/202504", "Data/202512",
  "Data/202601", "Data/202602", "Data/202603", "Data/202604"
)

# Carregar lookups
lookups <- carregar_lookups_esistafe(metadata_lookup)

# Processar, combinar e enriquecer
df_esistafe <- paths_esistafe |>
  map(\(path) processar_extracto_esistafe(
    source_path           = path,
    df_ugb_lookup         = lookups$ugb,
    include_percent       = FALSE,
    include_file_metadata = TRUE,
    include_metrica       = TRUE,
    correct_negatives     = TRUE,
    quiet                 = TRUE
  )) |>
  list_rbind() |>
  adicionar_lookups_esistafe(lookups)

# Gravar (Parquet + Excel)
gravar_esistafe(df_esistafe, output_folder = "Dataout/")
```

O resultado são dois ficheiros prontos para análise — produzidos em
segundos, com total rastreabilidade de cada decisão tomada durante o
processamento.

------------------------------------------------------------------------

*Para mais informações sobre as funções individuais do pacote, consulte
a documentação com
[`?processar_extracto_esistafe`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_esistafe.md),
[`?carregar_lookups_esistafe`](https://moz-gpe.github.io/easystafe/reference/carregar_lookups_esistafe.md),
[`?adicionar_lookups_esistafe`](https://moz-gpe.github.io/easystafe/reference/adicionar_lookups_esistafe.md)
e
[`?gravar_esistafe`](https://moz-gpe.github.io/easystafe/reference/gravar_esistafe.md).*
