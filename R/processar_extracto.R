#' Processar extractos de exportacao e-SISTAFE
#'
#' Carrega, limpa e processa um ou mais ficheiros de exportacao do e-SISTAFE
#' no formato Excel, aplicando uma sequencia de transformacoes que inclui
#' renomeacao de colunas, filtragem de UGBs de educacao, classificacao e
#' subtraccao hierarquica de codigos CED, e restauracao da estrutura original
#' de colunas. Devolve um dataframe final desduplicado e pronto para analise.
#'
#' @param source_path Um vector de caracteres com um ou mais caminhos para
#'   ficheiros de exportacao e-SISTAFE no formato \code{.xlsx}.
#' @param df_ugb_lookup Um dataframe com a tabela de referencia de UGBs de
#'   educacao. Deve conter pelo menos a coluna \code{codigo_ugb} com os
#'   codigos de 9 caracteres dos UGBs validos (e.g. \code{"50B105761"}).
#'   Tipicamente carregado a partir da tabela de referencia de UGBs do
#'   projecto. Apenas as linhas cujo \code{ugb_id} coincida com um valor
#'   em \code{codigo_ugb} sao retidas no processamento.
#' @param include_percent Logico. Se \code{TRUE} (padrao), as colunas
#'   \code{percent} sao incluidas no output (preenchidas com \code{NA}).
#'   Se \code{FALSE}, essas colunas sao removidas do resultado final.
#' @param include_file_metadata Logico. Se \code{TRUE} (padrao), os metadados
#'   extraidos do nome do ficheiro (tipo de relatorio, ano, mes, datas) sao
#'   adicionados ao dataframe imediatamente apos a coluna \code{file_name}.
#'   Se \code{FALSE}, os metadados nao sao adicionados e a coluna
#'   \code{file_name} e tambem removida do resultado final.
#' @param include_metrica Logico. Se \code{TRUE} (padrao), as linhas do tipo
#'   \code{"Metrica"} sao excluidas do output final, mantendo apenas as linhas
#'   \code{"Valor"} apos subtraccao hierarquica. Se \code{TRUE}, as linhas
#'   \code{"Metrica"} sao reincluidas no output final apos o processamento,
#'   util para comparacoes e validacao. A coluna \code{data_tipo} e sempre
#'   incluida no output, independentemente deste parametro.
#' @param quiet Logico. Se \code{TRUE} (padrao), as mensagens de progresso
#'   sao suprimidas. Se \code{FALSE}, e emitida uma mensagem por cada etapa
#'   do processamento. Independentemente deste parametro, e sempre emitida
#'   uma mensagem final com o numero de ficheiros processados.
#'
#' @return Um tibble com uma linha por entrada CED deduplificada, contendo
#'   as colunas originais do extracto e-SISTAFE apos limpeza e subtraccao
#'   hierarquica. A coluna \code{data_tipo} esta sempre presente e posicionada
#'   imediatamente antes de \code{ugb}. As colunas de percentagem sao sempre
#'   incluidas na estrutura original (preenchidas com \code{NA}) salvo se
#'   \code{include_percent = FALSE}.
#'
#' @details
#' O processamento segue as seguintes etapas principais:
#' \enumerate{
#'   \item Carregamento e combinacao de todos os ficheiros em \code{source_path}.
#'   \item Adicao opcional de metadados via \code{extrair_meta_extracto()}.
#'   \item Limpeza de nomes de colunas com \code{janitor::clean_names()}.
#'   \item Remocao de colunas \code{percent}.
#'   \item Conversao de colunas numericas e extraccao do codigo \code{ugb_id}.
#'   \item Filtragem de UGBs validos de educacao a partir de \code{df_ugb_lookup}.
#'   \item Remocao de linhas com CED e campos-chave em branco.
#'   \item Classificacao de grupos CED (A, B, C, D) e remocao do grupo D.
#'   \item Criacao de variaveis hierarquicas auxiliares.
#'   \item Separacao de linhas \code{"Metrica"} e \code{"Valor"} antes da
#'     subtraccao hierarquica.
#'   \item Subtraccao hierarquica em tres passos para eliminar dupla contagem
#'     (aplicada apenas a linhas \code{"Valor"}):
#'     \itemize{
#'       \item Passo 1: Subtrair grupo A do grupo B (dentro de \code{ced_b4}).
#'       \item Passo 2: Subtrair grupo B ajustado do grupo C (dentro de \code{ced_b3}).
#'       \item Passo 3: Subtrair grupo A directamente do grupo C (dentro de \code{ced_b3}).
#'     }
#'   \item Reinclusao opcional das linhas \code{"Metrica"} via \code{include_metrica}.
#'   \item Seleccao das colunas finais a partir de um vector explicito,
#'     garantindo que \code{data_tipo} e sempre incluido antes de \code{ugb}.
#' }
#'
#' @examples
#' \dontrun{
#' ugb_lookup    <- readxl::read_excel("Data/ugb/Codigos de UGBs.xlsx", sheet = "UGBS")
#' path_files <- list.files("Data/", pattern = "\\.xlsx$", full.names = TRUE)
#'
#' # Padrao -- com metadados e colunas percent, sem linhas Metrica
#' df <- processar_extracto_esistafe(
#'   source_path = path_files,
#'   df_ugb_lookup  = ugb_lookup
#' )
#'
#' # Sem metadados, sem colunas percent
#' df <- processar_extracto_esistafe(
#'   source_path     = path_files,
#'   df_ugb_lookup      = ugb_lookup,
#'   include_percent = FALSE,
#'   include_file_metadata    = FALSE
#' )
#'
#' # Com linhas Metrica incluidas para comparacao
#' df <- processar_extracto_esistafe(
#'   source_path      = path_files,
#'   df_ugb_lookup       = ugb_lookup,
#'   include_metrica  = TRUE
#' )
#'
#' # Com mensagens de progresso
#' df <- processar_extracto_esistafe(
#'   source_path = path_files,
#'   df_ugb_lookup  = ugb_lookup,
#'   quiet       = FALSE
#' )
#' }
#'
#' @importFrom purrr map
#' @importFrom readxl read_excel
#' @importFrom dplyr n_distinct mutate across relocate filter select left_join
#'   if_else case_when group_by ungroup bind_rows distinct
#' @importFrom tidyr unite
#' @importFrom stringr str_ends str_sub str_c
#' @importFrom janitor clean_names
#' @importFrom glue glue
#' @importFrom tibble tibble
#'
#' @export

