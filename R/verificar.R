#' Verificar completude de UGBs no extracto e-SISTAFE
#'
#' Compara a lista de UGBs de educacao de um dataframe de referencia com os
#' dados processados do e-SISTAFE, verificando se cada UGB possui valores
#' registados para as variaveis financeiras chave. Os resultados sao emitidos
#' como mensagens no console.
#'
#' @param df_esistafe A dataframe of processed e-SISTAFE data, as returned by
#'   \code{processar_extracto_esistafe()}. Must contain at least the columns
#'   \code{ugb_id}, \code{reporte_tipo}, \code{dotacao_actualizada_da}, and
#'   \code{ad_fundos_desp_paga_vd_afdp}.
#' @param lookup_ugb A dataframe with the education UGB reference table. Must
#'   contain at least the column \code{codigo_ugb} with 9-character UGB codes
#'   (e.g. \code{"50B105761"}).
#' @param quiet Logical. If \code{TRUE} (default), the completude summary
#'   message is suppressed. If \code{FALSE}, a message is emitted to the
#'   console listing total UGBs and any missing values for each financial
#'   variable.
#'
#' @return Invisibly returns \code{NULL}. Called for its side effect of
#'   printing a completude summary message to the console.
#'
#' @details
#' The function filters \code{df_esistafe} to \code{reporte_tipo == "Funcionamento"}
#' and checks two financial variables for each UGB in \code{lookup_ugb}:
#' \itemize{
#'   \item \code{dotacao_actualizada_da}: dotacao actualizada (DA).
#'   \item \code{ad_fundos_desp_paga_vd_afdp}: despesa paga via directa e
#'     atraves de adiantamento de fundos (AFDP).
#' }
#' A UGB is considered complete for a given variable if at least one row
#' exists with a non-missing value greater than zero. UGBs failing either
#' check are listed by code in the console message.
#'
#' @examples
#' \dontrun{
#' ugb_lookup <- readxl::read_excel("Data/ugb/Codigos de UGBs.xlsx", sheet = "UGBS")
#'
#' df <- processar_extracto_esistafe(
#'   source_path   = "Data/",
#'   df_ugb_lookup = ugb_lookup
#' )
#'
#' # Com mensagem de completude
#' verificar_ugb_completude(df, ugb_lookup, quiet = FALSE)
#' }
#'
#' @importFrom dplyr mutate left_join filter distinct pull
#' @importFrom tidyr replace_na
#'
#' @export

verificar_ugb_completude <- function(df_esistafe, lookup_ugb, quiet = TRUE) {

  ugb_check <- lookup_ugb |>
    dplyr::mutate(codigo_ugb = as.character(codigo_ugb)) |>
    dplyr::left_join(
      df_esistafe |>
        dplyr::filter(
          reporte_tipo == "Funcionamento",
          !is.na(dotacao_actualizada_da),
          dotacao_actualizada_da > 0
        ) |>
        dplyr::distinct(ugb_id) |>
        dplyr::mutate(has_dotacao = TRUE),
      by = c("codigo_ugb" = "ugb_id")
    ) |>
    dplyr::left_join(
      df_esistafe |>
        dplyr::filter(
          reporte_tipo == "Funcionamento",
          !is.na(ad_fundos_desp_paga_vd_afdp),
          ad_fundos_desp_paga_vd_afdp > 0
        ) |>
        dplyr::distinct(ugb_id) |>
        dplyr::mutate(has_afdp = TRUE),
      by = c("codigo_ugb" = "ugb_id")
    ) |>
    dplyr::mutate(
      has_dotacao = tidyr::replace_na(has_dotacao, FALSE),
      has_afdp    = tidyr::replace_na(has_afdp, FALSE)
    )

  if (!quiet) {
    missing_dotacao <- ugb_check |> dplyr::filter(!has_dotacao) |> dplyr::pull(codigo_ugb)
    missing_afdp    <- ugb_check |> dplyr::filter(!has_afdp)    |> dplyr::pull(codigo_ugb)

    message(
      "\nA verificar a completude de UGBs (Funcionamento)",
      "\n Total UGB's no lookup:                ", nrow(ugb_check),
      "\n UGB's sem dotacao_actualizada_da:     ", length(missing_dotacao),
      "\n   ", paste(missing_dotacao, collapse = "\n   "),
      "\n UGB's sem ad_fundos_desp_paga_vd_afdp: ", length(missing_afdp),
      "\n   ", paste(missing_afdp, collapse = "\n   "),
      "\n---------------------------------------------------------"
    )
  }

  invisible(NULL)

}
