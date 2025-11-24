# easystafe

Ferramentas para processamento, consolidação e análise de extractos do e-SISTAFE em Moçambique.  
O pacote facilita a limpeza, padronização e deduplicação de ficheiros de execução orçamental, permitindo uma análise mais rápida, transparente e reprodutível.


[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

---

## 📘 Resumo

O pacote **easystafe** foi desenvolvido para apoiar equipas técnicas que trabalham com dados extraídos do sistema e-SISTAFE, fornecendo funções robustas para:

- Processamento hierárquico e consolidação automática de extractos;
- Remoção de duplicações entre níveis CED (A, B, C, D);
- Extração estruturada de metadados (datas, tipo de reporte, ano, mês) diretamente do nome dos ficheiros;
- Processamento em lote de múltiplos extractos com anexação de metadados;
- Fluxos consistentes e reproduzíveis para integração em pipelines analíticos.

As funções principais incluem:

- **`processar_esistafe_extracto_unico()`**  
  Processamento completo de um único extracto e eliminação de duplicações entre níveis CED.

- **`processo_esistafe_extracto()`**  
  Processamento em massa de múltiplos extractos, incluindo gestão de erros e unificação dos resultados.

- **`extrair_meta_extracto()`**  
  Extração automática de metadados a partir do nome dos ficheiros do e-SISTAFE.

Este pacote apoia análises orçamentais, promovendo maior transparência e rigor nos processos de gestão financeira pública.

---

## 🔧 Instalação

O pacote ainda não se encontra no CRAN. Para instalar a versão de desenvolvimento diretamente do GitHub, utilize:

```r

# Instalar easystafe a partir do repositório GitHub
devtools::install_github("moz-gpe/easystafe")
    
```

---

*Disclaimer: As conclusões, interpretações e opiniões expressas neste pacote são de responsabilidade exclusiva dos autores e não refletem necessariamente as posições da Deutsche Gesellschaft für Internationale Zusammenarbeit (GIZ) GmbH, do Global Partnership for Education (GPE), do Ministério da Educação e Desenvolvimento Humano (MINEDH), ou da United States Agency for International Development (USAID). Quaisquer erros ou omissões são de inteira responsabilidade dos autores.