processar_extracto_esistafe <- function(
    source_path,
    df_ugb_lookup,
    include_percent  = TRUE,
    include_file_metadata     = TRUE,
    include_metrica  = TRUE,
    quiet            = TRUE
) {

  # --- Mensagens internas ---
  msg <- function(...) {
    if (!quiet) message(...)
  }

  # --- 1. Carregar ficheiros ---
  msg("A carregar ficheiros...")

  df <- purrr::map(source_path, ~readxl::read_excel(.x, col_types = "text")) |>
    purrr::set_names(base::basename(source_path)) |>
    purrr::list_rbind(names_to = "file_name")

  msg(glue::glue("Ficheiros carregados: {dplyr::n_distinct(df$file_name)} | Linhas: {nrow(df)}"))

  # --- 2. Adicionar ou remover metadados ---
  if (include_file_metadata) {
    msg("A extrair e adicionar metadados...")

    paths_meta <- extrair_meta_extracto(source_path)

    df <- df |>
      dplyr::left_join(paths_meta, by = "file_name") |>
      dplyr::relocate(names(paths_meta)[-1], .after = file_name)
  }

  # --- 3. Renomear colunas ---
  msg("A limpar nomes de colunas...")

  df_limpeza_1 <- janitor::clean_names(df)

  # --- 4. Remover colunas percent ---
  msg("A remover colunas percent...")

  df_limpeza_2 <- df_limpeza_1 |>
    dplyr::select(!dplyr::ends_with("percent"))

  # --- 5. Extrair codigo UGB ---
  msg("A extrair c\u00f3digo UGB...")

  df_limpeza_3 <- df_limpeza_2 |>
    dplyr::mutate(
      dplyr::across(dotacao_inicial:liq_ad_fundos_via_directa_lafvd,
                    ~ suppressWarnings(as.numeric(.x))),
      ugb_id = base::substr(ugb, 1, 9)
    ) |>
    dplyr::relocate(ugb_id, .after = ugb)

  # --- 6. Filtrar UGBs de educacao ---
  msg("A filtrar UGBs de educa\u00e7\u00e3o...")

  vec_ugb <- df_ugb_lookup |>
    dplyr::distinct(codigo_ugb) |>
    dplyr::pull()

  df_limpeza_4 <- df_limpeza_3 |>
    dplyr::mutate(mec_ugb_class = base::ifelse(ugb_id %in% vec_ugb, "Keep", "Remove")) |>
    dplyr::filter(mec_ugb_class == "Keep") |>
    dplyr::select(-mec_ugb_class)

  # --- 7. Remover linhas com CED e funcao/programa/FR em branco ---
  msg("A remover linhas com CED e campos-chave em branco...")

  df_limpeza_5 <- df_limpeza_4 |>
    dplyr::filter(!base::is.na(ced) | (!base::is.na(funcao) & !base::is.na(programa) & !base::is.na(fr))) |>
    dplyr::mutate(data_tipo = dplyr::if_else(base::is.na(ced), "Metrica", "Valor")) |>
    dplyr::relocate(data_tipo, .before = ced)

  # --- 8. Classificar grupos CED e remover grupo D ---
  msg("A classificar grupos CED e remover grupo D...")

  df_limpeza_6 <- df_limpeza_5 |>
    dplyr::mutate(
      ced_group = dplyr::case_when(
        !stringr::str_ends(ced, "00")                                                                    ~ "A",
        stringr::str_ends(ced, "00") & !stringr::str_ends(ced, "000") & !stringr::str_ends(ced, "0000") ~ "B",
        stringr::str_ends(ced, "000") & !stringr::str_ends(ced, "0000")                                 ~ "C",
        stringr::str_ends(ced, "0000")                                                                   ~ "D",
        TRUE                                                                                              ~ NA_character_
      )
    ) |>
    dplyr::filter(base::is.na(ced_group) | ced_group != "D")

  # --- 9. Criar variaveis hierarquicas ---
  msg("A criar vari\u00e1veis hier\u00e1rquicas...")

  df_limpeza_7 <- df_limpeza_6 |>
    dplyr::mutate(
      ced_b4    = stringr::str_sub(ced, 1, 4),
      ced_b3    = stringr::str_sub(ced, 1, 3),
      id_ced_b4 = stringr::str_c(ugb_id, funcao, programa, fr, ced_b4, sep = " | "),
      id_ced_b3 = stringr::str_c(ugb_id, funcao, programa, fr, ced_b3, sep = " | ")
    ) |>
    tidyr::unite(ugb_funcao_prog_fr, ugb_id, funcao, programa, fr, sep = " | ", remove = FALSE, na.rm = FALSE) |>
    dplyr::relocate(c(ced_b4, ced_b3), .after = ced) |>
    dplyr::relocate(ced_group, .before = ced) |>
    dplyr::relocate(data_tipo, .after = ced_b3) |>
    dplyr::relocate(ugb_funcao_prog_fr, .before = dplyr::everything())

  # --- 10. Definir colunas numericas ---
  num_cols <- df_limpeza_7 |>
    dplyr::select(dotacao_inicial:liq_ad_fundos_via_directa_lafvd) |>
    base::names()

  # --- 10b. Separar linhas Metrica antes da subtraccao hierarquica ---
  msg("A separar linhas Metrica e Valor...")

  df_metrica <- df_limpeza_7 |>
    dplyr::filter(data_tipo == "Metrica")

  # --- 11. Subtracao hierarquica: Passo 1 (A -> B dentro de ced_b4) ---
  # Nota: apenas linhas "Valor" entram na subtraccao -- comportamento agora explicito
  msg("A executar subtra\u00e7\u00e3o hier\u00e1rquica \u2014 Passo 1 (A \u2192 B)...")

  df_step1 <- df_limpeza_7 |>
    dplyr::filter(data_tipo == "Valor") |>
    dplyr::group_by(ugb_funcao_prog_fr, ced_b4) |>
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(num_cols),
        ~ dplyr::if_else(ced_group == "B", .x - base::sum(.x[ced_group == "A"], na.rm = TRUE), .x)
      )
    ) |>
    dplyr::ungroup()

  # --- 12. Subtracao hierarquica: Passo 2 (B ajustado -> C dentro de ced_b3) ---
  msg("A executar subtra\u00e7\u00e3o hier\u00e1rquica \u2014 Passo 2 (B \u2192 C)...")

  df_step2 <- df_step1 |>
    dplyr::group_by(ugb_funcao_prog_fr, ced_b3) |>
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(num_cols),
        ~ dplyr::if_else(ced_group == "C", .x - base::sum(.x[ced_group == "B"], na.rm = TRUE), .x)
      )
    ) |>
    dplyr::ungroup()

  # --- 13. Subtracao hierarquica: Passo 3 (A directo -> C dentro de ced_b3) ---
  msg("A executar subtra\u00e7\u00e3o hier\u00e1rquica \u2014 Passo 3 (A directo \u2192 C)...")

  df_limpeza_9 <- df_step2 |>
    dplyr::group_by(ugb_funcao_prog_fr, ced_b3) |>
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(num_cols),
        ~ dplyr::if_else(ced_group == "C", .x - base::sum(.x[ced_group == "A"], na.rm = TRUE), .x)
      )
    ) |>
    dplyr::ungroup()

  # --- 13b. Reincluir linhas Metrica se solicitado ---
  if (include_metrica) {
    msg("A reincluir linhas Metrica...")
    df_limpeza_9 <- dplyr::bind_rows(df_limpeza_9, df_metrica)
  }

  # --- 14. Seleccionar colunas finais a partir de vector explicito ---
  # data_tipo e sempre incluido, posicionado antes de ugb.
  # percent e file_name sao incluidos ou excluidos conforme os argumentos.
  msg("A finalizar estrutura do dataset...")

  final_cols <- c(
    # metadados de ficheiro (removidos se include_file_metadata = FALSE)
    "file_name", "reporte_tipo", "data_reporte", "data_extraido",
    "ano", "mes",
    # classificacao da linha -- sempre presente
    "data_tipo",
    "ugb_id",
    # identificadores orcamentais
    "ugb", "funcao", "programa", "fr", "ced",
    # colunas numericas
    "dotacao_inicial",
    "dotacao_revista",
    "dotacao_actualizada_da",
    "dotacao_disponivel",
    "dotacao_cabimentada_dc",
    "ad_fundos_concedidos_af",
    "despesa_paga_via_directa_dp",
    "ad_fundos_desp_paga_vd_afdp",
    "ad_fundos_liquidados_laf",
    "despesa_liquidada_via_directa_lvd",
    "liq_ad_fundos_via_directa_lafvd",
    "dc_da_percent",
    "afdp_da_percent",
    "laf_af_percent"
  )

  df_limpeza_final <- df_limpeza_9 |>
    dplyr::mutate(
      dc_da_percent   = NA_real_,
      afdp_da_percent = NA_real_,
      laf_af_percent  = NA_real_
    ) |>
    dplyr::select(dplyr::any_of(final_cols)) |>
    dplyr::relocate(data_tipo, .after = mes) |>
    dplyr::arrange(ugb)

  # --- 15. Excluir colunas percent se solicitado ---
  if (!include_percent) {
    df_limpeza_final <- df_limpeza_final |>
      dplyr::select(!dplyr::ends_with("percent"))
  }

  # --- 16. Remover file_name e metadados se include_file_metadata = FALSE ---
  if (!include_file_metadata) {
    df_limpeza_final <- df_limpeza_final |>
      dplyr::select(-dplyr::any_of(c("file_name", "reporte_tipo", "data_reporte", "data_extraido", "ano", "mes", "ugb_id")))
  }

  msg("Conclu\u00eddo.")

  # --- Resumo final ---
  n_files <- dplyr::n_distinct(df$file_name)
  message(glue::glue("Processamento conclu\u00eddo: {n_files} ficheiro(s) processado(s) com sucesso."))

  return(df_limpeza_final)

}







