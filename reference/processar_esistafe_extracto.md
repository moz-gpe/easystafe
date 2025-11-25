# Processar ficheiros extraídos do e-SISTAFE

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

O fluxo inclui:

- deduplicação após o processamento dos extractos individuais;

- extração e anexação automática de metadados (tipo de reporte, datas,
  mês, ano);

- gestão robusta de erros (ficheiros problemáticos não interrompem o
  fluxo).

### Variáveis financeiras disponíveis no dataframe final

O dataframe final contém métricas orçamentais padronizadas do e-SISTAFE.
Cada variável representa uma etapa do ciclo orçamental: dotação →
disponibilização → cabimentação → liquidação → pagamento.

#### Lista de variáveis financeiras

- **dotacao_inicial** (*Dotação Inicial*) — Alocação inicial aprovada no
  Orçamento do Estado.

- **dotacao_revista** (*Dotação Revista*) — Alocação revista formalmente
  pelo Parlamento.

- **dotacao_actualizada** (*Dotação Actualizada – DA*) — Atualizações
  feitas pelo MEF dentro dos limites legais, sem revisão parlamentar.

- **dotacao_disponivel** (*Dotação Disponível*) — Liquidez efetivamente
  disponibilizada para execução.

- **dotacao_cabimentada** (*Dotação Cabimentada – DC*) — Montante
  cabimentado/comprometido com base na liquidez disponível.

- **ad_fundos** (*Adiantamento de Fundos – AF*) — Valores adiantados
  antes da execução; inclui, por exemplo, o mecanismo ADE para escolas.

- **despesa_paga_via_directa** (*Despesa Paga Via Directa – DP*) —
  Pagamentos efetuados diretamente ao fornecedor via e-SISTAFE.

- **ad_fundos_mais_dpvd** (*AFDP – Adiantamento de Fundos + Despesa Paga
  VD*) — Soma dos adiantamentos de fundos e das despesas pagas via
  direta.

- **liq_ad_fundos** (*LAF – Adiantamentos de Fundos Liquidados*) —
  Adiantamentos para os quais já existe fatura aceite, pendentes de
  pagamento.

- **despesa_liquidada_via_directa** (*LVD – Despesa Liquidada Via
  Directa*) — Despesas liquidadas diretamente no e-SISTAFE, com
  documento de liquidação emitido.

- **liq_ad_fundos_via_directa_lafvd** (*LAFVD – Liquidação de AF + Via
  Directa*) — Total de liquidações combinando adiantamentos liquidados e
  despesas liquidadas via direta.

## Examples

``` r
if (FALSE) { # \dontrun{
arquivos <- list.files("Data/", pattern = "\\\\.xlsx$", full.names = TRUE)
df <- processar_esistafe_extracto(
  caminhos = arquivos,
  lista_ugb = c("010100001", "010100003")
)
} # }
```
