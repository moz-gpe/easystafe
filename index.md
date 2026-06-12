# easystafe

> **Estado:** *experimental*

## Resumo

O **easystafe** é um pacote R que automatiza o processamento de
extractos exportados do e-SISTAFE e de extractos bancários associados,
substituindo fluxos manuais por pipelines automatizados, reproduzíveis e
auditáveis.

------------------------------------------------------------------------

## Funcionalidades

### Processamento de extractos

Lê e estrutura ficheiros exportados do e-SISTAFE (demonstrativo
consolidado), da razão contabilística e de extractos bancários ABSA,
transformando-os em tabelas limpas e prontas para análise.

### Taxas de câmbio

Descarrega e consolida as taxas de câmbio diárias publicadas pelo Banco
de Moçambique, e junta-as automaticamente aos dados processados,
produzindo colunas de valor em MZN, USD e EUR.

### Enriquecimento de dados

Adiciona contexto descritivo aos dados processados: extrai metadados a
partir dos nomes dos ficheiros (datas, tipo de reporte, período) e
enriquece com tabelas de referência de UGB, função, programa e
classificação económica.

### Gravação de resultados

Grava os outputs processados em formato Parquet e/ou Excel com
nomenclatura automática, tanto para ficheiros individuais como para
compilações consolidadas de múltiplos extractos.

### Verificação

Ferramentas de apoio ao controlo de qualidade, incluindo a verificação
da completude das UGBs nos dados processados.

### Dados incluídos

O pacote inclui uma tabela de referência que mapeia nomes de ficheiros
PDF da razão contabilística para descrições e províncias.

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