#' Processar extractos do razao contabilistico do e-SISTAFE a partir de ficheiros PDF
#'
#' Le todos os ficheiros PDF de uma pasta, extrai as transaccoes e saldos
#' de cada extracto da razao contabilistico, e combina os resultados num
#' unico tibble. Ficheiros com formato FOREX (USD/EUR) sao excluidos por
#' padrao.
#'
#' @param source_path Caractere. Caminho para a pasta que contem os ficheiros
#'   PDF a processar. Obrigatorio.
#' @param exclude_pattern Caractere. Expressao regular para excluir ficheiros
#'   pelo nome. Por padrao exclui ficheiros FOREX:
#'   \code{"CENTRAL USD|EXTRACTO DA CONTA FOREX EUR|EXTRACTO DA CONTA FOREX USD"}.
#'   Para nao excluir nenhum ficheiro, usar \code{NULL}.
#' @param recursive Logico. Se \code{TRUE}, a pesquisa de ficheiros PDF
#'   inclui subpastas. Por padrao \code{FALSE}.
#' @param quiet Logico. Se \code{TRUE} (padrao), suprime as mensagens emitidas
#'   por ficheiro durante o processamento (por exemplo, quando um PDF nao
#'   contem transaccoes). Se \code{FALSE}, as mensagens sao apresentadas.
#'
#' @return Um tibble com uma linha por registo (movimentos, saldo inicial e
#'   saldo final) de todos os PDFs processados, contendo as colunas:
#'   \describe{
#'     \item{source_file}{Nome do ficheiro PDF de origem.}
#'     \item{unidade_gestao}{Nome da unidade de gestao extraido do cabecalho.}
#'     \item{data}{Data do registo (\code{Date}).}
#'     \item{ano}{Ano extraido da data do registo (\code{integer}).}
#'     \item{mes}{Mes extraido da data do registo (\code{integer}).}
#'     \item{tipo}{Tipo de registo: \code{"MOVIMENTO"}, \code{"SALDO_INICIAL"} ou \code{"SALDO_FINAL"}.}
#'     \item{codigo_documento}{Codigo do documento (apenas em movimentos).}
#'     \item{valor_lancamento}{Valor do lancamento em MZN, negativo para creditos (C).}
#'     \item{dc1}{Indicador debito/credito do lancamento (\code{"D"} ou \code{"C"}).}
#'     \item{saldo_atual}{Saldo acumulado apos o lancamento.}
#'     \item{dc2}{Indicador debito/credito do saldo.}
#'     \item{saldo_inicial_fim}{Valor do saldo inicial ou final (apenas nessas linhas).}
#'   }
#'
#' @details
#' A logica de extraccao trata os seguintes casos:
#' \itemize{
#'   \item PDFs com transaccoes: extrai movimentos linha a linha e calcula
#'     saldos inicial e final.
#'   \item PDFs sem transaccoes: retorna apenas as linhas SALDO_INICIAL e
#'     SALDO_FINAL com base nos valores do cabecalho.
#'   \item Datas com espacos irregulares (ex: \code{"01 / 12 / 2025"}): sao
#'     normalizadas automaticamente.
#'   \item Valores em formato portugues (ponto como separador de milhares,
#'     virgula como decimal): convertidos correctamente.
#'   \item Creditos (C) sao convertidos para valores negativos.
#' }
#'
#' O intervalo de datas do conjunto processado e guardado como atributo do
#' tibble retornado, acessivel via \code{attr(df, "date_range_txt")}.
#'
#' @examples
#' \dontrun{
#' df_razao <- processar_extracto_razao_c(
#'   source_path = path_folder_source
#' )
#'
#' # Com mensagens visiveis e subpastas incluidas
#' df_razao <- processar_extracto_razao_c(
#'   source_path = path_folder_source,
#'   recursive   = TRUE,
#'   quiet       = FALSE
#' )
#'
#' # Sem exclusao de ficheiros FOREX
#' df_razao <- processar_extracto_razao_c(
#'   source_path     = path_folder_source,
#'   exclude_pattern = NULL
#' )
#' }
#'
#' @export

