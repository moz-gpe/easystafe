#' Recodificar variaveis padrao de exportacoes e-SISTAFE
#'
#' @description
#' A wrapper function that detects the presence of known e-SISTAFE columns and
#' applies standard recoding transformations to each one found. Columns not
#' present in the dataframe are silently skipped.
#'
#' Currently handles:
#' \itemize{
#'   \item \code{distrito}: applies title case with lowercase prepositions (de, da, do, dos, das)
#' }
#'
#' @param df A dataframe containing one or more standard e-SISTAFE columns.
#'
#' @return The input dataframe with transformations applied to detected columns.
#'
#' @examples
#' \dontrun{
#'   df_clean <- df |>
#'     dplyr::left_join(ugb_lookup, by = dplyr::join_by(ugb_id == codigo_ugb)) |>
#'     recodificar_esistafe_vars()
#' }
#'
#' @importFrom dplyr mutate
#' @importFrom stringr str_to_title str_replace_all
#'
#' @export

recodificar_esistafe_vars <- function(df) {

  # distrito: title case with lowercase prepositions
  if ("distrito" %in% names(df)) {
    df <- df %>%
      dplyr::mutate(
        distrito = distrito %>%
          stringr::str_to_title() %>%
          stringr::str_replace_all("\\b(De|Da|Do|Dos|Das)\\b", ~ stringr::str_to_lower(.x))
      )
  }

  df
}
