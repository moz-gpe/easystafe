#' Processamento hierárquico e consolidação de um único extracto do e-SISTAFE
#'
#' Esta função processa um ficheiro individual do e-SISTAFE, executando
#' um conjunto estruturado de operações para produzir um extracto
#' totalmente consolidado e não duplicado a partir dos diferentes níveis
#' hierárquicos de CED (A, B, C e D).
#'
#' O processamento inclui:
#' * limpeza e normalização do extracto original;
#' * classificação do grupo CED para cada linha (A, B, C, D);
#' * aplicação de regras de subtração hierárquica entre níveis:
#'   - C → D
#'   - B → D
#'   - A → D
#'   - B → C
#'   - A → C
#'   - A → B
#' * atribuição de prioridade (D > C > B > A) e seleção do valor final;
#' * devolução de um extracto “único” representando o nível mais granular disponível.
#'
#' @param caminho Caminho completo do ficheiro Excel a ser processado.
#' @param lista_ugb Vetor de códigos UGB a manter (os restantes são marcados como "Remove").
#'
#' @return Um tibble contendo o extracto processado e consolidado para um único ficheiro,
#' sem duplicações e com o nível hierárquico final escolhido automaticamente.
#'
#' @examples
#' \dontrun{
#' df <- processar_esistafe_extracto_unico(
#'   caminho = "Data/Extracto_20240201.xlsx",
#'   lista_ugb = c("010100001")
#' )
#' }
#'
#' @export