processar_extracto_razao_c <- function(
    source_path,
    exclude_pattern = "CENTRAL USD|FOREX|DemonstrativoConsolidado",
    recursive       = FALSE,
    quiet           = TRUE
) {

  # ---- Helper interno: extrair tabela de um PDF ----
  extract_sistafe_table <- function(path_pdf) {

    raw_text <- pdftools::pdf_text(path_pdf)

    # -- helpers --
    normalize_pt_date <- function(x) {
      x <- as.character(x)
      x <- stringr::str_replace_all(x, "\\s*", "")
      dplyr::na_if(x, "")
    }

    extract_header_date <- function(txt, label_regex) {
      m <- stringr::str_match(
        txt,
        paste0(
          "(?s)\\b",
          label_regex,
          "\\s*:?\\s*(\\d{2}\\s*/\\s*\\d{2}\\s*/\\s*\\d{4})\\b"
        )
      )
      normalize_pt_date(m[, 2])
    }

    # -- unidade_gestao --
    unidade_gestao <- raw_text[1] |>
      stringr::str_extract("Gest\u00e3o:\\s*(.+)") |>
      stringr::str_remove("Gest\u00e3o:\\s*") |>
      stringr::str_trim()

    # -- header dates --
    header_data_chr       <- extract_header_date(raw_text[1], "Data(?!\\s*Final)")
    header_data_final_chr <- extract_header_date(raw_text[1], "Data\\s*Final")

    header_data       <- suppressWarnings(lubridate::dmy(header_data_chr))
    header_data_final <- suppressWarnings(lubridate::dmy(header_data_final_chr))

    # -- header saldo (fallback when no transactions) --
    saldo_hdr <- raw_text[1] |>
      stringr::str_extract("Saldo:\\s*([\\d\\.]+,\\d{2})") |>
      stringr::str_remove("Saldo:\\s*")

    saldo_hdr_dc <- raw_text[1] |>
      stringr::str_extract("Saldo:\\s*[\\d\\.]+,\\d{2}\\s*([CD])") |>
      stringr::str_extract("[CD]$")

    saldo_hdr_num <- readr::parse_number(
      saldo_hdr,
      locale = readr::locale(decimal_mark = ",", grouping_mark = ".")
    )

    # -- extract transaction lines --
    lines <- raw_text |>
      stringr::str_split("\n") |>
      unlist() |>
      stringr::str_subset("^\\d{2}\\s*/\\s*\\d{2}\\s*/\\s*\\d{4}") |>
      stringr::str_squish()

    # -- no transactions: return saldo rows only --
    if (length(lines) == 0) {
      if (!quiet) {
        message(
          "Sem transa\u00e7\u00f5es em: ",
          basename(path_pdf),
          " \u2014 a retornar apenas saldos"
        )
      }

      return(
        dplyr::bind_rows(
          tibble::tibble(
            unidade_gestao    = unidade_gestao,
            data              = header_data,
            tipo              = "SALDO_INICIAL",
            codigo_documento  = NA_character_,
            valor_lancamento  = 0,
            dc1               = NA_character_,
            saldo_atual       = saldo_hdr_num,
            dc2               = saldo_hdr_dc,
            saldo_inicial_fim = saldo_hdr_num
          ),
          tibble::tibble(
            unidade_gestao    = unidade_gestao,
            data              = header_data_final,
            tipo              = "SALDO_FINAL",
            codigo_documento  = NA_character_,
            valor_lancamento  = 0,
            dc1               = NA_character_,
            saldo_atual       = saldo_hdr_num,
            dc2               = saldo_hdr_dc,
            saldo_inicial_fim = saldo_hdr_num
          )
        )
      )
    }

    # -- parse transactions --
    df <- tibble::tibble(raw = lines) |>
      tidyr::separate(
        raw,
        into = c(
          "data",
          "codigo_documento",
          "valor_lancamento",
          "dc1",
          "saldo_atual",
          "dc2"
        ),
        sep  = "\\s+",
        fill = "right"
      ) |>
      dplyr::mutate(
        data = normalize_pt_date(data),
        data = lubridate::dmy(data),

        valor_lancamento = readr::parse_number(
          valor_lancamento,
          locale = readr::locale(decimal_mark = ",", grouping_mark = ".")
        ),
        saldo_atual = readr::parse_number(
          saldo_atual,
          locale = readr::locale(decimal_mark = ",", grouping_mark = ".")
        ),

        valor_lancamento = dplyr::if_else(
          dc1 == "C",
          -valor_lancamento,
          valor_lancamento
        ),

        unidade_gestao    = unidade_gestao,
        tipo              = "MOVIMENTO",
        saldo_inicial_fim = NA_real_
      ) |>
      dplyr::select(
        unidade_gestao,
        data,
        tipo,
        codigo_documento,
        valor_lancamento,
        dc1,
        saldo_atual,
        dc2,
        saldo_inicial_fim
      )

    # -- saldo inicial --
    data_inicio        <- if (!is.na(header_data)) header_data else df$data[1]
    saldo_inicial_calc <- df$saldo_atual[1] - df$valor_lancamento[1]

    saldo_inicial_row <- tibble::tibble(
      unidade_gestao    = unidade_gestao,
      data              = data_inicio,
      tipo              = "SALDO_INICIAL",
      codigo_documento  = NA_character_,
      valor_lancamento  = 0,
      dc1               = NA_character_,
      saldo_atual       = saldo_inicial_calc,
      dc2               = df$dc2[1],
      saldo_inicial_fim = saldo_inicial_calc
    )

    # -- saldo final --
    data_fim        <- if (!is.na(header_data_final)) header_data_final else df$data[nrow(df)]
    saldo_final_val <- df$saldo_atual[nrow(df)]

    saldo_final_row <- tibble::tibble(
      unidade_gestao    = unidade_gestao,
      data              = data_fim,
      tipo              = "SALDO_FINAL",
      codigo_documento  = NA_character_,
      valor_lancamento  = 0,
      dc1               = NA_character_,
      saldo_atual       = saldo_final_val,
      dc2               = df$dc2[nrow(df)],
      saldo_inicial_fim = saldo_final_val
    )

    dplyr::bind_rows(saldo_inicial_row, df, saldo_final_row)
  }

  # ---- Validacao de argumentos ----
  if (!dir.exists(source_path)) {
    cli::cli_abort("A pasta {.path {source_path}} n\u00e3o existe.")
  }

  # ---- Listar ficheiros PDF ----
  list_pdf <- list.files(
    path       = source_path,
    pattern    = "\\.pdf$",
    full.names = TRUE,
    recursive  = recursive
  )

  if (!is.null(exclude_pattern)) {
    list_pdf <- stringr::str_subset(list_pdf, exclude_pattern, negate = TRUE)
  }

  if (length(list_pdf) == 0) {
    cli::cli_abort("Nenhum ficheiro PDF encontrado em {.path {source_path}}.")
  }

  # ---- Processar PDFs ----
  df <- list_pdf |>
    purrr::set_names(basename) |>
    purrr::map(extract_sistafe_table) |>
    purrr::list_rbind(names_to = "source_file") |>
    dplyr::mutate(
      ano  = lubridate::year(data),
      mes = as.character(lubridate::month(data, label = TRUE, abbr = FALSE))
    ) |>
    dplyr::relocate(ano, mes, .after = data)

  # ---- Calcular intervalo de datas ----
  date_min <- suppressWarnings(min(df$data, na.rm = TRUE))
  date_max <- suppressWarnings(max(df$data, na.rm = TRUE))

  date_range_txt <- if (is.finite(date_min) && is.finite(date_max)) {
    paste0(format(date_min, "%Y-%m-%d"), "_a_", format(date_max, "%Y-%m-%d"))
  } else {
    "sem_datas"
  }

  attr(df, "date_range_txt") <- date_range_txt

  df
}


