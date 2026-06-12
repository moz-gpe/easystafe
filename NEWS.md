# easystafe 0.2.0

## Novas funcionalidades

- Adicionada a função `adicionar_conversao_moeda()` para juntar taxas de câmbio
  diárias do BancoMOC a dados processados, produzindo colunas de valor e saldo
  em MZN, USD e EUR.
- Adicionada a função `obter_conversao_bancomoc()` para descarregar e consolidar
  tabelas de taxas diárias do portal do Banco de Moçambique.
- Adicionada a função `parse_bancomoc_pdf()` para interpretar PDFs individuais
  de taxas de câmbio do BancoMOC.
- Adicionado o conjunto de dados `lookup_razao` com a tabela de referência que
  mapeia nomes de ficheiros PDF da razão contabilística para descrições e
  províncias.

## Alterações a funções existentes

- `processar_extracto_razao_c()` e `processar_extracto_absa()`: removidos os
  parâmetros de taxa de câmbio (`usd_to_mt`, `eur_to_mt`, etc.); a conversão
  de moeda é agora aplicada separadamente via `adicionar_conversao_moeda()`.
- `adicionar_conversao_moeda()`: colunas `valor_lancamento` e
  `saldo_inicial_fim` renomeadas para `valor_lancamento_mzn` e
  `saldo_inicial_fim_mzn`; colunas de moeda reposicionadas no final do tibble
  na ordem `_mzn`, `_eur`, `_usd`.
- `carregar_lookups_esistafe()` e `adicionar_lookups_esistafe()`: adicionado
  suporte à folha `ced_nivel`, que classifica agrupamentos de nível 3 do CED.

## Reorganização do pacote

- Ficheiros `R/` reorganizados por área funcional: `bancomoc.R`,
  `adicionar_lookups.R`, `gravar.R`.
- Removida a função `recodificar_esistafe_vars()` (não utilizada internamente).
- Corrigidas referências cruzadas quebradas na documentação que apontavam para
  a função eliminada `aplicar_conversao_moeda`.
- Corrigida a estrutura do `_pkgdown.yml` (chave `reference:` em falta);
  secções de referência reorganizadas em seis grupos: Processamento, Taxas de
  Câmbio, Dados, Enriquecer Dados, Gravar Dados Processados e Verificação.
- README actualizado em Português, reflectindo a estrutura actual do pacote.

---

# easystafe 0.1.0

## Novas funcionalidades

- Adicionada a função `processar_extracto_esistafe()` para processar ficheiros
  demonstrativo consolidado do e-SISTAFE em lote, aplicando lógica hierárquica
  CED e devolvendo um tibble consolidado.
- Adicionada a função `extrair_meta_extracto()` para extrair datas, tipo de
  reporte, ano e mês a partir dos nomes dos ficheiros.

## Documentação e estrutura

- Criada documentação completa em Roxygen2, totalmente compatível com UTF-8.
- Estabelecida a infra-estrutura inicial do pacote com diretórios `R/`, `man/`,
  e configuração da toolchain de build.
