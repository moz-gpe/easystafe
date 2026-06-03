# Package index

## Extracção de metadados

Funções para carregar ficheiros e extrair metadados

- [`extrair_meta_extracto()`](https://moz-gpe.github.io/easystafe/reference/extrair_meta_extracto.md)
  : Extrair metadados de ficheiros de extracto e-SISTAFE
- [`adicionar_lookups_esistafe()`](https://moz-gpe.github.io/easystafe/reference/adicionar_lookups_esistafe.md)
  : Adicionar metados ao dataframe e-SISTAFE com lookups descritivos

## Processamento

Funções principais de limpeza e processamento

- [`processar_extracto_esistafe()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_esistafe.md)
  : Processar extractos de exportacao e-SISTAFE
- [`processar_extracto_razao_c()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_razao_c.md)
  : Processar extractos do razao contabilistico do e-SISTAFE a partir de
  ficheiros PDF
- [`processar_extracto_absa()`](https://moz-gpe.github.io/easystafe/reference/processar_extracto_absa.md)
  : Processar Extractos Bancarios ABSA

## Recodificação

Funções para recodificar e classificar variáveis

- [`recodificar_esistafe_vars()`](https://moz-gpe.github.io/easystafe/reference/recodificar_esistafe_vars.md)
  : Recodificar variaveis padrao de exportacoes e-SISTAFE
- [`carregar_lookups_esistafe()`](https://moz-gpe.github.io/easystafe/reference/carregar_lookups_esistafe.md)
  : Carregar lookups descritivos para enriquecimento de dados e-SISTAFE
- [`aplicar_conversao_moeda()`](https://moz-gpe.github.io/easystafe/reference/aplicar_conversao_moeda.md)
  : Aplicar conversao de moeda a um tibble de extractos do e-SISTAFE

## Gravação

Funções para gravar outputs processados

- [`gravar_esistafe()`](https://moz-gpe.github.io/easystafe/reference/gravar_esistafe.md)
  : Gravar extracto processado do e-SISTAFE em Parquet e Excel
- [`gravar_extracto_razao_c()`](https://moz-gpe.github.io/easystafe/reference/gravar_extracto_razao_c.md)
  : Gravar extracto da razao contabilistico processado em Excel
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