# =============================================================================
# processar_extracto_absa()
# Internal helper: .parse_single_absa()
# =============================================================================

# -----------------------------------------------------------------------------
# .parse_single_absa() -- internal, not exported
# Parses a single ABSA statement PDF. Called by processar_extracto_absa().
# -----------------------------------------------------------------------------

.parse_single_absa <- function(pdf_path, y_tolerance = 2, verbose = TRUE) {

  source_file_name <- basename(pdf_path)

  # --- 1. Extract lines from PDF using word-level coordinate data ------------
  # pdf_text() silently truncates ABSA page 1; pdf_data() returns all words
  # with x/y positions. Lines are reconstructed by grouping words that share
  # the same y coordinate (within y_tolerance) and sorting by x.

  reconstruct_lines <- function(page_data) {
    page_data |>
      dplyr::mutate(y_group = round(y / y_tolerance) * y_tolerance) |>
      dplyr::arrange(y_group, x) |>
      dplyr::group_by(y_group) |>
      dplyr::summarise(line = paste(text, collapse = " "), .groups = "drop") |>
      dplyr::arrange(y_group) |>
      dplyr::pull(line)
  }

  lines <- pdf_data(pdf_path) |>
    purrr::map(reconstruct_lines) |>
    unlist() |>
    stringr::str_trim() |>
    purrr::discard(~ .x == "")

  # --- 2. Extract account metadata -------------------------------------------
  account_number <- lines |>
    stringr::str_subset("Nr da Conta") |>
    stringr::str_extract("\\d{10,}") |>
    first() %||% NA_character_

  client_name <- lines |>
    stringr::str_subset("Nome da Cliente") |>
    stringr::str_remove(".*Nome da Cliente\\s*:?\\s*") |>
    stringr::str_trim() |>
    first() %||% NA_character_

  currency <- lines |>
    stringr::str_subset("Nome da Moeda") |>
    stringr::str_extract("MZN|USD|EUR") |>
    first() %||% "MZN"

  # --- 3. Extract opening balance --------------------------------------------
  saldo_abertura <- lines |>
    stringr::str_subset("Saldo de Abertura") |>
    stringr::str_extract("[\\d,]+\\.\\d{2}") |>
    stringr::str_remove_all(",") |>
    as.numeric() |>
    first() %||% NA_real_

  # --- 4. Parse statement period ---------------------------------------------
  all_period_dates <- lines |>
    stringr::str_subset("^Per|^Para\\s*:") |>
    stringr::str_extract_all("\\d{2}/\\d{2}/\\d{4}") |>
    unlist() |>
    lubridate::dmy()

  periodo_inicio <- if (length(all_period_dates) >= 1) min(all_period_dates) else NA
  periodo_fim    <- if (length(all_period_dates) >= 1) max(all_period_dates) else NA

  # --- 5. Filter to transaction lines only -----------------------------------
  # Drop all known header/footer/noise lines. Patterns use ASCII-safe
  # substrings only (no accented characters) to avoid encoding mismatches.

  date_pattern  <- "^\\d{2}/\\d{2}/\\d{4}\\s+\\d+"
  num_pat       <- "[\\d,]+\\.\\d{2}"

  noise_pattern <- paste(c(
    "^Extracto de Conta",
    "^Nome do Balcao",
    "^Per.*De",           # Periodo De
    "^Para\\s*:",
    "^Nr da P",           # Nr da Pagina
    "^Nr da Conta",
    "^NIB No",
    "^Nome do Produto",
    "^Nome da Moeda",
    "^C.*d do Bal",       # Cod do Balcao
    "^Nome Abreviado",
    "^Nr de Identifica",
    "^Nome da Cliente",
    "^Endere",            # Endereco do Cliente
    "^T.*tulo da Conta",  # Titulo da Conta
    "^Data Bal",          # column header row
    "^Saldo de Abertura",
    "^Valor Total",
    "^Nr de D",           # Nr de Debitos
    "^Nr de Cr",          # Nr de Creditos
    "^Saldo de Encer",
    "^Valor da Comissao",
    "^\\*",
    "^-{3,}",
    "^%%",
    "^NR\\s+\\d+",
    "^CIDADE DE",
    "^Maputo",
    "^AV\\s+",
    "Fim do Extracto",
    "^Rel Pty",
    "^Large Corporate"
  ), collapse = "|")

  tx_lines_raw <- lines |> purrr::discard(~ stringr::str_detect(.x, noise_pattern))

  # --- 6. Join continuation lines onto their parent -------------------------
  # Lines without a leading dd/mm/yyyy date are description continuations;
  # they are appended to the preceding transaction line.

  joined_lines <- character(0)
  for (line in tx_lines_raw) {
    if (stringr::str_detect(line, date_pattern)) {
      joined_lines <- c(joined_lines, line)
    } else if (length(joined_lines) > 0) {
      joined_lines[length(joined_lines)] <-
        paste(joined_lines[length(joined_lines)], line)
    }
  }

  # --- 7. Parse each joined line ---------------------------------------------
  transactions <- joined_lines |>
    purrr::map_dfr(function(line) {

      data_str   <- stringr::str_extract(line, "^\\d{2}/\\d{2}/\\d{4}")
      referencia <- stringr::str_extract(line, "\\d{12,}") %||% NA_character_

      # Strip leading date + branch code, long reference numbers, and any
      # mid-line value-date, leaving: description text + debit + credit + saldo
      line_clean <- line |>
        stringr::str_remove("^\\d{2}/\\d{2}/\\d{4}\\s+\\d+\\s+") |>
        stringr::str_remove_all("\\d{12,}")                        |>
        stringr::str_remove_all("\\d{2}/\\d{2}/\\d{4}")            |>
        stringr::str_trim()

      nums <- stringr::str_extract_all(line_clean, num_pat)[[1]] |>
        stringr::str_remove_all(",") |>
        as.numeric()

      if (length(nums) < 3) return(NULL)

      n       <- length(nums)
      debito  <- nums[n - 2]
      credito <- nums[n - 1]
      saldo   <- nums[n]

      desc_raw <- line_clean |>
        stringr::str_remove("[\\d,]+\\.\\d{2}.*$") |>
        stringr::str_trim()

      tibble::tibble(
        data_str   = data_str,
        descricao  = desc_raw,
        referencia = referencia,
        debito     = debito,
        credito    = credito,
        saldo      = saldo
      )
    })

  # --- 8. Remap dummy opening balance date -----------------------------------
  transactions <- transactions |>
    dplyr::mutate(
      data = lubridate::dmy(data_str),
      data = dplyr::if_else(
        data == as.Date("1900-01-01"),
        periodo_inicio %||% lubridate::floor_date(min(lubridate::dmy(data_str), na.rm = TRUE), "month"),
        data
      )
    )

  # --- 9. Classify transaction types -----------------------------------------
  transactions <- transactions |>
    dplyr::mutate(
      tipo = dplyr::case_when(
        stringr::str_detect(descricao, stringr::regex("SALDO DE ABERTURA", ignore_case = TRUE)) ~ "SALDO_INICIAL",
        TRUE ~ "MOVIMENTO"
      )
    )

  # --- 10. Build df_razao-compatible tibble ----------------------------------
  df_movimentos <- transactions |>
    dplyr::mutate(
      source_file       = source_file_name,
      unidade_gestao    = NA_character_,
      ano               = lubridate::year(data),
      mes               = lubridate::month(data, label = TRUE, abbr = FALSE) |> as.character(),
      valor_lancamento  = dplyr::case_when(
        tipo == "SALDO_INICIAL" ~ NA_real_,
        credito > 0             ~ credito,
        TRUE                    ~ -debito
      ),
      dc1 = dplyr::case_when(
        tipo == "SALDO_INICIAL" ~ NA_character_,
        credito > 0             ~ "C",
        debito  > 0             ~ "D",
        TRUE                    ~ NA_character_
      ),
      dc2               = "D",
      codigo_documento  = referencia,
      saldo_atual       = saldo,
      saldo_inicial_fim = dplyr::case_when(
        tipo == "SALDO_INICIAL" ~ saldo_abertura,
        TRUE                    ~ NA_real_
      )
    ) |>
    dplyr::select(source_file, unidade_gestao, data, ano, mes, tipo,
                  codigo_documento, valor_lancamento, dc1,
                  saldo_atual, dc2, saldo_inicial_fim)

  # --- 11. Append closing balance row ----------------------------------------
  total_cred_mov <- sum(df_movimentos$valor_lancamento[
    df_movimentos$tipo == "MOVIMENTO" &
      !is.na(df_movimentos$valor_lancamento) &
      df_movimentos$valor_lancamento > 0])

  total_deb_mov <- abs(sum(df_movimentos$valor_lancamento[
    df_movimentos$tipo == "MOVIMENTO" &
      !is.na(df_movimentos$valor_lancamento) &
      df_movimentos$valor_lancamento < 0]))

  saldo_final_calc <- saldo_abertura + total_cred_mov - total_deb_mov

  data_saldo_final <- if (!is.na(periodo_fim)) {
    lubridate::ceiling_date(periodo_fim, "month") - lubridate::days(1)
  } else {
    lubridate::ceiling_date(max(transactions$data), "month") - lubridate::days(1)
  }

  df_saldo_final <- tibble::tibble(
    source_file       = source_file_name,
    unidade_gestao    = NA_character_,
    data              = data_saldo_final,
    ano               = lubridate::year(data_saldo_final),
    mes               = lubridate::month(data_saldo_final, label = TRUE, abbr = FALSE) |> as.character(),
    tipo              = "SALDO_FINAL",
    codigo_documento  = NA_character_,
    valor_lancamento  = NA_real_,
    dc1               = NA_character_,
    saldo_atual       = saldo_final_calc,
    dc2               = "D",
    saldo_inicial_fim = saldo_final_calc
  )

  # --- 12. Final assembly & sort ---------------------------------------------
  df_out <- dplyr::bind_rows(df_movimentos, df_saldo_final) |>
    dplyr::arrange(data, desc(tipo == "SALDO_INICIAL"), tipo == "SALDO_FINAL")

  # --- 13. Optional per-file summary message ---------------------------------
  if (verbose) {
    message(sprintf("  \u2714 %s \u2014 %d linhas", source_file_name, nrow(df_out)))
  }

  df_out
}


