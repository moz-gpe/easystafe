# easystafe

<!-- Badge strip -->
[![R-CMD-check](https://github.com/moz-gpe/easystafe/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/moz-gpe/easystafe/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## 📌 Resumo

O **easystafe** é um pacote em desenvolvimento para facilitar o processamento,
deduplicação e análise de extractos exportados do **e-SISTAFE** (Sistema de Administração Financeira do Estado de Moçambique).

O pacote oferece:

- funções robustas para normalizar extractos financeiros;
- regras automáticas de priorização entre níveis de CED (A, B, C, D);
- deduplicação inteligente entre ficheiros múltiplos;
- extração automática de metadados (datas, tipo de reporte, ano, mês);
- preparação das variáveis orçamentais principais para uso analítico.

> **Estado:** *experimental* — a API poderá mudar nas próximas versões.

---

## 📦 Instalação

### Versão de desenvolvimento (GitHub)

```r
# install.packages("devtools")
devtools::install_github("moz-gpe/easystafe")


---

*Disclaimer: As conclusões, interpretações e opiniões expressas neste pacote são de responsabilidade exclusiva dos autores e não refletem necessariamente as posições da GIZ. Quaisquer erros ou omissões são de inteira responsabilidade dos autores.