processar_esistafe_extracto_unico <- function(caminho, lista_ugb) {

  # ============================================================
  # --------------- LOAD & PREPARE SOURCE DATA -----------------
  # ============================================================

  df <- readxl::read_excel(caminho, col_type = "text") %>%
    janitor::clean_names() %>%
    dplyr::select(!dplyr::ends_with("percent")) %>%
    dplyr::mutate(
      dplyr::across(dotacao_inicial:liq_ad_fundos_via_directa_lafvd, as.numeric),
      ugb_id = substr(ugb, 1, 9),
      ced_base_5 = stringr::str_sub(ced, 1, 5),
      id_row_ced_5d = stringr::str_c(ugb, funcao, programa, fr, ced_base_5, sep = "_"),
      ced_base_4 = stringr::str_sub(ced, 1, 4),
      id_row_ced_4d = stringr::str_c(ugb, funcao, programa, fr, ced_base_4, sep = "_"),
      ced_base_3 = stringr::str_sub(ced, 1, 3),
      id_row_ced_3d = stringr::str_c(ugb, funcao, programa, fr, ced_base_3, sep = "_"),
      ced_base_2 = stringr::str_sub(ced, 1, 2),
      id_row_ced_2d = stringr::str_c(ugb, funcao, programa, fr, ced_base_2, sep = "_")
    ) %>%
    dplyr::mutate(
      mec_ugb_class  = ifelse(ugb_id %in% lista_ugb, "Keep", "Remove"),
      ced_blank_class = ifelse(!is.na(ced), "Keep", "Remove"),
      ced_group = dplyr::case_when(
        !stringr::str_ends(ced, "00")                                           ~ "A",
        stringr::str_ends(ced, "00") & !stringr::str_ends(ced, "000") & !stringr::str_ends(ced, "0000") ~ "B",
        stringr::str_ends(ced, "000") & !stringr::str_ends(ced, "0000")        ~ "C",
        stringr::str_ends(ced, "0000")                                         ~ "D",
        TRUE                                                                   ~ NA_character_
      )
    ) %>%
    dplyr::relocate(ugb_id, .before = tidyselect::everything())

  num_cols <- df %>% dplyr::select(where(is.numeric)) %>% names()

  # ============================================================
  # ------------------------ D LEVEL ----------------------------
  # ============================================================

  df_dc_has_c <- df %>%
    dplyr::group_by(id_row_ced_2d) %>%
    dplyr::summarise(has_C = any(ced_group == "C"), .groups = "drop")

  vec_dc_keep_c <- df_dc_has_c %>% dplyr::filter(has_C) %>% dplyr::pull(id_row_ced_2d)

  df_dc <- df %>%
    dplyr::filter(id_row_ced_2d %in% vec_dc_keep_c, ced_group %in% c("C", "D")) %>%
    dplyr::group_by(id_row_ced_3d) %>%
    dplyr::mutate(is_parent = stringr::str_ends(ced, "0000")) %>%
    dplyr::group_by(id_row_ced_2d) %>%
    dplyr::mutate(
      dplyr::across(
        tidyselect::all_of(num_cols),
        ~ ifelse(is_parent, .x - sum(.x[!is_parent], na.rm = TRUE), .x)
      )
    ) %>%
    dplyr::ungroup()

  # -------------------- D fallback via B ------------------------

  vec_dc_no_c <- df_dc_has_c %>% dplyr::filter(!has_C) %>% dplyr::pull(id_row_ced_2d)

  df_db_has_b <- df %>%
    dplyr::filter(id_row_ced_2d %in% vec_dc_no_c) %>%
    dplyr::group_by(id_row_ced_2d) %>%
    dplyr::summarise(has_B = any(ced_group == "B"), .groups = "drop")

  vec_db_keep_b <- df_db_has_b %>% dplyr::filter(has_B) %>% dplyr::pull(id_row_ced_2d)

  df_db <- df %>%
    dplyr::filter(id_row_ced_2d %in% vec_db_keep_b, ced_group %in% c("B", "D")) %>%
    dplyr::group_by(id_row_ced_3d) %>%
    dplyr::mutate(is_parent = stringr::str_ends(ced, "0000")) %>%
    dplyr::group_by(id_row_ced_2d) %>%
    dplyr::mutate(
      dplyr::across(
        tidyselect::all_of(num_cols),
        ~ ifelse(is_parent, .x - sum(.x[!is_parent], na.rm = TRUE), .x)
      )
    ) %>%
    dplyr::ungroup()

  # -------------------- D fallback via A ------------------------

  vec_db_no_b <- df_db_has_b %>% dplyr::filter(!has_B) %>% dplyr::pull(id_row_ced_2d)

  df_da_has_a <- df %>%
    dplyr::filter(id_row_ced_2d %in% vec_db_no_b) %>%
    dplyr::group_by(id_row_ced_2d) %>%
    dplyr::summarise(has_A = any(ced_group == "A"), .groups = "drop")

  vec_da_keep_a <- df_da_has_a %>% dplyr::filter(has_A) %>% dplyr::pull(id_row_ced_2d)

  df_da <- df %>%
    dplyr::filter(id_row_ced_2d %in% vec_da_keep_a, ced_group %in% c("A", "D")) %>%
    dplyr::group_by(id_row_ced_3d) %>%
    dplyr::mutate(is_parent = stringr::str_ends(ced, "0000")) %>%
    dplyr::group_by(id_row_ced_2d) %>%
    dplyr::mutate(
      dplyr::across(
        tidyselect::all_of(num_cols),
        ~ ifelse(is_parent, .x - sum(.x[!is_parent], na.rm = TRUE), .x)
      )
    ) %>%
    dplyr::ungroup()

  df_d_final <- dplyr::bind_rows(df_dc, df_db, df_da)

  # ============================================================
  # ------------------------ C LEVEL ----------------------------
  # ============================================================

  df_cb_has_b <- df %>%
    dplyr::group_by(id_row_ced_3d) %>%
    dplyr::summarise(has_B = any(ced_group == "B"), .groups = "drop")

  vec_cb_keep_b <- df_cb_has_b %>% dplyr::filter(has_B) %>% dplyr::pull(id_row_ced_3d)

  df_cb <- df %>%
    dplyr::filter(id_row_ced_3d %in% vec_cb_keep_b, ced_group %in% c("B", "C")) %>%
    dplyr::group_by(id_row_ced_4d) %>%
    dplyr::mutate(is_parent = stringr::str_ends(ced, "000")) %>%
    dplyr::group_by(id_row_ced_3d) %>%
    dplyr::mutate(
      dplyr::across(
        tidyselect::all_of(num_cols),
        ~ ifelse(is_parent, .x - sum(.x[!is_parent], na.rm = TRUE), .x)
      )
    ) %>%
    dplyr::ungroup()

  # -------------------- C fallback via A ------------------------

  vec_cb_no_b <- df_cb_has_b %>% dplyr::filter(!has_B) %>% dplyr::pull(id_row_ced_3d)

  df_ca_has_a <- df %>%
    dplyr::filter(id_row_ced_3d %in% vec_cb_no_b) %>%
    dplyr::group_by(id_row_ced_3d) %>%
    dplyr::summarise(has_A = any(ced_group == "A"), .groups = "drop")

  vec_ca_keep_a <- df_ca_has_a %>% dplyr::filter(has_A) %>% dplyr::pull(id_row_ced_3d)

  df_ca <- df %>%
    dplyr::filter(id_row_ced_3d %in% vec_ca_keep_a, ced_group %in% c("A", "C")) %>%
    dplyr::group_by(id_row_ced_4d) %>%
    dplyr::mutate(is_parent = stringr::str_ends(ced, "0000")) %>%
    dplyr::group_by(id_row_ced_3d) %>%
    dplyr::mutate(
      dplyr::across(
        tidyselect::all_of(num_cols),
        ~ ifelse(is_parent, .x - sum(.x[!is_parent], na.rm = TRUE), .x)
      )
    ) %>%
    dplyr::ungroup()

  df_c_final <- dplyr::bind_rows(df_cb, df_ca)

  # ============================================================
  # ------------------------ B LEVEL ----------------------------
  # ============================================================

  df_ba_has_a <- df %>%
    dplyr::group_by(id_row_ced_4d) %>%
    dplyr::summarise(has_A = any(ced_group == "A"), .groups = "drop")

  vec_ba_keep_a <- df_ba_has_a %>% dplyr::filter(has_A) %>% dplyr::pull(id_row_ced_4d)

  df_b_final <- df %>%
    dplyr::filter(id_row_ced_4d %in% vec_ba_keep_a, ced_group %in% c("A", "B")) %>%
    dplyr::group_by(id_row_ced_5d) %>%
    dplyr::mutate(is_parent = stringr::str_ends(ced, "00")) %>%
    dplyr::group_by(id_row_ced_4d) %>%
    dplyr::mutate(
      dplyr::across(
        tidyselect::all_of(num_cols),
        ~ ifelse(is_parent, .x - sum(.x[!is_parent], na.rm = TRUE), .x)
      )
    ) %>%
    dplyr::ungroup()

  # ============================================================
  # ------------------------ A LEVEL ----------------------------
  # ============================================================

  df_a_final <- df %>%
    dplyr::filter(ced_group == "A") %>%
    dplyr::mutate(is_parent = NA)

  # ============================================================
  # ------------------------ PRIORITIZE --------------------------
  # ============================================================

  df_d_final <- df_d_final %>% dplyr::mutate(level_priority = 4)
  df_c_final <- df_c_final %>% dplyr::mutate(level_priority = 3)
  df_b_final <- df_b_final %>% dplyr::mutate(level_priority = 2)
  df_a_final <- df_a_final %>% dplyr::mutate(level_priority = 1)

  # ============================================================
  # ------------------------- FINALIZE ---------------------------
  # ============================================================

  df_final <- dplyr::bind_rows(df_d_final, df_c_final, df_b_final, df_a_final) %>%
    dplyr::arrange(id_row_ced_5d, level_priority) %>%
    dplyr::distinct(id_row_ced_5d, .keep_all = TRUE) %>%
    dplyr::select(-level_priority)

  return(df_final)
}