# =============================================================================
# processar_extracto_absa()
# Internal helper: .parse_single_absa()
# =============================================================================

# -----------------------------------------------------------------------------
# .parse_single_absa() internal, not exported
# Parses a single ABSA statement PDF. Called by processar_extracto_absa().
# -----------------------------------------------------------------------------

.parse_single_absa <- function(pdf_path, y_tolerance = 2, verbose = TRUE) {

  source_file_name <- basename(pdf_path)

  # --- 1. Extract lines from PDF using word-level coordinate data ------------
  # pdf_text() silently truncates ABSA page 1; pdf_data() returns all words
  # with x/y positions. Lines are reconstructed by grouping words that share
  # the same y coordinate (within y_tolerance) and sorting by x.

  reconstruct_lines <- function(page_data) {
    page_data |>
      dplyr::mutate(y_group = round(y / y_tolerance) * y_tolerance) |>
      dplyr::arrange(y_group, x) |>
      dplyr::group_by(y_group) |>
      dplyr::summarise(line = paste(text, collapse = " "), .groups = "drop") |>
      dplyr::arrange(y_group) |>
      dplyr::pull(line)
  }

  lines <- pdf_data(pdf_path) |>
    purrr::map(reconstruct_lines) |>
    unlist() |>
    stringr::str_trim() |>
    purrr::discard(~ .x == "")

  # --- 2. Extract account metadata -------------------------------------------
  account_number <- lines |>
    stringr::str_subset("Nr da Conta") |>
    stringr::str_extract("\\d{10,}") |>
    first() %||% NA_character_

  client_name <- lines |>
    stringr::str_subset("Nome da Cliente") |>
    stringr::str_remove(".*Nome da Cliente\\s*:?\\s*") |>
    stringr::str_trim() |>
    first() %||% NA_character_

  currency <- lines |>
    stringr::str_subset("Nome da Moeda") |>
    stringr::str_extract("MZN|USD|EUR") |>
    first() %||% "MZN"

  # --- 3. Extract opening balance --------------------------------------------
  saldo_abertura <- lines |>
    stringr::str_subset("Saldo de Abertura") |>
    stringr::str_extract("[\\d,]+\\.\\d{2}") |>
    stringr::str_remove_all(",") |>
    as.numeric() |>
    first() %||% NA_real_

  # --- 4. Parse statement period ---------------------------------------------
  all_period_dates <- lines |>
    stringr::str_subset("^Per|^Para\\s*:") |>
    stringr::str_extract_all("\\d{2}/\\d{2}/\\d{4}") |>
    unlist() |>
    lubridate::dmy()

  periodo_inicio <- if (length(all_period_dates) >= 1) min(all_period_dates) else NA
  periodo_fim    <- if (length(all_period_dates) >= 1) max(all_period_dates) else NA

  # --- 5. Filter to transaction lines only -----------------------------------
  # Drop all known header/footer/noise lines. Patterns use ASCII-safe
  # substrings only (no accented characters) to avoid encoding mismatches.

  date_pattern  <- "^\\d{2}/\\d{2}/\\d{4}\\s+\\d+"
  num_pat       <- "[\\d,]+\\.\\d{2}"

  noise_pattern <- paste(c(
    "^Extracto de Conta",
    "^Nome do Balcao",
    "^Per.*De",           # Per\u00edodo De
    "^Para\\s*:",
    "^Nr da P",           # Nr da P\u00e1gina
    "^Nr da Conta",
    "^NIB No",
    "^Nome do Produto",
    "^Nome da Moeda",
    "^C.*d do Bal",       # C\u00f3d do Balc\u00e3o
    "^Nome Abreviado",
    "^Nr de Identifica",
    "^Nome da Cliente",
    "^Endere",            # Endere\u00e7o do Cliente
    "^T.*tulo da Conta",  # T\u00edtulo da Conta
    "^Data Bal",          # column header row
    "^Saldo de Abertura",
    "^Valor Total",
    "^Nr de D",           # Nr de Debitos
    "^Nr de Cr",          # Nr de Creditos
    "^Saldo de Encer",
    "^Valor da Comissao",
    "^\\*",
    "^-{3,}",
    "^%%",
    "^NR\\s+\\d+",
    "^CIDADE DE",
    "^Maputo",
    "^AV\\s+",
    "Fim do Extracto",
    "^Rel Pty",
    "^Large Corporate"
  ), collapse = "|")

  tx_lines_raw <- lines |> purrr::discard(~ stringr::str_detect(.x, noise_pattern))

  # --- 6. Join continuation lines onto their parent -------------------------
  # Lines without a leading dd/mm/yyyy date are description continuations;
  # they are appended to the preceding transaction line.

  joined_lines <- character(0)
  for (line in tx_lines_raw) {
    if (stringr::str_detect(line, date_pattern)) {
      joined_lines <- c(joined_lines, line)
    } else if (length(joined_lines) > 0) {
      joined_lines[length(joined_lines)] <-
        paste(joined_lines[length(joined_lines)], line)
    }
  }

  # --- 7. Parse each joined line ---------------------------------------------
  transactions <- joined_lines |>
    purrr::map_dfr(function(line) {

      data_str   <- stringr::str_extract(line, "^\\d{2}/\\d{2}/\\d{4}")
      referencia <- stringr::str_extract(line, "\\d{12,}") %||% NA_character_

      # Strip leading date + branch code, long reference numbers, and any
      # mid-line value-date, leaving: description text + debit + credit + saldo
      line_clean <- line |>
        stringr::str_remove("^\\d{2}/\\d{2}/\\d{4}\\s+\\d+\\s+") |>
        stringr::str_remove_all("\\d{12,}")                        |>
        stringr::str_remove_all("\\d{2}/\\d{2}/\\d{4}")            |>
        stringr::str_trim()

      nums <- stringr::str_extract_all(line_clean, num_pat)[[1]] |>
        stringr::str_remove_all(",") |>
        as.numeric()

      if (length(nums) < 3) return(NULL)

      n       <- length(nums)
      debito  <- nums[n - 2]
      credito <- nums[n - 1]
      saldo   <- nums[n]

      desc_raw <- line_clean |>
        stringr::str_remove("[\\d,]+\\.\\d{2}.*$") |>
        stringr::str_trim()

      tibble::tibble(
        data_str   = data_str,
        descricao  = desc_raw,
        referencia = referencia,
        debito     = debito,
        credito    = credito,
        saldo      = saldo
      )
    })

  # --- 8. Remap dummy opening balance date -----------------------------------
  transactions <- transactions |>
    dplyr::mutate(
      data = lubridate::dmy(data_str),
      data = dplyr::if_else(
        data == as.Date("1900-01-01"),
        periodo_inicio %||% lubridate::floor_date(min(lubridate::dmy(data_str), na.rm = TRUE), "month"),
        data
      )
    )

  # --- 9. Classify transaction types -----------------------------------------
  transactions <- transactions |>
    dplyr::mutate(
      tipo = dplyr::case_when(
        stringr::str_detect(descricao, stringr::regex("SALDO DE ABERTURA", ignore_case = TRUE)) ~ "SALDO_INICIAL",
        TRUE ~ "MOVIMENTO"
      )
    )

  # --- 10. Build df_razao-compatible tibble ----------------------------------
  df_movimentos <- transactions |>
    dplyr::mutate(
      source_file       = source_file_name,
      unidade_gestao    = NA_character_,
      ano               = lubridate::year(data),
      mes               = lubridate::month(data, label = TRUE, abbr = FALSE) |> as.character(),
      valor_lancamento  = dplyr::case_when(
        tipo == "SALDO_INICIAL" ~ NA_real_,
        credito > 0             ~ credito,
        TRUE                    ~ -debito
      ),
      dc1 = dplyr::case_when(
        tipo == "SALDO_INICIAL" ~ NA_character_,
        credito > 0             ~ "C",
        debito  > 0             ~ "D",
        TRUE                    ~ NA_character_
      ),
      dc2               = "D",
      codigo_documento  = referencia,
      saldo_atual       = saldo,
      saldo_inicial_fim = dplyr::case_when(
        tipo == "SALDO_INICIAL" ~ saldo_abertura,
        TRUE                    ~ NA_real_
      )
    ) |>
    dplyr::select(source_file, unidade_gestao, data, ano, mes, tipo,
                  codigo_documento, valor_lancamento, dc1,
                  saldo_atual, dc2, saldo_inicial_fim)

  # --- 11. Append closing balance row ----------------------------------------
  total_cred_mov <- sum(df_movimentos$valor_lancamento[
    df_movimentos$tipo == "MOVIMENTO" &
      !is.na(df_movimentos$valor_lancamento) &
      df_movimentos$valor_lancamento > 0])

  total_deb_mov <- abs(sum(df_movimentos$valor_lancamento[
    df_movimentos$tipo == "MOVIMENTO" &
      !is.na(df_movimentos$valor_lancamento) &
      df_movimentos$valor_lancamento < 0]))

  saldo_final_calc <- saldo_abertura + total_cred_mov - total_deb_mov

  data_saldo_final <- if (!is.na(periodo_fim)) {
    lubridate::ceiling_date(periodo_fim, "month") - lubridate::days(1)
  } else {
    lubridate::ceiling_date(max(transactions$data), "month") - lubridate::days(1)
  }

  df_saldo_final <- tibble::tibble(
    source_file       = source_file_name,
    unidade_gestao    = NA_character_,
    data              = data_saldo_final,
    ano               = lubridate::year(data_saldo_final),
    mes               = lubridate::month(data_saldo_final, label = TRUE, abbr = FALSE) |> as.character(),
    tipo              = "SALDO_FINAL",
    codigo_documento  = NA_character_,
    valor_lancamento  = NA_real_,
    dc1               = NA_character_,
    saldo_atual       = saldo_final_calc,
    dc2               = "D",
    saldo_inicial_fim = saldo_final_calc
  )

  # --- 12. Final assembly & sort ---------------------------------------------
  df_out <- dplyr::bind_rows(df_movimentos, df_saldo_final) |>
    dplyr::arrange(data, desc(tipo == "SALDO_INICIAL"), tipo == "SALDO_FINAL")

  # --- 13. Optional per-file summary message ---------------------------------
  if (verbose) {
    message(sprintf("  \u2714 %s \u2014 %d linhas", source_file_name, nrow(df_out)))
  }

  df_out
}


