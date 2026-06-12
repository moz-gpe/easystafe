# easystafe <a href="https://moz-gpe.github.io/easystafe/"><img src="man/figures/logo.png" align="right" height="139" alt="easystafe logo"/></a>

> **Estado:** *experimental*

<!-- badges: start -->
  [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
  [![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

## Resumo

O **easystafe** é um pacote R para automatizar o processamento de extractos
exportados do e-SISTAFE (Sistema de Administração Financeira do Estado de
Moçambique) e de extractos bancários associados, substituindo fluxos manuais
por pipelines reproduzíveis e auditáveis.

---

## Funcionalidades

### Processamento de extractos
- `processar_extracto_esistafe()` — processa ficheiros *demonstrativo consolidado* do e-SISTAFE em lote
- `processar_extracto_razao_c()` — processa extractos PDF da razão contabilística
- `processar_extracto_absa()` — processa extractos PDF do banco ABSA

### Taxas de câmbio
- `parse_bancomoc_pdf()` — interpreta um PDF de taxas de câmbio do Banco de Moçambique
- `obter_conversao_bancomoc()` — descarrega e consolida taxas diárias do portal do BancoMOC
- `adicionar_conversao_moeda()` — junta taxas de câmbio diárias a um tibble processado, adicionando colunas em MZN, USD e EUR

### Enriquecimento de dados
- `extrair_meta_extracto()` — extrai metadados (datas, tipo de reporte, ano, mês) a partir do nome do ficheiro
- `carregar_lookups_esistafe()` — carrega as tabelas de referência (UGB, função, programa, CED, nível CED) a partir de um Excel
- `adicionar_lookups_esistafe()` — enriquece os dados com colunas descritivas via joins às tabelas de referência

### Gravação de resultados
- `gravar_esistafe()` — grava dados e-SISTAFE em Parquet e Excel com nomenclatura automática
- `gravar_extracto_razao_c()` — grava extracto da razão contabilística em Parquet e Excel
- `gravar_extracto_absa()` — grava extracto ABSA em Excel
- `gravar_compilacao_sistafe()` — compila e grava múltiplos ficheiros e-SISTAFE num único Excel
- `gravar_compilacao_razao_c()` — compila e grava múltiplos extractos da razão contabilística num único Excel

### Verificação
- `verificar_ugb_completude()` — verifica a completude das UGBs nos dados processados

### Dados incluídos
- `lookup_razao` — tabela de referência que mapeia os nomes dos ficheiros PDF da razão contabilística para descrições e províncias

---

## Instalação

```r
# instalar pacote
pak::pak("moz-gpe/easystafe")

# carregar pacote
library(easystafe)
```

---

*Disclaimer: As conclusões, interpretações e opiniões expressas neste pacote são
da responsabilidade exclusiva dos autores e não reflectem necessariamente as
posições da GIZ. Quaisquer erros ou omissões são da inteira responsabilidade
dos autores.*
