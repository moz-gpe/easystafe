# easystafe

> **Estado:** *experimental*

## Resumo

O **easystafe** é um pacote R em desenvolvimento para automatizar o
processamento de extractos exportados do e-SISTAFE (Sistema de
Administração Financeira do Estado de Moçambique), substituindo fluxos
manuais por pipelines automatizados, reproduzíveis e auditáveis.

O pacote oferece:

- Carregamento e processamento de múltiplos ficheiros ‘demonstrativo
  consolidado’ numa única operação;
- Extração automática de metadados a partir do nome do ficheiro,
  incluindo tipo de reporte, ano, mês e datas;
- Filtragem automática de UGB’s (Unidades Gestoras Beneficiárias) do
  sector da Educação;
- Adição de metadados analiticos (âmbito, província, distrito, tipo de
  programa, etc.);
- Carregamento e processamento de múltiplos ficheiros ‘razão
  contabalistica’ numa única operação;
- Gravação dos dados processados em Excel e Parquet com nomenclatura
  automática de ficheiros.
- Recolha e consolidação das taxas de câmbio diárias a partir do portal
  do Banco de Moçambique

------------------------------------------------------------------------

## Instalação

### Versão de desenvolvimento (GitHub)

``` r

      
      # instalar pacote
      pak::pak("moz-gpe/easystafe")

      # carregar pacote
      library(easystafe)
      
      # Listar funções do pacote
      ls("package:easystafe")
      
```

------------------------------------------------------------------------

*Disclaimer: As conclusões, interpretações e opiniões expressas neste
pacote são de responsabilidade exclusiva dos autores e não refletem
necessariamente as posições da GIZ. Quaisquer erros ou omissões são de
inteira responsabilidade dos autores.*
