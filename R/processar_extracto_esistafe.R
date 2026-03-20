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
#' @param ugb_lookup Um dataframe com a tabela de referencia de UGBs de
#'   educacao, carregado a partir do ficheiro Excel de codigos UGB (folha
#'   \code{"UGBS"}). Deve conter uma coluna \code{ugb_3} com os nomes
#'   completos dos UGBs validos.
#' @param include_percent Logico. Se \code{TRUE} (padrao), as colunas
#'   \code{percent} sao incluidas no output (preenchidas com \code{NA}).
#'   Se \code{FALSE}, essas colunas sao removidas do resultado final.
#' @param include_meta Logico. Se \code{TRUE} (padrao), os metadados
#'   extraidos do nome do ficheiro (tipo de relatorio, ano, mes, datas) sao
#'   adicionados ao dataframe imediatamente apos a coluna \code{file_name}.
#'   Se \code{FALSE}, os metadados nao sao adicionados e a coluna
#'   \code{file_name} e tambem removida do resultado final.
#' @param quiet Logico. Se \code{TRUE} (padrao), as mensagens de progresso
#'   sao suprimidas. Se \code{FALSE}, e emitida uma mensagem por cada etapa
#'   do processamento. Independentemente deste parametro, e sempre emitida
#'   uma mensagem final com o numero de ficheiros processados.
#'
#' @return Um tibble com uma linha por entrada CED deduplificada, contendo
#'   as colunas originais do extracto e-SISTAFE apos limpeza e subtraccao
#'   hierarquica. As colunas de percentagem sao sempre incluidas na estrutura
#'   original (preenchidas com \code{NA}) salvo se \code{include_percent = FALSE}.
#'
#' @details
#' O processamento segue as seguintes etapas principais:
#' \enumerate{
#'   \item Carregamento e combinacao de todos os ficheiros em \code{source_path}.
#'   \item Adicao opcional de metadados via \code{extrair_meta_extracto()}.
#'   \item Limpeza de nomes de colunas com \code{janitor::clean_names()}.
#'   \item Remocao de colunas \code{percent}.
#'   \item Conversao de colunas numericas e extraccao do codigo \code{ugb_id}.
#'   \item Filtragem de UGBs validos de educacao a partir de \code{ugb_lookup}.
#'   \item Remocao de linhas com CED e campos-chave em branco.
#'   \item Classificacao de grupos CED (A, B, C, D) e remocao do grupo D.
#'   \item Criacao de variaveis hierarquicas auxiliares.
#'   \item Subtraccao hierarquica em tres passos para eliminar dupla contagem:
#'     \itemize{
#'       \item Passo 1: Subtrair grupo A do grupo B (dentro de \code{ced_b4}).
#'       \item Passo 2: Subtrair grupo B ajustado do grupo C (dentro de \code{ced_b3}).
#'       \item Passo 3: Subtrair grupo A directamente do grupo C (dentro de \code{ced_b3}).
#'     }
#'   \item Restauracao da estrutura original de colunas.
#' }
#'
#' @examples
#' \dontrun{
#' ugb_raw    <- readxl::read_excel("Data/ugb/Codigos de UGBs.xlsx", sheet = "UGBS")
#' path_files <- list.files("Data/", pattern = "\\.xlsx$", full.names = TRUE)
#'
#' # Padrao -- com metadados e colunas percent
#' df <- processar_extracto_sistafe(
#'   source_path = path_files,
#'   ugb_lookup  = ugb_raw
#' )
#'
#' # Sem metadados, sem colunas percent
#' df <- processar_extracto_sistafe(
#'   source_path     = path_files,
#'   ugb_lookup      = ugb_raw,
#'   include_percent = FALSE,
#'   include_meta    = FALSE
#' )
#'
#' # Com mensagens de progresso
#' df <- processar_extracto_sistafe(
#'   source_path = path_files,
#'   ugb_lookup  = ugb_raw,
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
    ugb_lookup,
    include_percent = TRUE,
    include_meta    = TRUE,
    quiet           = TRUE
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
  if (include_meta) {
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

  # --- 5. Extrair código UGB ---
  msg("A extrair c\u00f3digo UGB...")

  df_limpeza_3 <- df_limpeza_2 |>
    dplyr::mutate(
      dplyr::across(dotacao_inicial:liq_ad_fundos_via_directa_lafvd, as.numeric),
      ugb_id = base::substr(ugb, 1, 9)
    ) |>
    dplyr::relocate(ugb_id, .after = ugb)

  # --- 6. Filtrar UGBs de educação ---
  msg("A filtrar UGBs de educa\u00e7\u00e3o...")

  vec_ugb <- ugb_lookup |>
    janitor::clean_names() |>
    dplyr::select(ugb_nome = ugb_3) |>
    dplyr::distinct(ugb_nome) |>
    dplyr::pull()

  df_limpeza_4 <- df_limpeza_3 |>
    dplyr::mutate(mec_ugb_class = base::ifelse(ugb %in% vec_ugb, "Keep", "Remove")) |>
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
        !stringr::str_ends(ced, "00")                                                  ~ "A",
        stringr::str_ends(ced, "00") & !stringr::str_ends(ced, "000") & !stringr::str_ends(ced, "0000") ~ "B",
        stringr::str_ends(ced, "000") & !stringr::str_ends(ced, "0000")               ~ "C",
        stringr::str_ends(ced, "0000")                                                 ~ "D",
        TRUE                                                                            ~ NA_character_
      )
    ) |>
    dplyr::filter(base::is.na(ced_group) | ced_group != "D")

  # --- 9. Criar variáveis hierárquicas ---
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

  # --- 10. Definir colunas numéricas ---
  num_cols <- df_limpeza_7 |>
    dplyr::select(dotacao_inicial:liq_ad_fundos_via_directa_lafvd) |>
    base::names()

  # --- 11. Subtração hierárquica: Passo 1 (A -> B dentro de ced_b4) ---
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

  # --- 12. Subtração hierárquica: Passo 2 (B ajustado -> C dentro de ced_b3) ---
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

  # --- 13. Subtração hierárquica: Passo 3 (A directo -> C dentro de ced_b3) ---
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

  # --- 14. Seleccionar colunas finais e restaurar estrutura original ---
  msg("A finalizar estrutura do dataset...")

  df_limpeza_final <- df_limpeza_9 |>
    dplyr::select(dplyr::any_of(base::names(df_limpeza_1))) |>
    dplyr::mutate(
      dc_da_percent   = NA_real_,
      afdp_da_percent = NA_real_,
      laf_af_percent  = NA_real_
    ) |>
    dplyr::select(dplyr::all_of(base::names(df_limpeza_1)))

  # --- 15. Incluir ou excluir colunas percent ---
  if (!include_percent) {
    df_limpeza_final <- df_limpeza_final |>
      dplyr::select(!dplyr::ends_with("percent"))
  }

  # --- 16. Remover file_name se metadados não incluidos ---
  if (!include_meta) {
    df_limpeza_final <- df_limpeza_final |>
      dplyr::select(-file_name)
  }

  msg("Conclu\u00eddo.")

  # --- Resumo final ---
  n_files <- dplyr::n_distinct(df$file_name)
  message(glue::glue("Processamento conclu\u00eddo: {n_files} ficheiro(s) processado(s) com sucesso."))

  return(df_limpeza_final)

}

