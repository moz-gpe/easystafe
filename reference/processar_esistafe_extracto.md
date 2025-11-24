# Processar ficheiros extraidos do e-SISTAFE

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

### Variáveis financeiras disponíveis no dataframe final

O dataframe final contém um conjunto de métricas orçamentais
padronizadas do e-SISTAFE, incluindo:

- **Dotação Inicial (dotacao_inicial)** — Alocação inicial aprovada no
  Orçamento do Estado.

- **Dotação Revista (dotacao_revista)** — Alocação revista formalmente
  pelo Parlamento.

- **Dotação Actualizada – DA (dotacao_actualizada)** — Atualizações
  efetuadas pelo MEF dentro dos limites legais, sem revisão parlamentar.

- **Dotação Disponível (dotacao_disponivel)** — Liquidez efetivamente
  disponibilizada.

- **Dotação Cabimentada – DC (dotacao_cabimentada)** — Montante
  cabimentado/comprometido.

- **Adiantamento de Fundos – AF (ad_fundos)** — Montantes adiantados
  antes da execução; inclui, por exemplo, o ADE para escolas.

- **Despesa Paga Via Directa – DP (despesa_paga_via_directa)** —
  Pagamentos feitos diretamente ao fornecedor via e-SISTAFE.

- **Adiantamento de Fundos + Despesa Paga VD – AFDP
  (ad_fundos_mais_dpvd)** — Soma dos adiantamentos e das despesas pagas
  via direta.

- **Adiantamentos de Fundos Liquidados – LAF (liq_ad_fundos)** —
  Adiantamentos para os quais o governo já recebeu e aceitou a fatura
  (aguardando pagamento).

- **Despesa Liquidada Via Directa – LVD
  (despesa_liquidada_via_directa)** — Despesas liquidadas diretamente no
  e-SISTAFE, ou seja, com documento de liquidação emitido.

- **Liq. Adiantamento de Fundos + Via Directa – LAFVD
  (liq_ad_fundos_via_directa_lafvd)** — Total de liquidações combinando
  adiantamentos liquidados e despesas liquidadas via direta.

Estas variáveis refletem todo o ciclo orçamental: dotação,
disponibilização de fundos, compromisso, liquidação e pagamento.

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
