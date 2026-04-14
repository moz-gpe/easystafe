#' Aplicar conversao de moeda a um tibble de extractos do e-SISTAFE
#'
#' Calcula \code{valor_lancamento_mt}, \code{valor_lancamento_usd} e
#' \code{valor_lancamento_eur} com base no nome do ficheiro de origem
#' (\code{source_file}), aplicando as taxas de cambio fornecidas. Pode ser
#' chamada de forma independente ou e invocada internamente por
#' \code{processar_extracto_razao_c()}.
#'
#' @param df Tibble. Output de \code{processar_extracto_razao_c()} ou qualquer
#'   tibble com as colunas \code{source_file} e \code{valor_lancamento}.
#' @param usd_to_mt Numerico. Taxa de cambio USD para MZN. Obrigatorio.
#' @param eur_to_mt Numerico. Taxa de cambio EUR para MZN. Obrigatorio.
#' @param eur_to_usd Numerico. Taxa de cambio EUR para USD. Obrigatorio.
#'
#' @return O tibble de entrada com tres colunas adicionais imediatamente a
#'   direita de \code{valor_lancamento}:
#'   \describe{
#'     \item{valor_lancamento_mt}{Valor do lancamento em MZN. Para ficheiros
#'       MZN, igual a \code{valor_lancamento}. Para ficheiros USD, calculado
#'       via \code{valor_lancamento * usd_to_mt}. Para ficheiros EUR,
#'       calculado via \code{valor_lancamento * eur_to_mt}.}
#'     \item{valor_lancamento_usd}{Valor do lancamento em USD. Para ficheiros
#'       USD, igual a \code{valor_lancamento}. Para ficheiros MZN, calculado
#'       via \code{valor_lancamento / usd_to_mt}. Para ficheiros EUR,
#'       calculado via \code{valor_lancamento * eur_to_usd}.}
#'     \item{valor_lancamento_eur}{Valor do lancamento em EUR. Para ficheiros
#'       EUR, igual a \code{valor_lancamento}. Para ficheiros MZN, calculado
#'       via \code{valor_lancamento / eur_to_mt}. Para ficheiros USD,
#'       calculado via \code{valor_lancamento / eur_to_usd}.}
#'   }
#'
#' @details
#' A logica de conversao baseia-se no nome do ficheiro de origem:
#' \itemize{
#'   \item \code{"CENTRAL USD"}: \code{valor_lancamento_mt = valor_lancamento * usd_to_mt};
#'     \code{valor_lancamento_usd = valor_lancamento};
#'     \code{valor_lancamento_eur = valor_lancamento / eur_to_usd}.
#'   \item \code{"CENTRAL EUR"}: \code{valor_lancamento_mt = valor_lancamento * eur_to_mt};
#'     \code{valor_lancamento_usd = valor_lancamento * eur_to_usd};
#'     \code{valor_lancamento_eur = valor_lancamento}.
#'   \item Todos os outros ficheiros (MZN): \code{valor_lancamento_mt = valor_lancamento};
#'     \code{valor_lancamento_usd = valor_lancamento / usd_to_mt};
#'     \code{valor_lancamento_eur = valor_lancamento / eur_to_mt}.
#' }
#'
#' Para re-aplicar conversoes com taxas actualizadas sem re-processar os PDFs,
#' chame esta funcao directamente sobre o tibble ja processado (removendo
#' previamente as colunas existentes se necessario).
#'
#' @examples
#' \dontrun{
#' # Uso independente sobre um tibble ja processado
#' df_com_moeda <- aplicar_conversao_moeda(
#'   df         = df_razao,
#'   usd_to_mt  = 63.86,
#'   eur_to_mt  = 70.00,
#'   eur_to_usd = 1.10
#' )
#'
#' # Re-aplicar com taxas actualizadas
#' df_revalorizado <- df_razao |>
#'   dplyr::select(-valor_lancamento_mt, -valor_lancamento_usd, -valor_lancamento_eur) |>
#'   aplicar_conversao_moeda(usd_to_mt = 64.10, eur_to_mt = 71.20, eur_to_usd = 1.11)
#' }
#'
#' @export

