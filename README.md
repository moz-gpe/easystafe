# easystafe <a href="https://moz-gpe.github.io/easystafe/"><img src="man/figures/logo.png" align="right" height="300" alt="easystafe logo"/></a>

> **Estado:** *experimental*

<!-- badges: start -->
  [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
  [![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

## Resumo

O **easystafe** é um pacote R em desenvolvimento para automatizar o processamento de extractos 
exportados do e-SISTAFE (Sistema de Administração Financeira do Estado de Moçambique), substituindo 
fluxos manuais em Excel por pipelines reproduzíveis e auditáveis.

O pacote oferece:

- Carregamento e processamento de múltiplos ficheiros .xlsx numa única operação;
- Extração automática de metadados a partir do nome do ficheiro, incluindo tipo de reporte, ano, mês e datas;
- Filtragem automática de Unidades Gestoras Beneficiárias (UGBs) do sector da Educação;
- Adição de metadados de linha por UGB, incluindo âmbito, província, distrito e tipo de programa;
- Processamento de extractos PDF de razão de conta com extração de saldos e movimentos;
- Gravação dos dados processados em Excel com nomenclatura automática de ficheiros.


---

## Instalação

### Versão de desenvolvimento (GitHub)

```r
      
      # instalar pacote
      pak::pak("moz-gpe/easystafe")

      # carregar pacote
      library(easystafe)
      
      # Listar funções do pacote
      ls("package:easystafe")
      
```

---

*Disclaimer: As conclusões, interpretações e opiniões expressas neste pacote são de responsabilidade exclusiva dos autores e não refletem necessariamente as posições da GIZ. Quaisquer erros ou omissões são de inteira responsabilidade dos autores.*
