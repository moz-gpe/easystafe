# Package index

## Processamento

Funções principais de limpeza e processamento de ficheiros exportados do
e-SISTAFE e extractos bancários

- [`processar_extracto_esistafe()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_esistafe.md)
  : Processar extractos 'Demonstrativo Consolidado' do e-SISTAFE
- [`processar_extracto_razao_c()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_razao_c.md)
  : Processar extractos 'Razao Contabilistico' a partir de ficheiros PDF
- [`processar_extracto_absa()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_absa.md)
  : Processar extractos bancarios ABSA

## Taxas de Câmbio

Funções para obter e aplicar taxas de câmbio diárias do BancoMOC

- [`parse_bancomoc_pdf()`](https://moz-gpe.github.io/easystafe/reference/parse_bancomoc_pdf.md)
  : Converter um ficheiro PDF com as taxas de câmbio do Banco de
  Moçambique num ficheiro 'tibble' arrumado
- [`obter_conversao_bancomoc()`](https://moz-gpe.github.io/easystafe/reference/obter_conversao_bancomoc.md)
  : Descarregar e arrumar os ficheiros PDF com as taxas de câmbio do
  portal do Banco de Moçambique
- [`adicionar_conversao_moeda()`](https://moz-gpe.github.io/easystafe/reference/adicionar_conversao_moeda.md)
  : Adicionar conversões diárias de taxas de câmbio a 'tibbles' com
  dados da 'Razao Contabilistica'

## Dados

Tabelas de referência incluídas no pacote

- [`lookup_razao`](https://moz-gpe.github.io/easystafe/reference/lookup_razao.md)
  : LTabela de referência que associa os nomes dos ficheiros de origem
  da 'Razão Contabilística' às respetivas descrições

## Enriquecer Dados

Funções para recodificar, classificar e adicionar variáveis aos dados
processados

- [`extrair_meta_extracto()`](https://moz-gpe.github.io/easystafe/reference/extrair_meta_extracto.md)
  : Extrair metadados de ficheiros de extracto 'Demonstrativo
  Consolidado' do e-SISTAFE
- [`carregar_lookups_esistafe()`](https://moz-gpe.github.io/easystafe/reference/carregar_lookups_esistafe.md)
  : Carregar lookups descritivos para enriquecimento de dados
  'Demonstrativo Consolidado' do e-SISTAFE
- [`adicionar_lookups_esistafe()`](https://moz-gpe.github.io/easystafe/reference/adicionar_lookups_esistafe.md)
  : Adicionar metadados a um 'tibble' contendo dados do 'Demonstrativo
  Consolidado' processado

## Gravar Dados Processados

Funções para gravar outputs processados

- [`gravar_esistafe()`](https://moz-gpe.github.io/easystafe/reference/gravar_esistafe.md)
  : Gravar extracto processado do e-SISTAFE em Parquet e Excel
- [`gravar_extracto_razao_c()`](https://moz-gpe.github.io/easystafe/reference/gravar_extracto_razao_c.md)
  : Gravar extracto da razao contabilistico processado em Parquet e
  Excel
- [`gravar_extracto_absa()`](https://moz-gpe.github.io/easystafe/reference/gravar_extracto_absa.md)
  : Gravar Extracto Bancario ABSA em Excel
- [`gravar_compilacao_sistafe()`](https://moz-gpe.github.io/easystafe/reference/gravar_compilacao_sistafe.md)
  : Compilar ficheiros eSISTAFE processados num unico Excel
- [`gravar_compilacao_razao_c()`](https://moz-gpe.github.io/easystafe/reference/gravar_compilacao_razao_c.md)
  : Compilar ficheiros RazaoCont processados num unico Excel

## Verificação

Funções para apoiar as verificações de qualidade

- [`verificar_ugb_completude()`](https://moz-gpe.github.io/easystafe/reference/verificar_ugb_completude.md)
  : Verificar completude de UGBs no extracto e-SISTAFE
