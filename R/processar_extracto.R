#' Processar extractos 'Demonstrativo Consolidado' do e-SISTAFE
#'
#' Carrega, limpa e processa um ou mais ficheiros de exportacao do e-SISTAFE
#' no formato Excel, aplicando uma sequencia de transformacoes que inclui
#' renomeacao de colunas, filtragem de UGBs de educacao, classificacao e
#' subtraccao hierarquica de codigos CED, e restauracao da estrutura original
#' de colunas. Devolve um dataframe final desduplicado e pronto para analise.
#'
#' @param source_path A character vector with one or more file paths to
#'   e-SISTAFE export files in \code{.xlsx} format.
#' @param df_ugb_lookup A dataframe with the education UGB reference table.
#'   Must contain at least the column \code{codigo_ugb} with 9-character UGB
#'   codes (e.g. \code{"50B105761"}). Only rows whose \code{ugb_id} matches a
#'   value in \code{codigo_ugb} are retained during processing.
#' @param include_pattern A character string with a regex pattern used to
#'   retain only files whose \code{file_name} matches the pattern. Defaults to
#'   \code{"DemonstrativoConsolidado"}, which retains only consolidated
#'   statement files. Set to \code{NULL} to skip filtering and process all
#'   loaded files regardless of name.
#' @param include_percent Logical. If \code{TRUE} (default), the
#'   \code{percent} columns are included in the output (filled with
#'   \code{NA}). If \code{FALSE}, those columns are removed from the final
#'   result.
#' @param include_file_metadata Logical. If \code{TRUE} (default), metadata
#'   extracted from the file name (report type, dates) are added to the
#'   dataframe immediately after the \code{file_name} column. If \code{FALSE},
#'   metadata are not added and the \code{file_name} column is also removed
#'   from the final result.
#' @param include_metrica Logical. If \code{TRUE} (default), rows of type
#'   \code{"Metrica"} are reincluded in the final output after hierarchical
#'   subtraction, useful for comparisons and validation. If \code{FALSE},
#'   only \code{"Valor"} rows are retained in the final output. The
#'   \code{data_tipo} column is always included in the output regardless of
#'   this parameter.
#' @param correct_negatives Logical. If \code{TRUE} (default), negative values
#'   in the 11 main numeric columns are detected and corrected: they are set to
#'   zero in the original \code{"Valor"} rows, audit copies of the affected
#'   rows are appended with \code{data_tipo == "Corregido"}, and two flag
#'   columns are added -- \code{valor_corregido} (\code{1L} for any row whose
#'   \code{ugb_funcao_prog_fr} contained a negative of any magnitude) and
#'   \code{valor_negativo} (\code{1L} only where the absolute value of the
#'   negative was \eqn{\geq 1}). If \code{FALSE}, this entire block is
#'   skipped: negative values are left as-is, no \code{"Corregido"} rows are
#'   added, and the two flag columns are not created.
#' @param quiet Logical. If \code{TRUE} (default), progress messages are
#'   suppressed. If \code{FALSE}, a message is emitted for each processing
#'   step. Regardless of this parameter, a final message with the number of
#'   processed files is always emitted.
#'
#' @return Um tibble com uma linha por entrada CED deduplificada, contendo
#'   as colunas originais do extracto e-SISTAFE apos limpeza e subtraccao
#'   hierarquica. A coluna \code{data_tipo} esta sempre presente e posicionada
#'   imediatamente antes de \code{ugb}. Tres colunas hierarquicas derivadas de
#'   \code{ced} sao sempre incluidas imediatamente a seguir a \code{ced}:
#'   \code{ced_2} (primeiros 2 digitos com sufixo \code{"0000"}) e
#'   \code{ced_3} (primeiros 3 digitos);
#'   ambas sao \code{NA} nas linhas \code{"Metrica"}. As colunas de percentagem
#'   sao sempre incluidas na estrutura original (preenchidas com \code{NA})
#'   salvo se \code{include_percent = FALSE}. A coluna \code{pasta_fonte} contem
#'   o nome da pasta imediata de onde os dados foram carregados. As colunas
#'   \code{ano} (inteiro), \code{mes} (caracter em portugues) e
#'   \code{periodo} (data do primeiro dia do mes, classe \code{Date}) sao
#'   derivados do nome da pasta quando este segue o formato \code{YYYYMM};
#'   caso contrario sao preenchidos com \code{NA} e e emitido um aviso.
#'
#' @details
#' O processamento segue as seguintes etapas principais:
#' \enumerate{
#'   \item Carregamento e combinacao de todos os ficheiros em \code{source_path}.
#'   \item Adicao de \code{pasta_fonte}, \code{ano}, \code{mes} e
#'     \code{periodo} derivados do nome da pasta de origem. Se o nome da
#'     pasta nao seguir o formato \code{YYYYMM}, \code{ano}, \code{mes} e
#'     \code{periodo} sao \code{NA} e e emitido um \code{warning()}.
#'   \item Adicao opcional de metadados via \code{extrair_meta_extracto()}
#'     (reporte_tipo, data_reporte, data_extraido -- sem ano nem mes).
#'   \item Limpeza de nomes de colunas com \code{janitor::clean_names()}.
#'   \item Remocao de colunas \code{percent}.
#'   \item Conversao de colunas numericas e extraccao do codigo \code{ugb_id}.
#'   \item Filtragem de UGBs validos de educacao a partir de \code{df_ugb_lookup}.
#'   \item Remocao de linhas com CED e campos-chave em branco.
#'   \item Classificacao de grupos CED (A, B, C, D) e remocao do grupo D.
#'   \item Criacao de variaveis hierarquicas: \code{ced_4} (primeiros 4 digitos
#'     de \code{ced} -- usada internamente e removida no output final),
#'     \code{ced_3} (primeiros 3 digitos), \code{ced_2}
#'     (primeiros 2 digitos com sufixo \code{"0000"}), e chaves compostas
#'     auxiliares \code{id_ced_b4} e \code{id_ced_b3} (usadas internamente e
#'     removidas no output final).
#'   \item Separacao de linhas \code{"Metrica"} e \code{"Valor"} antes da
#'     subtraccao hierarquica.
#'   \item Subtraccao hierarquica em tres passos para eliminar dupla contagem
#'     (aplicada apenas a linhas \code{"Valor"}):
#'     \itemize{
#'       \item Passo 1: Subtrair grupo A do grupo B (dentro de \code{ced_4}).
#'       \item Passo 2: Subtrair grupo B ajustado do grupo C (dentro de \code{ced_3}).
#'       \item Passo 3: Subtrair grupo A directamente do grupo C (dentro de \code{ced_3}).
#'     }
#'   \item Reinclusao opcional das linhas \code{"Metrica"} via \code{include_metrica}.
#'   \item Seleccao das colunas finais a partir de um vector explicito,
#'     garantindo que \code{data_tipo} e sempre incluido antes de \code{ugb}.
#'   \item Deteccao e correccao de valores negativos (apenas quando
#'     \code{correct_negatives = TRUE}):
#'     \itemize{
#'       \item Calculo do denominador: soma total das colunas numericas em linhas
#'         \code{"Valor"} antes de qualquer correccao.
#'       \item Identificacao dos \code{ugb_funcao_prog_fr} distintos com pelo
#'         menos um valor negativo em qualquer coluna numerica.
#'       \item Criacao de uma copia dessas linhas com \code{data_tipo} recodificado
#'         para \code{"Corregido"}, preservando os valores negativos originais
#'         como registo de auditoria.
#'       \item Substituicao dos valores negativos por zero nas linhas originais
#'         \code{"Valor"} (cirurgicamente, coluna a coluna).
#'       \item Anexacao da copia \code{"Corregido"} ao dataset final.
#'       \item Criacao de \code{valor_corregido}: \code{1L} para todas as linhas
#'         cujo \code{ugb_funcao_prog_fr} continha pelo menos um valor negativo
#'         (qualquer magnitude); \code{0L} caso contrario.
#'       \item Criacao de \code{valor_negativo}: \code{1L} apenas para linhas
#'         onde pelo menos uma coluna numerica tinha valor \eqn{\leq -1}
#'         (valor absoluto \eqn{\geq 1}); \code{0L} caso contrario.
#'       \item Emissao de mensagem de resumo com o numero de grupos corrigidos,
#'         a soma absoluta dos valores corrigidos, e a respectiva percentagem
#'         da soma total \code{"Valor"}.
#'     }
#' }
#'
#' @examples
#' \dontrun{
#' ugb_lookup <- readxl::read_excel("Data/ugb/Codigos de UGBs.xlsx", sheet = "UGBS")
#'
#' # Padrao -- pasta com formato YYYYMM, correccao de negativos activa
#' df <- processar_extracto_esistafe(
#'   source_path   = "Data/202602/",
#'   df_ugb_lookup = ugb_lookup
#' )
#'
#' # Sem correccao de negativos
#' df <- processar_extracto_esistafe(
#'   source_path        = "Data/202602/",
#'   df_ugb_lookup      = ugb_lookup,
#'   correct_negatives  = FALSE
#' )
#'
#' # Sem metadados, sem colunas percent
#' df <- processar_extracto_esistafe(
#'   source_path           = "Data/202602/",
#'   df_ugb_lookup         = ugb_lookup,
#'   include_percent       = FALSE,
#'   include_file_metadata = FALSE
#' )
#'
#' # Com mensagens de progresso
#' df <- processar_extracto_esistafe(
#'   source_path   = "Data/202602/",
#'   df_ugb_lookup = ugb_lookup,
#'   quiet         = FALSE
#' )
#' }
#'
#' @importFrom purrr map keep
#' @importFrom readxl read_excel
#' @importFrom dplyr n_distinct mutate across relocate filter select left_join if_else case_when group_by ungroup bind_rows distinct row_number pull summarise pick
#' @importFrom tidyr unite
#' @importFrom stringr str_ends str_sub str_c
#' @importFrom janitor clean_names
#' @importFrom glue glue
#' @importFrom tibble tibble
#' @importFrom scales comma percent
#'
#' @export
processar_extracto_esistafe <- function(
    source_path        = "Data/",
    df_ugb_lookup,
    include_pattern    = "DemonstrativoConsolidado",
    include_percent    = TRUE,
    include_file_metadata = TRUE,
    include_metrica    = TRUE,
    correct_negatives  = TRUE,
    quiet              = TRUE
) {
  # --- Mensagens internas ---
  msg <- function(...) {
    if (!quiet) message(...)
  }

  # --- 1. Identificar e carregar ficheiros ---
  msg("A identificar ficheiros...")
  files <- base::list.files(
    path       = source_path,
    pattern    = include_pattern,
    full.names = TRUE
  )
  if (length(files) == 0) {
    stop(glue::glue("Nenhum ficheiro encontrado em '{source_path}' com o padrao '{include_pattern}'."))
  }
  msg(glue::glue("{length(files)} ficheiro(s) encontrado(s). A carregar..."))
  df <- purrr::map(files, ~readxl::read_excel(.x, col_types = "text")) |>
    purrr::set_names(base::basename(files)) |>
    purrr::list_rbind(names_to = "file_name")
  msg(glue::glue("Ficheiros carregados: {dplyr::n_distinct(df$file_name)} | Linhas: {nrow(df)}"))

  # --- 1b. Adicionar pasta_fonte, ano e mes ---
  # ano e mes sao derivados do nome da pasta se seguir o formato YYYYMM.
  # Caso contrario, sao NA e e emitido um aviso.
  msg("A adicionar pasta_fonte, ano e mes...")
  pasta <- base::basename(base::normalizePath(source_path, mustWork = FALSE))

  meses_pt <- c(
    "Janeiro", "Fevereiro", "Mar\u00e7o", "Abril",
    "Maio", "Junho", "Julho", "Agosto",
    "Setembro", "Outubro", "Novembro", "Dezembro"
  )

  if (base::grepl("^\\d{6}$", pasta)) {
    ano_fonte     <- base::as.integer(base::substr(pasta, 1, 4))
    mes_num       <- base::as.numeric(base::substr(pasta, 5, 6))
    mes_fonte     <- meses_pt[mes_num]
    periodo_fonte <- as.Date(base::paste(ano_fonte, mes_num, "01", sep = "-"))
  } else {
    ano_fonte     <- NA_integer_
    mes_fonte     <- NA_character_
    periodo_fonte <- as.Date(NA)
    warning(glue::glue(
      "O nome da pasta '{pasta}' nao segue o formato YYYYMM. ",
      "As colunas 'ano', 'mes' e 'periodo' foram preenchidas com NA."
    ))
  }

  df <- df |>
    dplyr::mutate(
      pasta_fonte = pasta,
      ano         = ano_fonte,
      mes         = mes_fonte,
      periodo     = periodo_fonte
    )

  # --- 2. Adicionar ou remover metadados ---
  # Nota: extrair_meta_extracto() ja nao devolve ano nem mes --
  # essas colunas sao agora derivadas de pasta_fonte (Step 1b).
  if (include_file_metadata) {
    msg("A extrair e adicionar metadados...")
    paths_meta <- extrair_meta_extracto(files) |>
      dplyr::rename_with(~ gsub("_meta$", "", .x))
    df <- df |>
      dplyr::left_join(paths_meta, by = "file_name") |>
      dplyr::relocate(names(paths_meta)[-1], .after = file_name)
  }

  # --- 3. Renomear colunas ---
  msg("A limpar nomes de colunas...")
  df_limpeza_1 <- janitor::clean_names(df)

  # --- 4. Remover colunas percent ---
  msg("A remover colunas percentuais...")
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
  msg("A filtrar UGB's de educa\u00e7\u00e3o...")
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
      ced_4     = stringr::str_sub(ced, 1, 4),
      ced_3     = stringr::str_sub(ced, 1, 3),
      ced_2     = stringr::str_c(stringr::str_sub(ced, 1, 2), "0000"),
      id_ced_b4 = stringr::str_c(ugb_id, funcao, programa, fr, ced_4, sep = " | "),
      id_ced_b3 = stringr::str_c(ugb_id, funcao, programa, fr, ced_3, sep = " | ")
    ) |>
    tidyr::unite(ugb_funcao_prog_fr, ugb_id, funcao, programa, fr, sep = " | ", remove = FALSE, na.rm = FALSE) |>
    dplyr::relocate(c(ced_4, ced_3), .after = ced) |>
    dplyr::relocate(ced_group, .before = ced) |>
    dplyr::relocate(data_tipo, .after = ced_3) |>
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
  msg("A executar subtra\u00e7\u00e3o hier\u00e1rquica \u2014 Passo 1 (A \u2192 B)...")
  df_step1 <- df_limpeza_7 |>
    dplyr::filter(data_tipo == "Valor") |>
    dplyr::group_by(ugb_funcao_prog_fr, ced_4) |>
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
    dplyr::group_by(ugb_funcao_prog_fr, ced_3) |>
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
    dplyr::group_by(ugb_funcao_prog_fr, ced_3) |>
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
  # pasta_fonte e sempre retido independentemente de include_file_metadata.
  # ano e mes sao sempre retidos (podem ser NA se pasta_fonte nao for YYYYMM).
  # data_tipo e sempre incluido, posicionado antes de ugb.
  # percent e file_name sao incluidos ou excluidos conforme os argumentos.
  msg("A finalizar estrutura do dataset...")
  final_cols <- c(
    # metadados de ficheiro (removidos se include_file_metadata = FALSE)
    "file_name",
    "pasta_fonte",
    "ugb_funcao_prog_fr",
    "reporte_tipo",
    "data_reporte",
    "data_extraido",
    "periodo",
    "ano",
    "mes",
    # classificacao da linha -- sempre presente
    "data_tipo",
    "ugb_id",
    # identificadores orcamentais
    "ugb", "funcao", "programa", "fr", "ced",
    "ced_2", "ced_3",
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
  # Nota: pasta_fonte, ano e mes sao sempre retidos independentemente de
  # include_file_metadata, pois identificam a origem temporal dos dados.
  if (!include_file_metadata) {
    df_limpeza_final <- df_limpeza_final |>
      dplyr::select(-dplyr::any_of(c("file_name", "reporte_tipo", "data_reporte", "data_extraido", "ugb_id")))
  }

  # --- 17. Detectar e corrigir valores negativos (apenas se correct_negatives = TRUE) ---
  if (correct_negatives) {

    neg_cols <- c(
      "dotacao_inicial", "dotacao_revista", "dotacao_actualizada_da",
      "dotacao_disponivel", "dotacao_cabimentada_dc", "ad_fundos_concedidos_af",
      "despesa_paga_via_directa_dp", "ad_fundos_desp_paga_vd_afdp",
      "ad_fundos_liquidados_laf", "despesa_liquidada_via_directa_lvd",
      "liq_ad_fundos_via_directa_lafvd"
    ) |>
      purrr::keep(~ .x %in% names(df_limpeza_final))

    # -- 17a. Calcular denominador (soma total de "Valor" antes de qualquer correccao) --
    total_sum_valor <- df_limpeza_final |>
      dplyr::filter(data_tipo == "Valor") |>
      dplyr::summarise(dplyr::across(dplyr::all_of(neg_cols), ~ sum(.x, na.rm = TRUE))) |>
      dplyr::summarise(total = rowSums(dplyr::pick(dplyr::everything()))) |>
      dplyr::pull(total)

    # -- 17b. Adicionar row ID temporario e identificar grupos/linhas com negativos --
    df_limpeza_final <- df_limpeza_final |>
      dplyr::mutate(.row_id = dplyr::row_number())

    # Grupos (ugb_funcao_prog_fr) com pelo menos um valor negativo de qualquer magnitude
    ugb_com_negativos <- df_limpeza_final |>
      dplyr::filter(
        data_tipo == "Valor",
        dplyr::if_any(dplyr::all_of(neg_cols), ~ .x < 0)
      ) |>
      dplyr::distinct(ugb_funcao_prog_fr) |>
      dplyr::pull(ugb_funcao_prog_fr)

    # Linhas com pelo menos um valor negativo com valor absoluto >= 1 (valor <= -1)
    rows_sig_correccao <- df_limpeza_final |>
      dplyr::filter(
        data_tipo == "Valor",
        dplyr::if_any(dplyr::all_of(neg_cols), ~ !is.na(.x) & .x <= -1)
      ) |>
      dplyr::pull(.row_id)

    # -- 17c. Calcular soma absoluta dos negativos (antes de corrigir) --
    soma_negativos <- df_limpeza_final |>
      dplyr::filter(
        data_tipo == "Valor",
        ugb_funcao_prog_fr %in% ugb_com_negativos
      ) |>
      dplyr::summarise(dplyr::across(dplyr::all_of(neg_cols), ~ sum(pmin(.x, 0), na.rm = TRUE))) |>
      dplyr::summarise(total = rowSums(dplyr::pick(dplyr::everything()))) |>
      dplyr::pull(total) |>
      abs()

    # -- 17d. Criar copia "Corregido" com valores negativos preservados --
    df_corregido <- df_limpeza_final |>
      dplyr::filter(
        data_tipo == "Valor",
        ugb_funcao_prog_fr %in% ugb_com_negativos
      ) |>
      dplyr::mutate(data_tipo = "Corregido")

    # -- 17e. Zerar negativos no dataset original apenas em linhas "Valor" --
    df_limpeza_final <- df_limpeza_final |>
      dplyr::mutate(
        dplyr::across(
          dplyr::all_of(neg_cols),
          ~ dplyr::if_else(data_tipo == "Valor" & .x < 0, 0, .x)
        )
      )

    # -- 17f. Anexar copia "Corregido" --
    df_limpeza_final <- dplyr::bind_rows(df_limpeza_final, df_corregido)

    # -- 17f.2. Criar variaveis valor_corregido e valor_negativo --
    # valor_corregido: 1 para todas as linhas cujo ugb_funcao_prog_fr tinha
    #   qualquer valor negativo (independentemente da magnitude)
    # valor_negativo:  1 apenas para linhas onde pelo menos uma coluna numerica
    #   tinha valor absoluto >= 1 (i.e., valor <= -1)
    df_limpeza_final <- df_limpeza_final |>
      dplyr::mutate(
        valor_corregido = dplyr::if_else(ugb_funcao_prog_fr %in% ugb_com_negativos, 1L, 0L),
        valor_negativo  = dplyr::if_else(.row_id %in% rows_sig_correccao, 1L, 0L)
      ) |>
      dplyr::select(-.row_id) |>
      dplyr::relocate(c(valor_corregido, valor_negativo), .after = ugb_funcao_prog_fr)

    # -- 17g. Mensagem de resumo (sempre visivel) --
    pct_negativos <- if (total_sum_valor != 0) {
      scales::percent(soma_negativos / abs(total_sum_valor), accuracy = 0.01)
    } else {
      "N/A (soma total == 0)"
    }
    message(glue::glue(
      "Correccao de negativos: {length(ugb_com_negativos)} ugb_funcao_prog_fr(s) identificado(s) e corrigido(s).\n",
      "  Soma absoluta dos valores negativos convertidos a zero: {scales::comma(soma_negativos)} ({pct_negativos} da soma total de colunas numericas [data_tipo == 'Valor'])."
    ))

  } # fim do bloco correct_negatives

  # --- Resumo final ---
  n_files   <- length(files)
  file_list <- base::paste(base::paste0("  - ", base::basename(files)), collapse = "\n")
  message(glue::glue(
    "Processamento concluido: {n_files} ficheiro(s) processado(s) com sucesso.\n{file_list}"
  ))

  # --- Verificar completude de UGBs ---
  verificar_ugb_completude(df_limpeza_final, df_ugb_lookup, quiet = quiet)

  return(df_limpeza_final)
}



