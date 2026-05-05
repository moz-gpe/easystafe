#' Aplicar conversao de moeda a um tibble de extractos do e-SISTAFE
#'
#' Calcula \code{valor_lancamento_mt}, \code{valor_lancamento_usd},
#' \code{valor_lancamento_eur}, \code{saldo_inicial_fim_mt},
#' \code{saldo_inicial_fim_usd} e \code{saldo_inicial_fim_eur} com base no
#' nome do ficheiro de origem (\code{source_file}), aplicando as taxas de
#' cambio fornecidas. Pode ser chamada de forma independente ou e invocada
#' internamente por \code{processar_extracto_razao_c()} e
#' \code{processar_extracto_absa()}.
#'
#' @param df Tibble. Output de \code{processar_extracto_razao_c()} ou qualquer
#'   tibble com as colunas \code{source_file}, \code{valor_lancamento} e
#'   \code{saldo_inicial_fim}.
#' @param usd_to_mt Numerico. Taxa de cambio USD para MZN. Utilizada para
#'   ficheiros \code{"EXTRACTO ABSA BANK USD"} e como fallback geral para
#'   ficheiros MZN. Por padrao \code{63.91}.
#' @param cut_usd_to_mt Numerico. Taxa de cambio USD para MZN especifica para
#'   ficheiros \code{"CENTRAL USD"}. Por padrao \code{63.27}.
#' @param eur_to_mt Numerico. Taxa de cambio EUR para MZN. Utilizada para
#'   ficheiros \code{"CENTRAL EUR"}. Por padrao \code{70.00}
#'   (valor indicativo; actualizar conforme necessario).
#' @param eur_to_usd Numerico. Taxa de cambio EUR para USD. Utilizada para
#'   calcular conversoes EUR/USD. Por padrao \code{1.10}
#'   (valor indicativo; actualizar conforme necessario).
#'
#' @return O tibble de entrada com seis colunas adicionais, posicionadas
#'   imediatamente a direita das suas colunas de origem:
#'   \describe{
#'     \item{valor_lancamento_mt}{Valor do lancamento em MZN.}
#'     \item{valor_lancamento_usd}{Valor do lancamento em USD.}
#'     \item{valor_lancamento_eur}{Valor do lancamento em EUR.}
#'     \item{saldo_inicial_fim_mt}{Saldo inicial ou final em MZN.}
#'     \item{saldo_inicial_fim_usd}{Saldo inicial ou final em USD.}
#'     \item{saldo_inicial_fim_eur}{Saldo inicial ou final em EUR.}
#'   }
#'
#' @details
#' A logica de conversao baseia-se no nome do ficheiro de origem. A tabela
#' abaixo resume as taxas aplicadas a cada tipo de ficheiro:
#'
#' \tabular{llll}{
#'   \strong{Ficheiro}          \tab \strong{_mt}          \tab \strong{_usd}           \tab \strong{_eur} \cr
#'   CENTRAL USD                \tab * cut_usd_to_mt        \tab = valor original         \tab / eur_to_usd \cr
#'   EXTRACTO ABSA BANK USD     \tab * usd_to_mt            \tab = valor original         \tab / eur_to_usd \cr
#'   CENTRAL EUR                \tab * eur_to_mt            \tab * eur_to_usd            \tab = valor original \cr
#'   EXTRACTO ABSA BANK MT/MZN  \tab = valor original       \tab / usd_to_mt             \tab / eur_to_mt \cr
#' }
#'
#' Para re-aplicar conversoes com taxas actualizadas sem re-processar os PDFs,
#' chame esta funcao directamente sobre o tibble ja processado, removendo
#' previamente as colunas de conversao existentes.
#'
#' @examples
#' \dontrun{
#' # Uso independente sobre um tibble ja processado
#' df_com_moeda <- aplicar_conversao_moeda(
#'   df             = df_razao,
#'   usd_to_mt      = 63.91,
#'   cut_usd_to_mt  = 63.27,
#'   eur_to_mt      = 70.00,
#'   eur_to_usd     = 1.10
#' )
#'
#' # Re-aplicar com taxas actualizadas
#' df_revalorizado <- df_razao |>
#'   dplyr::select(-valor_lancamento_mt, -valor_lancamento_usd,
#'                 -valor_lancamento_eur, -saldo_inicial_fim_mt,
#'                 -saldo_inicial_fim_usd, -saldo_inicial_fim_eur) |>
#'   aplicar_conversao_moeda(
#'     usd_to_mt     = 0.015700,
#'     cut_usd_to_mt = 0.015900,
#'     eur_to_mt     = 71.20,
#'     eur_to_usd    = 1.11
#'   )
#' }
#'
#' @export

