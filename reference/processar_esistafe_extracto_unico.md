# Processar um ficheiro extraido do e-SISTAFE

Esta função processa um ficheiro individual do e-SISTAFE, executando um
conjunto estruturado de operações para produzir um extracto totalmente
consolidado e não duplicado a partir dos diferentes níveis hierárquicos
de CED (A, B, C e D).

## Usage

``` r
processar_esistafe_extracto_unico(caminho, lista_ugb)
```

## Arguments

- caminho:

  Caminho completo do ficheiro Excel a ser processado.

- lista_ugb:

  Vetor de códigos UGB a manter (os restantes são marcados como
  "Remove").

## Value

Um tibble contendo o extracto processado e consolidado para um único
ficheiro, sem duplicações e com o nível hierárquico final escolhido
automaticamente.

## Details

O processamento inclui:

- limpeza e normalização do extracto original;

- classificação do grupo CED para cada linha (A, B, C, D);

- aplicação de regras de subtração hierárquica entre níveis:

  - C → D

  - B → D

  - A → D

  - B → C

  - A → C

  - A → B

- atribuição de prioridade (D \> C \> B \> A) e seleção do valor final;

- devolução de um extracto “único” representando o nível mais granular
  disponível.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- processar_esistafe_extracto_unico(
  caminho = "Data/Extracto_20240201.xlsx",
  lista_ugb = c("010100001")
)
} # }
```