#' Processar extractos 'Razao Contabilistico' a partir de ficheiros PDF
#'
#' Le todos os ficheiros PDF de uma pasta, extrai as transaccoes e saldos
#' de cada extracto da razao contabilistico, e combina os resultados num
#' unico tibble. Ficheiros com formato FOREX (USD/EUR) sao excluidos por
#' padrao.
#'
#'
#' @param source_path Caractere. Caminho para a pasta que contem os ficheiros
#'   PDF a processar. Obrigatorio.
#' @param exclude_pattern Caractere. Expressao regular para excluir ficheiros
#'   pelo nome. Por padrao exclui ficheiros FOREX:
#'   \code{"CAMBIO|FOREX|EXTRACTO|DemonstrativoConsolidado"}.
#'   Para nao excluir nenhum ficheiro, usar \code{NULL}.
#' @param recursive Logico. Se \code{TRUE}, a pesquisa de ficheiros PDF
#'   inclui subpastas. Por padrao \code{FALSE}.
#' @param quiet Logico. Se \code{TRUE} (padrao), suprime as mensagens emitidas
#'   por ficheiro durante o processamento (por exemplo, quando um PDF nao
#'   contem transaccoes). Se \code{FALSE}, as mensagens sao apresentadas.
#' @return Um tibble com uma linha por registo (movimentos, saldo inicial e
#'   saldo final) de todos os PDFs processados. Aplique
#'   \code{\link{adicionar_conversao_moeda}} ao resultado para adicionar as
#'   colunas de conversao de moeda com taxas diarias.
#'
#' @examples
#' \dontrun{
#' df_razao <- processar_extracto_razao_c(
#'   source_path = path_folder_source
#' )
#' }
#'
#' @export