aplicar_conversao_moeda <- function(
    df,
    usd_to_mt     = 63.91,
    cut_usd_to_mt = 63.27,
    eur_to_mt     = 70.00,
    eur_to_usd    = 1.10
) {

  # ---- Validacao de argumentos ----
  if (!inherits(df, "data.frame")) {
    cli::cli_abort("{.arg df} deve ser um data frame ou tibble.")
  }

  required_cols <- c("source_file", "valor_lancamento", "saldo_inicial_fim")
  missing_cols  <- setdiff(required_cols, names(df))
  if (length(missing_cols) > 0) {
    cli::cli_abort(
      "As seguintes colunas estao em falta em {.arg df}: {.field {missing_cols}}."
    )
  }

  if (!is.numeric(usd_to_mt)     || length(usd_to_mt)     != 1 || usd_to_mt     <= 0) {
    cli::cli_abort("{.arg usd_to_mt} deve ser um numero positivo.")
  }
  if (!is.numeric(cut_usd_to_mt) || length(cut_usd_to_mt) != 1 || cut_usd_to_mt <= 0) {
    cli::cli_abort("{.arg cut_usd_to_mt} deve ser um numero positivo.")
  }
  if (!is.numeric(eur_to_mt)     || length(eur_to_mt)     != 1 || eur_to_mt     <= 0) {
    cli::cli_abort("{.arg eur_to_mt} deve ser um numero positivo.")
  }
  if (!is.numeric(eur_to_usd)    || length(eur_to_usd)    != 1 || eur_to_usd    <= 0) {
    cli::cli_abort("{.arg eur_to_usd} deve ser um numero positivo.")
  }

  # ---- Conversao ----
  df |>
    dplyr::mutate(
      valor_lancamento_mt = dplyr::case_when(
        stringr::str_detect(source_file, "CENTRAL USD")              ~ valor_lancamento * cut_usd_to_mt,
        stringr::str_detect(source_file, "EXTRACTO ABSA BANK USD")   ~ valor_lancamento * usd_to_mt,
        stringr::str_detect(source_file, "CENTRAL EUR")              ~ valor_lancamento * eur_to_mt,
        stringr::str_detect(source_file, "EXTRACTO ABSA BANK MT")    ~ valor_lancamento,
        .default = valor_lancamento
      ),
      valor_lancamento_usd = dplyr::case_when(
        stringr::str_detect(source_file, "CENTRAL USD")              ~ valor_lancamento,
        stringr::str_detect(source_file, "EXTRACTO ABSA BANK USD")   ~ valor_lancamento,
        stringr::str_detect(source_file, "CENTRAL EUR")              ~ valor_lancamento * eur_to_usd,
        stringr::str_detect(source_file, "EXTRACTO ABSA BANK MT")    ~ valor_lancamento / usd_to_mt,
        .default = valor_lancamento / usd_to_mt
      ),
      valor_lancamento_eur = dplyr::case_when(
        stringr::str_detect(source_file, "CENTRAL EUR")              ~ valor_lancamento,
        stringr::str_detect(source_file, "CENTRAL USD")              ~ valor_lancamento / eur_to_usd,
        stringr::str_detect(source_file, "EXTRACTO ABSA BANK USD")   ~ valor_lancamento / eur_to_usd,
        stringr::str_detect(source_file, "EXTRACTO ABSA BANK MT")    ~ valor_lancamento / eur_to_mt,
        .default = valor_lancamento / eur_to_mt
      ),
      saldo_inicial_fim_mt = dplyr::case_when(
        stringr::str_detect(source_file, "CENTRAL USD")              ~ saldo_inicial_fim * cut_usd_to_mt,
        stringr::str_detect(source_file, "EXTRACTO ABSA BANK USD")   ~ saldo_inicial_fim * usd_to_mt,
        stringr::str_detect(source_file, "CENTRAL EUR")              ~ saldo_inicial_fim * eur_to_mt,
        stringr::str_detect(source_file, "EXTRACTO ABSA BANK MT")    ~ saldo_inicial_fim,
        .default = saldo_inicial_fim
      ),
      saldo_inicial_fim_usd = dplyr::case_when(
        stringr::str_detect(source_file, "CENTRAL USD")              ~ saldo_inicial_fim,
        stringr::str_detect(source_file, "EXTRACTO ABSA BANK USD")   ~ saldo_inicial_fim,
        stringr::str_detect(source_file, "CENTRAL EUR")              ~ saldo_inicial_fim * eur_to_usd,
        stringr::str_detect(source_file, "EXTRACTO ABSA BANK MT")    ~ saldo_inicial_fim / usd_to_mt,
        .default = saldo_inicial_fim / usd_to_mt
      ),
      saldo_inicial_fim_eur = dplyr::case_when(
        stringr::str_detect(source_file, "CENTRAL EUR")              ~ saldo_inicial_fim,
        stringr::str_detect(source_file, "CENTRAL USD")              ~ saldo_inicial_fim / eur_to_usd,
        stringr::str_detect(source_file, "EXTRACTO ABSA BANK USD")   ~ saldo_inicial_fim / eur_to_usd,
        stringr::str_detect(source_file, "EXTRACTO ABSA BANK MT")    ~ saldo_inicial_fim / eur_to_mt,
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
