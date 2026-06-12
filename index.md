# easystafe

> **Estado:** *experimental*

## Resumo

O **easystafe** é um pacote R para automatizar o processamento de
extractos exportados do e-SISTAFE (Sistema de Administração Financeira
do Estado de Moçambique) e de extractos bancários associados,
substituindo fluxos manuais por pipelines reproduzíveis e auditáveis.

------------------------------------------------------------------------

## Funcionalidades

### Processamento de extractos

- [`processar_extracto_esistafe()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_esistafe.md)
  — processa ficheiros *demonstrativo consolidado* do e-SISTAFE em lote
- [`processar_extracto_razao_c()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_razao_c.md)
  — processa extractos PDF da razão contabilística
- [`processar_extracto_absa()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_absa.md)
  — processa extractos PDF do banco ABSA

### Taxas de câmbio

- [`parse_bancomoc_pdf()`](https://moz-gpe.github.io/easystafe/reference/parse_bancomoc_pdf.md)
  — interpreta um PDF de taxas de câmbio do Banco de Moçambique
- [`obter_conversao_bancomoc()`](https://moz-gpe.github.io/easystafe/reference/obter_conversao_bancomoc.md)
  — descarrega e consolida taxas diárias do portal do BancoMOC
- [`adicionar_conversao_moeda()`](https://moz-gpe.github.io/easystafe/reference/adicionar_conversao_moeda.md)
  — junta taxas de câmbio diárias a um tibble processado, adicionando
  colunas em MZN, USD e EUR

### Enriquecimento de dados

- [`extrair_meta_extracto()`](https://moz-gpe.github.io/easystafe/reference/extrair_meta_extracto.md)
  — extrai metadados (datas, tipo de reporte, ano, mês) a partir do nome
  do ficheiro
- [`carregar_lookups_esistafe()`](https://moz-gpe.github.io/easystafe/reference/carregar_lookups_esistafe.md)
  — carrega as tabelas de referência (UGB, função, programa, CED, nível
  CED) a partir de um Excel
- [`adicionar_lookups_esistafe()`](https://moz-gpe.github.io/easystafe/reference/adicionar_lookups_esistafe.md)
  — enriquece os dados com colunas descritivas via joins às tabelas de
  referência

### Gravação de resultados

- [`gravar_esistafe()`](https://moz-gpe.github.io/easystafe/reference/gravar_esistafe.md)
  — grava dados e-SISTAFE em Parquet e Excel com nomenclatura automática
- [`gravar_extracto_razao_c()`](https://moz-gpe.github.io/easystafe/reference/gravar_extracto_razao_c.md)
  — grava extracto da razão contabilística em Parquet e Excel
- [`gravar_extracto_absa()`](https://moz-gpe.github.io/easystafe/reference/gravar_extracto_absa.md)
  — grava extracto ABSA em Excel
- [`gravar_compilacao_sistafe()`](https://moz-gpe.github.io/easystafe/reference/gravar_compilacao_sistafe.md)
  — compila e grava múltiplos ficheiros e-SISTAFE num único Excel
- [`gravar_compilacao_razao_c()`](https://moz-gpe.github.io/easystafe/reference/gravar_compilacao_razao_c.md)
  — compila e grava múltiplos extractos da razão contabilística num
  único Excel

### Verificação

- [`verificar_ugb_completude()`](https://moz-gpe.github.io/easystafe/reference/verificar_ugb_completude.md)
  — verifica a completude das UGBs nos dados processados

### Dados incluídos

- `lookup_razao` — tabela de referência que mapeia os nomes dos
  ficheiros PDF da razão contabilística para descrições e províncias

------------------------------------------------------------------------

## Instalação

``` r

# instalar pacote
pak::pak("moz-gpe/easystafe")

# carregar pacote
library(easystafe)
```

------------------------------------------------------------------------

*Disclaimer: As conclusões, interpretações e opiniões expressas neste
pacote são da responsabilidade exclusiva dos autores e não reflectem
necessariamente as posições da GIZ. Quaisquer erros ou omissões são da
inteira responsabilidade dos autores.*