# =============================================================================

#' Processar Extractos Bancarios ABSA
#'
#' Localiza todos os ficheiros PDF com o padrao \code{"EXTRACTO ABSA"} numa
#' pasta, processa cada um e devolve um unico tibble combinado compativel com o
#' esquema \code{df_razao} utilizado no pipeline do \code{easystafe}.
#'
#' @param source_path \code{character(1)}. Caminho para a pasta que contem os
#'   ficheiros PDF dos extractos ABSA.
#' @param pattern \code{character(1)}. Padrao regex usado para identificar os
#'   ficheiros ABSA dentro de \code{source_path}. O padrao predefinido
#'   \code{"EXTRACTO ABSA"} corresponde ao nome de ficheiro padrao dos
#'   extractos ABSA Mocambique. Nao faz distincao entre maiusculas e
#'   minusculas. Default: \code{"EXTRACTO ABSA"}.
#' @param recursive \code{logical(1)}. Se \code{TRUE}, pesquisa tambem nas
#'   subpastas de \code{source_path}. Default: \code{FALSE}.
#' @param y_tolerance \code{numeric(1)}. Tolerancia vertical (em pontos PDF)
#'   para agrupar palavras na mesma linha durante a reconstrucao por
#'   coordenadas. O valor predefinido de \code{2} funciona para os extractos
#'   ABSA padrao. Default: \code{2}.
#' @param verbose \code{logical(1)}. Se \code{TRUE}, imprime uma linha de
#'   resumo por ficheiro processado e um total no final. Default: \code{TRUE}.
#'
#' @return Um tibble com 12 colunas correspondentes ao esquema \code{df_razao}:
#' \describe{
#'   \item{source_file}{\code{character}. Nome do ficheiro PDF de origem.}
#'   \item{unidade_gestao}{\code{character}. Sempre \code{NA} -- a preencher
#'     downstream.}
#'   \item{data}{\code{Date}. Data do movimento. A data ficticia de abertura
#'     (\code{01/01/1900}) e remapeada para o primeiro dia do periodo do
#'     extracto.}
#'   \item{ano}{\code{integer}. Ano extraido de \code{data}.}
#'   \item{mes}{\code{character}. Nome completo do mes em ingles (e.g.
#'     \code{"February"}).}
#'   \item{tipo}{\code{character}. Um de \code{"SALDO_INICIAL"},
#'     \code{"MOVIMENTO"} ou \code{"SALDO_FINAL"}.}
#'   \item{codigo_documento}{\code{character}. Numero de referencia do
#'     movimento, quando presente. \code{NA} caso contrario.}
#'   \item{valor_lancamento}{\code{double}. Valor assinado do movimento:
#'     positivo para creditos, negativo para debitos. \code{NA} nas linhas de
#'     saldo.}
#'   \item{dc1}{\code{character}. Indicador debito/credito do movimento:
#'     \code{"C"}, \code{"D"} ou \code{NA}.}
#'   \item{saldo_atual}{\code{double}. Saldo corrente apos o movimento.}
#'   \item{dc2}{\code{character}. Indicador debito/credito do saldo. Sempre
#'     \code{"D"} para este tipo de conta.}
#'   \item{saldo_inicial_fim}{\code{double}. Saldo de abertura em
#'     \code{SALDO_INICIAL}; saldo calculado (abertura + creditos - debitos)
#'     em \code{SALDO_FINAL}; \code{NA} nos movimentos.}
#' }
#'
#' @details
#' O layout dos PDFs ABSA apresenta dois problemas conhecidos que esta funcao
#' resolve:
#'
#' \enumerate{
#'   \item \strong{Truncagem de pagina}: \code{pdftools::pdf_text()} trunca
#'     silenciosamente a primeira pagina. A funcao usa
#'     \code{pdftools::pdf_data()} em alternativa, reconstruindo as linhas a
#'     partir das coordenadas x/y de cada palavra.
#'   \item \strong{Linhas de continuacao}: Descricoes longas e numeros de
#'     referencia podem continuar numa segunda linha sem data inicial. Essas
#'     linhas sao detectadas e concatenadas a linha de transaccao anterior.
#' }
#'
#' A linha de fecho (\code{SALDO_FINAL}) e acrescentada programaticamente e
#' nao extraida do rodape do PDF. O seu \code{saldo_inicial_fim} e calculado
#' como \code{saldo_abertura + sum(creditos) - sum(debitos)}.
#'
#' @examples
#' \dontrun{
#' # Processar todos os extractos ABSA numa pasta
#' df_absa <- processar_extracto_absa("Data/razao_cont/2026_02/outro/")
#'
#' # Combinar com outros extractos do razao
#' df_razao <- bind_rows(df_razao, df_absa)
#'
#' # Usar um padrao diferente ou pesquisar em subpastas
#' df_absa <- processar_extracto_absa(
#'   source_path = "Data/razao_cont/",
#'   pattern     = "ABSA",
#'   recursive   = TRUE
#' )
#' }
#'
#' @importFrom pdftools pdf_data
#' @importFrom dplyr mutate case_when arrange group_by summarise bind_rows
#'   select
#' @importFrom purrr map map_dfr discard
#' @importFrom stringr str_trim str_detect str_extract str_extract_all
#'   str_remove str_remove_all str_subset
#' @importFrom lubridate dmy year month floor_date ceiling_date days
#' @importFrom tibble tibble
#'
#' @export

