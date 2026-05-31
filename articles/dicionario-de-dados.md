# Dicionário de Dados (e-SISTAFE)

## Visão Geral

Os relatórios de acompanhamento orçamental extraídos do **e-SISTAFE**
(Sistema Electrónico de Administração Financeira do Estado) são
organizados em quatro tipos de despesa:

- **Funcionamento**: Despesas recorrentes/operacionais
- **Investimento Componente Interna**: Investimento financiado por
  recursos internos
- **Investimento Componente Externa**: Investimento financiado por
  recursos externos
- **Investimento Total**: Total do investimento

Cada relatório contém um conjunto de variáveis padrão descritos abaixo.

------------------------------------------------------------------------

## Dicionário de Variáveis

### Classificadores

Estes variáveis identificam *quem* gasta, *em quê*, *para qual programa*
e *a partir de que fonte de financiamento*.

[TABLE]

### Dotações

Estes variáveis acompanham o orçamento desde a sua aprovação inicial até
ao montante efectivamente disponível para execução.

[TABLE]

### Execução Orçamental

Estes variáveis registam como os fundos saem efectivamente do Tesouro e
são liquidados.

[TABLE]

------------------------------------------------------------------------

## Rácios de Desempenho Orçamental

Os seguintes rácios são habitualmente utilizados para avaliar o
desempenho orçamental. Todos são expressos em percentagem.

| Rácio | Fórmula | Interpretação |
|:---|:---|:---|
| **Taxa de cabimentação** | `DCB / DA × 100` | Percentagem da dotação actualizada que foi cabimentada. Mede o progresso no empenho do orçamento disponível. |
| **Taxa de execução orçamental** | `AFDP / DA × 100` | Percentagem da dotação actualizada que foi efectivamente desembolsada. É a principal medida de execução orçamental. |
| **Taxa de liquidação de adiantamentos** | `LAF / AF × 100` | Percentagem dos adiantamentos de fundos que foram formalmente liquidados (justificados com documentos). Uma taxa baixa pode indicar problemas de prestação de contas com adiantamentos em dinheiro. |

------------------------------------------------------------------------

## Ciclo de Execução da Despesa

A execução da despesa no e-SISTAFE obedece a um processo sequencial:

1.  **Cabimentação**: O orçamento é reservado para uma despesa
    específica.
2.  **Liquidação**: O direito do credor é verificado (bens recebidos,
    serviços prestados).
3.  **Pagamento**: Os fundos são transferidos para o fornecedor, seja
    por via directa (DP) ou após um adiantamento (AF → LAF).

Compreender em que fase do ciclo se encontra uma despesa é essencial
para interpretar correctamente os variáveis acima.

------------------------------------------------------------------------

*Para questões sobre o sistema e-SISTAFE ou este pacote, por favor abra
um issue no repositório do projecto.*
