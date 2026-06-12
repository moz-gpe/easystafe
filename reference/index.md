# Package index

## Processamento

Funções principais de limpeza e processamento de ficheiros exportados do
e-SISTAFE e extractos bancários

- [`processar_extracto_esistafe()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_esistafe.md)
  : Processar extractos de exportacao e-SISTAFE
- [`processar_extracto_razao_c()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_razao_c.md)
  : Processar extractos do razao contabilistico do e-SISTAFE a partir de
  ficheiros PDF
- [`processar_extracto_absa()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_absa.md)
  : Processar Extractos Bancarios ABSA

## Taxas de Câmbio

Funções para obter e aplicar taxas de câmbio diárias do BancoMOC

- [`parse_bancomoc_pdf()`](https://moz-gpe.github.io/easystafe/reference/parse_bancomoc_pdf.md)
  : Parse a Banco de Mocambique exchange rate PDF into a tidy tibble
- [`obter_conversao_bancomoc()`](https://moz-gpe.github.io/easystafe/reference/obter_conversao_bancomoc.md)
  : Download and parse Banco de Mocambique exchange rate PDFs
- [`adicionar_conversao_moeda()`](https://moz-gpe.github.io/easystafe/reference/adicionar_conversao_moeda.md)
  : Add daily exchange rate conversions to a razao contabilistica tibble

## Dados

Tabelas de referência incluídas no pacote

- [`lookup_razao`](https://moz-gpe.github.io/easystafe/reference/lookup_razao.md)
  : Lookup table mapping razao contabilistica source file names to
  descriptions

## Enriquecer Dados

Funções para recodificar, classificar e adicionar variáveis aos dados
processados

- [`extrair_meta_extracto()`](https://moz-gpe.github.io/easystafe/reference/extrair_meta_extracto.md)
  : Extrair metadados de ficheiros de extracto e-SISTAFE
- [`carregar_lookups_esistafe()`](https://moz-gpe.github.io/easystafe/reference/carregar_lookups_esistafe.md)
  : Carregar lookups descritivos para enriquecimento de dados e-SISTAFE
- [`adicionar_lookups_esistafe()`](https://moz-gpe.github.io/easystafe/reference/adicionar_lookups_esistafe.md)
  : Adicionar metados ao dataframe e-SISTAFE com lookups descritivos

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
