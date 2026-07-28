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

  ugb_check <- .calcular_ugb_completude(df_esistafe, lookup_ugb)

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


#' Detalhe de UGBs incompletas por periodo
#'
#' Devolve um tibble com as UGBs de educacao que, em cada periodo, nao possuem
#' registos de Funcionamento com valor > 0 em pelo menos uma das variaveis
#' financeiras chave (\code{dotacao_actualizada_da} e
#' \code{ad_fundos_desp_paga_vd_afdp}). Complementa
#' \code{\link{resumir_processamento_esistafe}}, cuja tabela-resumo mostra apenas
#' as contagens; esta funcao expoe os codigos concretos, que de outra forma
#' seriam truncados na consola.
#'
#' @param df O dataframe combinado do processamento e-SISTAFE. Deve conter as
#'   colunas \code{periodo}, \code{reporte_tipo}, \code{ugb_id},
#'   \code{dotacao_actualizada_da} e \code{ad_fundos_desp_paga_vd_afdp}.
#' @param lookup_ugb Dataframe com a tabela de referencia das UGBs de educacao
#'   (coluna \code{codigo_ugb}).
#'
#' @return Um tibble com uma linha por combinacao \code{periodo} x
#'   \code{codigo_ugb} que tem pelo menos uma lacuna, com as colunas logicas
#'   \code{sem_dotacao} e \code{sem_afdp}.
#'
#' @examples
#' \dontrun{
#' ugb_incompletas_esistafe(df_esistafe, lookups$ugb)
#' }
#'
#' @importFrom dplyr mutate filter arrange transmute
#'
#' @seealso \code{\link{resumir_processamento_esistafe}},
#'   \code{\link{verificar_ugb_completude}}
#' @export
ugb_incompletas_esistafe <- function(df, lookup_ugb) {
  .calcular_ugb_completude(df, lookup_ugb, por_periodo = TRUE) |>
    dplyr::transmute(
      periodo,
      codigo_ugb,
      sem_dotacao = !has_dotacao,
      sem_afdp    = !has_afdp
    ) |>
    dplyr::filter(sem_dotacao | sem_afdp) |>
    dplyr::arrange(periodo, codigo_ugb)
}


#' Calcular completude de UGBs (helper interno)
#'
#' Determina, para cada UGB do lookup, se possui pelo menos um registo de
#' Funcionamento com valor > 0 nas variaveis \code{dotacao_actualizada_da} e
#' \code{ad_fundos_desp_paga_vd_afdp}. Suporta calculo global ou por periodo.
#'
#' @param df_esistafe Dataframe processado do e-SISTAFE.
#' @param lookup_ugb Dataframe com a coluna \code{codigo_ugb}.
#' @param por_periodo Logico. Se \code{TRUE}, o resultado e cruzado com todos os
#'   periodos presentes em \code{df_esistafe} (uma linha por periodo x UGB). Se
#'   \code{FALSE} (padrao), devolve uma linha por UGB (comportamento global).
#'
#' @return Um tibble com \code{codigo_ugb}, \code{has_dotacao}, \code{has_afdp}
#'   e, quando \code{por_periodo = TRUE}, tambem \code{periodo}.
#'
#' @importFrom dplyr mutate left_join filter distinct
#' @importFrom tidyr replace_na crossing
#'
#' @keywords internal
#' @noRd
.calcular_ugb_completude <- function(df_esistafe, lookup_ugb, por_periodo = FALSE) {

  lookup_codes <- lookup_ugb |>
    dplyr::distinct(codigo_ugb) |>
    dplyr::mutate(codigo_ugb = as.character(codigo_ugb))

  funcionamento <- df_esistafe |>
    dplyr::filter(reporte_tipo == "Funcionamento")

  if (por_periodo) {
    dot <- funcionamento |>
      dplyr::filter(!is.na(dotacao_actualizada_da), dotacao_actualizada_da > 0) |>
      dplyr::distinct(periodo, ugb_id) |>
      dplyr::mutate(has_dotacao = TRUE)

    afdp <- funcionamento |>
      dplyr::filter(!is.na(ad_fundos_desp_paga_vd_afdp), ad_fundos_desp_paga_vd_afdp > 0) |>
      dplyr::distinct(periodo, ugb_id) |>
      dplyr::mutate(has_afdp = TRUE)

    periodos <- df_esistafe |> dplyr::distinct(periodo)

    tidyr::crossing(periodos, lookup_codes) |>
      dplyr::left_join(dot,  by = c("periodo", "codigo_ugb" = "ugb_id")) |>
      dplyr::left_join(afdp, by = c("periodo", "codigo_ugb" = "ugb_id")) |>
      dplyr::mutate(
        has_dotacao = tidyr::replace_na(has_dotacao, FALSE),
        has_afdp    = tidyr::replace_na(has_afdp, FALSE)
      )
  } else {
    lookup_codes |>
      dplyr::left_join(
        funcionamento |>
          dplyr::filter(!is.na(dotacao_actualizada_da), dotacao_actualizada_da > 0) |>
          dplyr::distinct(ugb_id) |>
          dplyr::mutate(has_dotacao = TRUE),
        by = c("codigo_ugb" = "ugb_id")
      ) |>
      dplyr::left_join(
        funcionamento |>
          dplyr::filter(!is.na(ad_fundos_desp_paga_vd_afdp), ad_fundos_desp_paga_vd_afdp > 0) |>
          dplyr::distinct(ugb_id) |>
          dplyr::mutate(has_afdp = TRUE),
        by = c("codigo_ugb" = "ugb_id")
      ) |>
      dplyr::mutate(
        has_dotacao = tidyr::replace_na(has_dotacao, FALSE),
        has_afdp    = tidyr::replace_na(has_afdp, FALSE)
      )
  }
}
