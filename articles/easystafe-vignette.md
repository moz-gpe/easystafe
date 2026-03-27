# Automatização do Processamento de Extractos do e-SISTAFE

## Introdução

Este documento explica como utilizar o pacote **easystafe** para
automatizar o processamento dos extractos exportados do sistema
e-SISTAFE, no contexto da Direcção de Administração e Finanças (DAF) do
Ministério da Educação e Cultura (MEC).

Actualmente, a preparação destes dados para análise é frequentemente
feita de forma manual. Este trabalho consome tempo, é propenso a erros,
e dificulta a verificação posterior das decisões tomadas durante a
limpeza dos dados.

O pacote **easystafe** resolve este problema. Com poucas linhas de
código em R, é possível:

- Carregar automaticamente vários ficheiros extraídos do e-SISTAFE de
  uma pasta;
- Extrair os metadados relevantes a partir dos nomes dos ficheiros
  (período de reporte, tipo de relatório, etc.);
- Limpar e padronizar as colunas dos dados;
- Filtrar os UGBs pertencentes ao sector da Educação;
- Classificar e desduplicar as entradas CED através de subtracção
  hierárquica;
- Gravar os dados processados num ficheiro Excel pronto para análise.

O processo completo demora apenas alguns segundos e produz sempre o
mesmo resultado independentemente de quem o executa ou quando.

------------------------------------------------------------------------

## Visão Geral do Pipeline

O diagrama abaixo mostra as etapas principais do pipeline de
processamento:

    Ficheiros Excel (exportados do e-SISTAFE)
              │
              ▼
      1. Carregar ficheiros
              │
              ▼
      2. Extrair metadados
              │
              ▼
      3. Limpar colunas
              │
              ▼
      4. Filtrar para linhas de Educação
              │
              ▼
      5. Subtracção hierárquica (desduplicação)
              │
              ▼
      6. Gravar ficheiro final

------------------------------------------------------------------------

## Pré-requisitos

Antes de executar o pipeline, certifique-se de que:

1.  O pacote **easystafe** está instalado e carregado.
2.  Os ficheiros de extracto exportados do e-SISTAFE estão guardados
    numa pasta acessível (por exemplo, `"Data/"`).
3.  O ficheiro de referência de UGBs de educação está disponível em
    `"Documentos/Codigos de UGBs.xlsx"`, na folha `"UGBS"`.

``` r
library(easystafe)
library(readxl)
library(dplyr)
library(gt)
```

------------------------------------------------------------------------

## Passo 1: Carregar a Tabela de Referência de UGBs

O pipeline precisa de saber quais UGBs pertencem ao sector da educação.
Esta informação está guardada numa tabela de referência externa que
carregamos antes de iniciar o processamento.

``` r
ugb_lookup <- read_excel(
  "Documents/Codigos de UGBs.xlsx",
  sheet = "UGBS"
)
```

Esta tabela contém os nomes e códigos de todos os UGBs do sector da
educação. É ela que determina quais linhas do extracto são mantidas na
etapa de filtragem.

------------------------------------------------------------------------

## Passo 2: Definir o Caminho para os Ficheiros de Extracto

``` r
pasta_extractos <- "Data/extractos/"
```

Todos os ficheiros `.xlsx` presentes nesta pasta serão processados
automaticamente. Não é necessário abrir os ficheiros um a um.

------------------------------------------------------------------------

## Passo 3: Executar o Pipeline Completo

Com apenas uma função — `processar_extracto_sistafe()` — o pacote
executa todas as etapas de limpeza, filtragem, classificação e
desduplicação:

``` r
df_processado <- processar_extracto_sistafe(
  source_path    = pasta_extractos,
  ugb_lookup     = ugb_lookup,
  include_meta   = TRUE,
  include_percent = FALSE,
  quiet          = FALSE
)
```

O argumento `quiet = FALSE` faz com que o R mostre mensagens de
progresso durante o processamento — útil para acompanhar o que está a
acontecer, especialmente da primeira vez.

Enquanto o pipeline corre, verá mensagens como:

    ✔ 12 ficheiros carregados.
    ✔ Metadados extraídos.
    ✔ Colunas limpas.
    ✔ Filtragem de UGBs aplicada: 8 341 linhas mantidas de 24 107.
    ✔ Classificação CED concluída.
    ✔ Subtracção hierárquica aplicada.

------------------------------------------------------------------------

## O Que Acontece Por Dentro? Uma Visão Detalhada

Esta secção explica cada etapa do pipeline para quem quiser compreender
o que a função `processar_extracto_sistafe()` faz internamente.

### 3.1 Extracção de Metadados