processar_extracto_absa <- function(source_path,
                                    pattern     = "EXTRACTO ABSA",
                                    recursive   = FALSE,
                                    y_tolerance = 2,
                                    verbose     = TRUE) {

  # --- 0. Validate input -----------------------------------------------------
  stopifnot(
    "source_path must be a single character string" =
      is.character(source_path) && length(source_path) == 1,
    "y_tolerance must be a positive number" =
      is.numeric(y_tolerance) && y_tolerance > 0,
    "verbose must be TRUE or FALSE" =
      is.logical(verbose) && length(verbose) == 1,
    "recursive must be TRUE or FALSE" =
      is.logical(recursive) && length(recursive) == 1
  )
  if (!dir.exists(source_path)) stop("Pasta n\u00e3o encontrada: ", source_path)

  # --- 1. Locate matching PDF files ------------------------------------------
  pdf_files <- list.files(
    path         = source_path,
    pattern      = pattern,
    full.names   = TRUE,
    recursive    = recursive,
    ignore.case  = TRUE
  )

  if (length(pdf_files) == 0) {
    stop(
      "Nenhum ficheiro PDF correspondente ao padr\u00e3o '", pattern,
      "' encontrado em: ", source_path
    )
  }

  if (verbose) {
    message(sprintf(
      "--- processar_extracto_absa() --- %d ficheiro(s) encontrado(s)",
      length(pdf_files)
    ))
  }

  # --- 2. Parse each file and bind -------------------------------------------
  df_out <- pdf_files |>
    purrr::set_names(basename) |>
    purrr::map(\(f) .parse_single_absa(f, y_tolerance = y_tolerance, verbose = verbose)) |>
    purrr::list_rbind()

  # --- 3. Summary ------------------------------------------------------------
  if (verbose) {
    message(sprintf("Total linhas output  : %d", nrow(df_out)))
    message(sprintf("Ficheiros processados: %d", length(pdf_files)))
  }

  df_out
}