processar_extracto_razao_c <- function(
    source_path,
    exclude_pattern = "CAMBIO|FOREX|EXTRACTO|DemonstrativoConsolidado",
    recursive       = FALSE,
    quiet           = TRUE
) {

  # ---- Helper interno: extrair tabela de um PDF ----
  extract_sistafe_table <- function(path_pdf) {

    raw_text <- pdftools::pdf_text(path_pdf)

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

    unidade_gestao <- raw_text[1] |>
      stringr::str_extract("Gest\u00e3o:\\s*(.+)") |>
      stringr::str_remove("Gest\u00e3o:\\s*") |>
      stringr::str_trim()

    header_data_chr       <- extract_header_date(raw_text[1], "Data(?!\\s*Final)")
    header_data_final_chr <- extract_header_date(raw_text[1], "Data\\s*Final")

    header_data       <- suppressWarnings(lubridate::dmy(header_data_chr))
    header_data_final <- suppressWarnings(lubridate::dmy(header_data_final_chr))

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

    lines <- raw_text |>
      stringr::str_split("\n") |>
      unlist() |>
      stringr::str_subset("^\\d{2}\\s*/\\s*\\d{2}\\s*/\\s*\\d{4}") |>
      stringr::str_squish()

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
            tipo              = "Saldo Inicial",
            codigo_documento  = NA_character_,
            valor_lancamento  = 0,
            dc1               = NA_character_,
            saldo_actual       = saldo_hdr_num,
            dc2               = saldo_hdr_dc,
            saldo_inicial_fim = saldo_hdr_num
          ),
          tibble::tibble(
            unidade_gestao    = unidade_gestao,
            data              = header_data_final,
            tipo              = "Saldo Final",
            codigo_documento  = NA_character_,
            valor_lancamento  = 0,
            dc1               = NA_character_,
            saldo_actual       = saldo_hdr_num,
            dc2               = saldo_hdr_dc,
            saldo_inicial_fim = saldo_hdr_num
          )
        )
      )
    }

    df <- tibble::tibble(raw = lines) |>
      tidyr::separate(
        raw,
        into = c(
          "data",
          "codigo_documento",
          "valor_lancamento",
          "dc1",
          "saldo_actual",
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
        saldo_actual = readr::parse_number(
          saldo_actual,
          locale = readr::locale(decimal_mark = ",", grouping_mark = ".")
        ),

        valor_lancamento = dplyr::if_else(
          dc1 == "C",
          -valor_lancamento,
          valor_lancamento
        ),

        unidade_gestao    = unidade_gestao,
        tipo              = "Movimento",
        saldo_inicial_fim = NA_real_
      ) |>
      dplyr::select(
        unidade_gestao, data, tipo, codigo_documento,
        valor_lancamento, dc1, saldo_actual, dc2, saldo_inicial_fim
      )

    data_inicio        <- if (!is.na(header_data)) header_data else df$data[1]
    saldo_inicial_calc <- df$saldo_actual[1] - df$valor_lancamento[1]

    saldo_inicial_row <- tibble::tibble(
      unidade_gestao    = unidade_gestao,
      data              = data_inicio,
      tipo              = "Saldo Inicial",
      codigo_documento  = NA_character_,
      valor_lancamento  = 0,
      dc1               = NA_character_,
      saldo_actual       = saldo_inicial_calc,
      dc2               = df$dc2[1],
      saldo_inicial_fim = saldo_inicial_calc
    )

    data_fim        <- if (!is.na(header_data_final)) header_data_final else df$data[nrow(df)]
    saldo_final_val <- df$saldo_actual[nrow(df)]

    saldo_final_row <- tibble::tibble(
      unidade_gestao    = unidade_gestao,
      data              = data_fim,
      tipo              = "Saldo Final",
      codigo_documento  = NA_character_,
      valor_lancamento  = 0,
      dc1               = NA_character_,
      saldo_actual       = saldo_final_val,
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
      ano = lubridate::year(data),
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

  # ---- Resumo final ----
  file_rows <- df |>
    dplyr::group_by(source_file) |>
    dplyr::summarise(n_linhas = dplyr::n(), .groups = "drop")

  n_files    <- nrow(file_rows)
  n_total    <- nrow(df)

  file_lines <- file_rows |>
    glue::glue_data("  \u2714 {source_file} \u2014 {n_linhas} linhas") |>
    paste(collapse = "\n")

  message(glue::glue(
    "\n--- processar_extracto_razao_c() ---\n",
    "{n_files} ficheiro(s) encontrado(s)\n",
    "{file_lines}\n",
    "Total linhas output  : {n_total}\n",
    "Ficheiros processados: {n_files}"
  ))

  df

}



#' Processar extractos bancarios ABSA
#'
#' Localiza todos os ficheiros PDF com o padrao \code{"EXTRACTO ABSA"} numa
#' pasta, processa cada um e devolve um unico tibble combinado compativel com o
#' esquema \code{df_razao} utilizado no pipeline do \code{easystafe}.
#'
#' @param source_path \code{character(1)}. Caminho para a pasta que contem os
#'   ficheiros PDF dos extractos ABSA. Obrigatorio.
#' @param pattern \code{character(1)}. Padrao regex usado para identificar os
#'   ficheiros ABSA dentro de \code{source_path}. Nao faz distincao entre
#'   maiusculas e minusculas. Default: \code{"EXTRACTO ABSA"}.
#' @param recursive \code{logical(1)}. Se \code{TRUE}, pesquisa tambem nas
#'   subpastas de \code{source_path}. Default: \code{FALSE}.
#' @param y_tolerance \code{numeric(1)}. Tolerancia vertical (em pontos PDF)
#'   para agrupar palavras na mesma linha durante a reconstrucao por
#'   coordenadas. O valor predefinido de \code{2} funciona para os extractos
#'   ABSA padrao. Default: \code{2}.
#' @param quiet \code{logical(1)}. Se \code{TRUE} (padrao), suprime as
#'   mensagens emitidas por ficheiro durante o processamento. Se \code{FALSE},
#'   e emitida uma mensagem por ficheiro processado. Independentemente deste
#'   parametro, e sempre emitida uma mensagem final com o numero de linhas e
#'   ficheiros processados. Default: \code{TRUE}.
#' @return Um tibble com 12 colunas base do esquema \code{df_razao}. Aplique
#'   \code{\link{adicionar_conversao_moeda}} ao resultado para adicionar as
#'   colunas de conversao de moeda com taxas diarias.
#'   \describe{
#'     \item{source_file}{\code{character}. Nome do ficheiro PDF de origem.}
#'     \item{unidade_gestao}{\code{character}. Sempre \code{NA} -- a preencher
#'       downstream.}
#'     \item{data}{\code{Date}. Data do movimento. A data ficticia de abertura
#'       (\code{01/01/1900}) e remapeada para o primeiro dia do periodo do
#'       extracto.}
#'     \item{ano}{\code{integer}. Ano extraido de \code{data}.}
#'     \item{mes}{\code{character}. Nome completo do mes em portugues (ex:
#'       \code{"Fevereiro"}).}
#'     \item{tipo}{\code{character}. Um de \code{"Saldo Inicial"},
#'       \code{"Moviemento"} ou \code{"Saldo Final"}.}
#'     \item{codigo_documento}{\code{character}. Numero de referencia do
#'       movimento, quando presente. \code{NA} caso contrario.}
#'     \item{valor_lancamento}{\code{double}. Valor assinado do movimento:
#'       positivo para creditos, negativo para debitos. \code{NA} nas linhas
#'       de saldo.}
#'     \item{valor_lancamento_mt}{\code{double}. Valor do lancamento em MZN.}
#'     \item{valor_lancamento_usd}{\code{double}. Valor do lancamento em USD.}
#'     \item{valor_lancamento_eur}{\code{double}. Valor do lancamento em EUR.}
#'     \item{dc1}{\code{character}. Indicador debito/credito do movimento:
#'       \code{"C"}, \code{"D"} ou \code{NA}.}
#'     \item{saldo_actual}{\code{double}. Saldo corrente apos o movimento.}
#'     \item{dc2}{\code{character}. Indicador debito/credito do saldo. Sempre
#'       \code{"D"} para este tipo de conta.}
#'     \item{saldo_inicial_fim}{\code{double}. Saldo de abertura em
#'       \code{Saldo Inicial}; saldo calculado em \code{Saldo Final};
#'       \code{NA} nos movimentos.}
#'     \item{saldo_inicial_fim_mt}{\code{double}. Saldo inicial ou final
#'       em MZN.}
#'     \item{saldo_inicial_fim_usd}{\code{double}. Saldo inicial ou final
#'       em USD.}
#'     \item{saldo_inicial_fim_eur}{\code{double}. Saldo inicial ou final
#'       em EUR.}
#'   }
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
#' A linha de fecho (\code{Saldo Final}) e acrescentada programaticamente e
#' nao extraida do rodape do PDF. O seu \code{saldo_inicial_fim} e calculado
#' como \code{saldo_abertura + sum(creditos) - sum(debitos)}.
#'
#' O helper interno \code{parse_single_absa()} e definido dentro desta funcao
#' e nao e exportado.
#'
#' @examples
#' \dontrun{
#' # Processar todos os extractos ABSA numa pasta
#' df_absa <- processar_extracto_absa(
#'   source_path = "Data/razao_cont/2026_02/outro/"
#' )
#'
#' # Combinar com outros extractos do razao
#' df_razao <- dplyr::bind_rows(df_razao, df_absa)
#'
#' # Pesquisar em subpastas com padrao alternativo
#' df_absa <- processar_extracto_absa(
#'   source_path = "Data/razao_cont/",
#'   pattern     = "ABSA",
#'   recursive   = TRUE
#' )
#' }
#'
#' @seealso \code{\link{adicionar_conversao_moeda}},
#'   \code{\link{processar_extracto_razao_c}}
#'
#' @importFrom pdftools pdf_data
#' @importFrom dplyr mutate case_when arrange group_by summarise bind_rows select first
#' @importFrom purrr map map_dfr discard set_names list_rbind
#' @importFrom stringr str_trim str_detect str_extract str_extract_all str_remove str_remove_all str_subset regex
#' @importFrom lubridate dmy year month floor_date ceiling_date days
#' @importFrom tibble tibble
#'
#' @export

processar_extracto_absa <- function(source_path,
                                    pattern     = "EXTRACTO ABSA",
                                    recursive   = FALSE,
                                    y_tolerance = 2,
                                    quiet       = TRUE) {

  # ---- Helper interno: processar um unico PDF ABSA -------------------------
  parse_single_absa <- function(pdf_path) {

    source_file_name <- basename(pdf_path)

    reconstruct_lines <- function(page_data) {
      page_data |>
        dplyr::mutate(y_group = round(y / y_tolerance) * y_tolerance) |>
        dplyr::arrange(y_group, x) |>
        dplyr::group_by(y_group) |>
        dplyr::summarise(line = paste(text, collapse = " "), .groups = "drop") |>
        dplyr::arrange(y_group) |>
        dplyr::pull(line)
    }

    lines <- pdftools::pdf_data(pdf_path) |>
      purrr::map(reconstruct_lines) |>
      unlist() |>
      stringr::str_trim() |>
      purrr::discard(~ .x == "")

    account_number <- lines |>
      stringr::str_subset("Nr da Conta") |>
      stringr::str_extract("\\d{10,}") |>
      dplyr::first() %||% NA_character_

    client_name <- lines |>
      stringr::str_subset("Nome da Cliente") |>
      stringr::str_remove(".*Nome da Cliente\\s*:?\\s*") |>
      stringr::str_trim() |>
      dplyr::first() %||% NA_character_

    currency <- lines |>
      stringr::str_subset("Nome da Moeda") |>
      stringr::str_extract("MZN|USD|EUR") |>
      dplyr::first() %||% "MZN"

    saldo_abertura <- lines |>
      stringr::str_subset("Saldo de Abertura") |>
      stringr::str_extract("[\\d,]+\\.\\d{2}") |>
      stringr::str_remove_all(",") |>
      as.numeric() |>
      dplyr::first() %||% NA_real_

    all_period_dates <- lines |>
      stringr::str_subset("^Per|^Para\\s*:") |>
      stringr::str_extract_all("\\d{2}/\\d{2}/\\d{4}") |>
      unlist() |>
      lubridate::dmy()

    periodo_inicio <- if (length(all_period_dates) >= 1) min(all_period_dates) else NA
    periodo_fim    <- if (length(all_period_dates) >= 1) max(all_period_dates) else NA

    date_pattern <- "^\\d{2}/\\d{2}/\\d{4}\\s+\\d+"
    num_pat      <- "[\\d,]+\\.\\d{2}"

    noise_pattern <- paste(c(
      "^Extracto de Conta", "^Nome do Balcao", "^Per.*De", "^Para\\s*:",
      "^Nr da P", "^Nr da Conta", "^NIB No", "^Nome do Produto",
      "^Nome da Moeda", "^C.*d do Bal", "^Nome Abreviado",
      "^Nr de Identifica", "^Nome da Cliente", "^Endere",
      "^T.*tulo da Conta", "^Data Bal", "^Saldo de Abertura",
      "^Valor Total", "^Nr de D", "^Nr de Cr", "^Saldo de Encer",
      "^Valor da Comissao", "^\\*", "^-{3,}", "^%%", "^NR\\s+\\d+",
      "^CIDADE DE", "^Maputo", "^AV\\s+", "Fim do Extracto",
      "^Rel Pty", "^Large Corporate"
    ), collapse = "|")

    tx_lines_raw <- lines |>
      purrr::discard(~ stringr::str_detect(.x, noise_pattern))

    joined_lines <- character(0)
    for (line in tx_lines_raw) {
      if (stringr::str_detect(line, date_pattern)) {
        joined_lines <- c(joined_lines, line)
      } else if (length(joined_lines) > 0) {
        joined_lines[length(joined_lines)] <-
          paste(joined_lines[length(joined_lines)], line)
      }
    }

    transactions <- joined_lines |>
      purrr::map_dfr(function(line) {

        data_str   <- stringr::str_extract(line, "^\\d{2}/\\d{2}/\\d{4}")
        referencia <- stringr::str_extract(line, "\\d{12,}") %||% NA_character_

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

    transactions <- transactions |>
      dplyr::mutate(
        data = lubridate::dmy(data_str),
        data = dplyr::if_else(
          data == as.Date("1900-01-01"),
          periodo_inicio %||% lubridate::floor_date(
            min(lubridate::dmy(data_str), na.rm = TRUE), "month"
          ),
          data
        )
      )

    transactions <- transactions |>
      dplyr::mutate(
        tipo = dplyr::case_when(
          stringr::str_detect(
            descricao,
            stringr::regex("SALDO DE ABERTURA", ignore_case = TRUE)
          ) ~ "Saldo Inicial",
          TRUE ~ "Movimento"
        )
      )

    mes_labels <- c(
      "Janeiro", "Fevereiro", "Marco", "Abril", "Maio", "Junho",
      "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
    )

    df_movimentos <- transactions |>
      dplyr::mutate(
        source_file       = source_file_name,
        unidade_gestao    = NA_character_,
        ano               = lubridate::year(data),
        mes               = mes_labels[lubridate::month(data)],
        valor_lancamento  = dplyr::case_when(
          tipo == "Saldo Inicial" ~ NA_real_,
          credito > 0             ~ credito,
          TRUE                    ~ -debito
        ),
        dc1 = dplyr::case_when(
          tipo == "Saldo Inicial" ~ NA_character_,
          credito > 0             ~ "C",
          debito  > 0             ~ "D",
          TRUE                    ~ NA_character_
        ),
        dc2               = "D",
        codigo_documento  = referencia,
        saldo_actual       = saldo,
        saldo_inicial_fim = dplyr::case_when(
          tipo == "Saldo Inicial" ~ saldo_abertura,
          TRUE                    ~ NA_real_
        )
      ) |>
      dplyr::select(
        source_file, unidade_gestao, data, ano, mes, tipo,
        codigo_documento, valor_lancamento, dc1,
        saldo_actual, dc2, saldo_inicial_fim
      )

    total_cred_mov <- sum(df_movimentos$valor_lancamento[
      df_movimentos$tipo == "Movimento" &
        !is.na(df_movimentos$valor_lancamento) &
        df_movimentos$valor_lancamento > 0
    ])

    total_deb_mov <- abs(sum(df_movimentos$valor_lancamento[
      df_movimentos$tipo == "Movimento" &
        !is.na(df_movimentos$valor_lancamento) &
        df_movimentos$valor_lancamento < 0
    ]))

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
      mes               = mes_labels[lubridate::month(data_saldo_final)],
      tipo              = "Saldo Final",
      codigo_documento  = NA_character_,
      valor_lancamento  = NA_real_,
      dc1               = NA_character_,
      saldo_actual       = saldo_final_calc,
      dc2               = "D",
      saldo_inicial_fim = saldo_final_calc
    )

    df_out <- dplyr::bind_rows(df_movimentos, df_saldo_final) |>
      dplyr::arrange(data, desc(tipo == "Saldo Inicial"), tipo == "Saldo Final")

    if (!quiet) {
      message(sprintf("  \u2714 %s \u2014 %d linhas", source_file_name, nrow(df_out)))
    }

    df_out
  }

  # ---- Validacao de argumentos ----
  stopifnot(
    "source_path must be a single character string" =
      is.character(source_path) && length(source_path) == 1,
    "y_tolerance must be a positive number" =
      is.numeric(y_tolerance) && y_tolerance > 0,
    "quiet must be TRUE or FALSE" =
      is.logical(quiet) && length(quiet) == 1,
    "recursive must be TRUE or FALSE" =
      is.logical(recursive) && length(recursive) == 1
  )
  if (!dir.exists(source_path)) stop("Pasta n\u00e3o encontrada: ", source_path)

  # ---- Listar ficheiros PDF ----
  pdf_files <- list.files(
    path        = source_path,
    pattern     = pattern,
    full.names  = TRUE,
    recursive   = recursive,
    ignore.case = TRUE
  )
  if (length(pdf_files) == 0) {
    stop(
      "Nenhum ficheiro PDF correspondente ao padr\u00e3o '", pattern,
      "' encontrado em: ", source_path
    )
  }

  if (!quiet) {
    message(sprintf(
      "--- processar_extracto_absa() --- %d ficheiro(s) encontrado(s)",
      length(pdf_files)
    ))
  }

  # ---- Processar PDFs ----
  df_out <- pdf_files |>
    purrr::set_names(basename) |>
    purrr::map(\(f) parse_single_absa(f)) |>
    purrr::list_rbind()

  message(sprintf("Total linhas output  : %d", nrow(df_out)))
  message(sprintf("Ficheiros processados: %d", length(pdf_files)))

  df_out
}