A função
[`extrair_meta_extracto()`](https://moz-gpe.github.io/easystafe/reference/extrair_meta_extracto.md)
analisa automaticamente o **nome de cada ficheiro** para extrair
informação sobre o período de reporte.

Por exemplo, a partir de um nome como:

    Funcionamento_2025_Dezembro_DAF_UGB123.xlsx

…a função extrai:

| Campo          | Valor extraído |
|----------------|----------------|
| `reporte_tipo` | Funcionamento  |
| `ano`          | 2025           |
| `mes`          | Dezembro       |
| `ugb_id`       | UGB123         |

Desta forma, não é necessário abrir cada ficheiro para saber a que
período pertence — o nome do ficheiro já contém essa informação.

### 3.2 Limpeza de Colunas

Os ficheiros exportados do e-SISTAFE têm nomes de colunas com espaços,
acentos e maiúsculas inconsistentes. O pipeline padroniza
automaticamente todos os nomes de colunas para o formato `snake_case`
(minúsculas, sem espaços), tornando o código mais fiável e previsível.

### 3.3 Filtragem de UGBs do Sector da Educação

Muitos extractos contêm dados de UGBs que não pertencem ao sector da
educação. Esta etapa compara cada linha do extracto com a tabela de
referência de UGBs e remove as linhas que não correspondem a nenhum UGB
de educação.

O resultado é apresentado antes e depois do filtro para que seja
possível verificar quantas linhas foram removidas:

| Classificação | Nº de Linhas |
|---------------|:------------:|
| Manter        |    8 341     |
| Remover       |    15 766    |
| **Total**     |  **24 107**  |

### 3.4 Remoção de Linhas de Agregação

Os extractos do e-SISTAFE contêm linhas de subtotal e cabeçalho que não
representam transacções individuais. Estas linhas são identificadas e
removidas, mantendo apenas as linhas com dados analíticos completos.

Especificamente, são mantidas apenas as linhas que:

- Têm um código CED preenchido (*linhas de Valor*), **ou**
- Têm os campos `funcao`, `programa` e `fr` todos preenchidos (*linhas
  de Métrica*).

### 3.5 Classificação dos Grupos CED (A, B, C, D)

O e-SISTAFE organiza as dotações numa hierarquia de quatro níveis, que o
pacote designa por grupos A, B, C e D:

| Grupo | Descrição                          | Acção no pipeline |
|-------|------------------------------------|:-----------------:|
| A     | Nível mais granular (sub-item CED) |      Manter       |
| B     | Agregação de nível intermédio      | Manter (ajustar)  |
| C     | Agregação de nível superior        | Manter (ajustar)  |
| D     | Totais gerais                      |      Remover      |

O grupo D é removido imediatamente por representar apenas somas de topo
que duplicariam os valores dos outros grupos.

### 3.6 Subtracção Hierárquica (Eliminação de Dupla Contagem)

Esta é a etapa mais importante — e a mais difícil de fazer correctamente
de forma manual. Os grupos B e C incluem nos seus valores os montantes
dos grupos que lhes estão subordinados, o que causaria dupla contagem se
somássemos todos os grupos directamente.

O pipeline resolve isto em três passos sequenciais:

**Passo 1:** Subtrair os valores do Grupo A do Grupo B correspondente
(dentro do mesmo `ced_b4`).

**Passo 2:** Subtrair o Grupo B ajustado (resultado do Passo 1) do Grupo
C correspondente (dentro do mesmo `ced_b3`).

**Passo 3:** Subtrair o Grupo A directamente do Grupo C nos casos em que
não existe um Grupo B intermédio (dentro do mesmo `ced_b3`).

Após estes três passos, a soma de todos os valores no dataframe final
representa o total real de execução orçamental, sem qualquer duplicação.

------------------------------------------------------------------------

## Passo 4: Verificar o Resultado

Antes de guardar, é boa prática verificar o resultado com uma breve
inspecção. O código abaixo mostra um resumo por tipo de relatório e mês:

``` r
df_processado |>
  count(reporte_tipo, ano, mes, name = "n_linhas") |>
  gt() |>
  cols_label(
    reporte_tipo = "Tipo de Relatório",
    ano          = "Ano",
    mes          = "Mês",
    n_linhas     = "Nº de Linhas"
  ) |>
  tab_header(title = "Resumo do Extracto Processado") |>
  grand_summary_rows(
    columns = n_linhas,
    fns     = list(Total ~ sum(.)),
    fmt     = ~ fmt_integer(.)
  )
```

------------------------------------------------------------------------

## Passo 5: Guardar o Resultado em Excel

A função
[`gravar_extracto_sistafe()`](https://moz-gpe.github.io/easystafe/reference/gravar_extracto_sistafe.md)
guarda o dataframe processado num ficheiro Excel, construindo
automaticamente o nome do ficheiro a partir dos metadados (tipo de
relatório, ano, mês e data de hoje):

``` r
gravar_extracto_sistafe(
  df            = df_processado,
  output_folder = "Dataout/"
)
```

O ficheiro será guardado com um nome no formato:

    Funcionamento_2025_Dezembro_20260327.xlsx

Não é necessário definir o nome manualmente — o pacote trata disso
automaticamente.

------------------------------------------------------------------------

## Resumo

Com o pacote **easystafe**, o processamento completo de um mês de
extractos do e-SISTAFE pode ser feito com menos de 10 linhas de código:

``` r
library(easystafe)
library(readxl)

ugb_lookup <- read_excel("Data/ugb/Codigos de UGBs.xlsx", sheet = "UGBS")

df_processado <- processar_extracto_sistafe(
  source_path     = "Data/extractos/",
  ugb_lookup      = ugb_lookup,
  include_meta    = TRUE,
  include_percent = FALSE,
  quiet           = TRUE
)

gravar_extracto_sistafe(df = df_processado, output_folder = "Dataout/")
```

O resultado é um ficheiro Excel limpo, consistente e pronto para análise
— produzido em segundos, com total rastreabilidade de cada decisão
tomada durante o processamento.

------------------------------------------------------------------------

*Para mais informações sobre as funções individuais do pacote, consulte
a documentação com `?processar_extracto_sistafe`,
[`?extrair_meta_extracto`](https://moz-gpe.github.io/easystafe/reference/extrair_meta_extracto.md),
e
[`?gravar_extracto_sistafe`](https://moz-gpe.github.io/easystafe/reference/gravar_extracto_sistafe.md).*