aplicar_conversao_moeda <- function(df, usd_to_mt, eur_to_mt, eur_to_usd) {

  # ---- Validacao de argumentos ----
  if (!inherits(df, "data.frame")) {
    cli::cli_abort("{.arg df} deve ser um data frame ou tibble.")
  }

  required_cols <- c("source_file", "valor_lancamento")
  missing_cols  <- setdiff(required_cols, names(df))
  if (length(missing_cols) > 0) {
    cli::cli_abort(
      "As seguintes colunas estao em falta em {.arg df}: {.field {missing_cols}}."
    )
  }

  if (!is.numeric(usd_to_mt)  || length(usd_to_mt)  != 1 || usd_to_mt  <= 0) {
    cli::cli_abort("{.arg usd_to_mt} deve ser um numero positivo.")
  }
  if (!is.numeric(eur_to_mt)  || length(eur_to_mt)  != 1 || eur_to_mt  <= 0) {
    cli::cli_abort("{.arg eur_to_mt} deve ser um numero positivo.")
  }
  if (!is.numeric(eur_to_usd) || length(eur_to_usd) != 1 || eur_to_usd <= 0) {
    cli::cli_abort("{.arg eur_to_usd} deve ser um numero positivo.")
  }

  # ---- Conversao ----
  df |>
    dplyr::mutate(
      valor_lancamento_mt = dplyr::case_when(
        stringr::str_detect(source_file, "CENTRAL USD|EXTRACTO ABSA BANK USD") ~ valor_lancamento * usd_to_mt,
        stringr::str_detect(source_file, "CENTRAL EUR")                         ~ valor_lancamento * eur_to_mt,
        stringr::str_detect(source_file, "EXTRACTO ABSA BANK MT")               ~ valor_lancamento,
        .default = valor_lancamento
      ),
      valor_lancamento_usd = dplyr::case_when(
        stringr::str_detect(source_file, "CENTRAL USD|EXTRACTO ABSA BANK USD") ~ valor_lancamento,
        stringr::str_detect(source_file, "CENTRAL EUR")                         ~ valor_lancamento * eur_to_usd,
        stringr::str_detect(source_file, "EXTRACTO ABSA BANK MT")               ~ valor_lancamento / usd_to_mt,
        .default = valor_lancamento / usd_to_mt
      ),
      valor_lancamento_eur = dplyr::case_when(
        stringr::str_detect(source_file, "CENTRAL EUR")                         ~ valor_lancamento,
        stringr::str_detect(source_file, "CENTRAL USD|EXTRACTO ABSA BANK USD") ~ valor_lancamento / eur_to_usd,
        stringr::str_detect(source_file, "EXTRACTO ABSA BANK MT")               ~ valor_lancamento / eur_to_mt,
        .default = valor_lancamento / eur_to_mt
      ),
      saldo_inicial_fim_mt = dplyr::case_when(
        stringr::str_detect(source_file, "CENTRAL USD|EXTRACTO ABSA BANK USD") ~ saldo_inicial_fim * usd_to_mt,
        stringr::str_detect(source_file, "CENTRAL EUR")                         ~ saldo_inicial_fim * eur_to_mt,
        stringr::str_detect(source_file, "EXTRACTO ABSA BANK MT")               ~ saldo_inicial_fim,
        .default = saldo_inicial_fim
      ),
      saldo_inicial_fim_usd = dplyr::case_when(
        stringr::str_detect(source_file, "CENTRAL USD|EXTRACTO ABSA BANK USD") ~ saldo_inicial_fim,
        stringr::str_detect(source_file, "CENTRAL EUR")                         ~ saldo_inicial_fim * eur_to_usd,
        stringr::str_detect(source_file, "EXTRACTO ABSA BANK MT")               ~ saldo_inicial_fim / usd_to_mt,
        .default = saldo_inicial_fim / usd_to_mt
      ),
      saldo_inicial_fim_eur = dplyr::case_when(
        stringr::str_detect(source_file, "CENTRAL EUR")                         ~ saldo_inicial_fim,
        stringr::str_detect(source_file, "CENTRAL USD|EXTRACTO ABSA BANK USD") ~ saldo_inicial_fim / eur_to_usd,
        stringr::str_detect(source_file, "EXTRACTO ABSA BANK MT")               ~ saldo_inicial_fim / eur_to_mt,
        .default = saldo_inicial_fim / eur_to_mt
      )
    ) |>
    dplyr::relocate(
      valor_lancamento_mt, valor_lancamento_usd, valor_lancamento_eur,
      .after = valor_lancamento
    ) |>
    dplyr::relocate(
      saldo_inicial_fim_mt, saldo_inicial_fim_usd, saldo_inicial_fim_eur,
      .after = saldo_inicial_fim
    )
}
