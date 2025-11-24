# easystafe 0.0.0.9000 (2025-11-24)

## Novas funcionalidades
- Adicionada a funcção **`processar_esistafe_extracto_unico()`** para:
  - processar extractos individuais do e-SISTAFE;
  - aplicar lógica hierárquica de subtração entre níveis CED (A, B, C, D);
  - consolidar valores e remover duplicações;
  - retornar um extracto final único e coerente.

- Adicionada a funcção **`processo_esistafe_extracto()`** para:
  - processar múltiplos extractos em lote;
  - anexar metadados automaticamente a cada ficheiro;
  - unificar resultados num único tibble consolidado;
  - gerir erros com `purrr::possibly()`.

- Adicionada a função **`extrair_meta_extracto()`** para:
  - extrair datas (referência e extração) a partir dos nomes dos ficheiros;
  - identificar o tipo de reporte (Funcionamento, Investimento Interno, Investimento Externo);
  - devolver ano e mês de referência com nomes de meses em Português.

## Documentação e estrutura
- Criada documentação completa em **Roxygen2**, totalmente compatível com UTF-8.
- Atualizadas imports no ficheiro **DESCRIPTION** para suportar todas as dependências usadas.
- Estabelecida a infra-estrutura inicial do pacote:
  - diretórios `R/`, `man/`, `.Rproj`, e configuração da toolchain de build;
  - estrutura de versionamento semântico para evolução futura.

## Melhorias técnicas
- Todo o código-fonte das funções foi convertido para **ASCII-safe**, garantindo:
  - compatibilidade com R CMD check;
  - ausência de caracteres não-ASCII em strings internas;
  - preservação de acentos apenas em comentários e documentação.

- Criadas regras internas para:
  - execução consistente da lógica CED;
  - validação segura do fluxo de processamento;
  - integração limpa entre funções principais.
