#' Extrair metadados de ficheiros de extracto e-SISTAFE
#'
#' Extrai metadados relevantes a partir dos nomes de ficheiros de exportação
#' do e-SISTAFE, incluindo o tipo de relatório, datas de referência e de
#' extracção, ano e mês em português. Suporta um ou múltiplos ficheiros.
#'
#' @param caminho Um vector de caracteres com um ou mais caminhos completos ou
#'   relativos para ficheiros de exportação e-SISTAFE. Os nomes dos ficheiros
#'   devem seguir a convenção de nomenclatura padrão do e-SISTAFE, contendo
#'   padrões de data no formato \code{YYYYMMDD}.
#'
#' @return Um tibble com uma linha por ficheiro e as seguintes colunas:
#' \describe{
#'   \item{file_name}{Nome do ficheiro sem o caminho completo.}
#'   \item{reporte_tipo}{Tipo de relatório classificado a partir do nome do
#'     ficheiro. Um de \code{"Funcionamento"}, \code{"Investimento Externo"},
#'     \code{"Investimento Interno"}, ou \code{NA} se não reconhecido.}
#'   \item{data_reporte}{Data de referência do relatório como objecto
#'     \code{Date}, extraída do primeiro padrão \code{YYYYMMDD} no nome
#'     do ficheiro.}
#'   \item{data_extraido}{Data de extracção do ficheiro como objecto
#'     \code{Date}, extraída do segundo padrão \code{YYYYMMDD} no nome
#'     do ficheiro.}
#'   \item{ano}{Ano da data de referência como inteiro.}
#'   \item{mes}{Mês da data de referência em português (ex. \code{"Janeiro"}).}
#' }
#'
#' @details
#' A classificação do tipo de relatório é feita por detecção de padrões no
#' nome do ficheiro:
#' \itemize{
#'   \item \code{"InvestimentoCompExterna"} → \code{"Investimento Externo"}
#'   \item \code{"InvestimentoCompInterna"} → \code{"Investimento Interno"}
#'   \item \code{"OrcamentoFuncionamento"}  → \code{"Funcionamento"}
#' }
#' Se nenhum padrão for reconhecido, \code{reporte_tipo} é \code{NA}.
#'
#' As datas são extraídas pelo padrão regex \code{\\d{8}} — espera-se que o
#' primeiro match corresponda à data de referência do relatório e o segundo
#' à data de extracção.
#'
#' @examples
#' \dontrun{
#' # Ficheiro único
#' extrair_meta_extracto("Data/DemonstrativoConsolidadoOrcamentoFuncionamento_20251231_20260205.xlsx")
#'
#' # Múltiplos ficheiros
#' path_files <- list.files("Data/", pattern = "\\.xlsx$", full.names = TRUE)
#' extrair_meta_extracto(path_files)
#' }
#'
#' @importFrom purrr map
#' @importFrom dplyr coalesce
#' @importFrom stringr str_detect str_extract_all
#' @importFrom tibble tibble
#' @importFrom lubridate year month
#'
#' @export

extrair_meta_extracto <- function(caminho) {

  extrair_um <- function(c) {
    # ------------------------------------------------------------
    # Extract file name
    # ------------------------------------------------------------
    fname <- base::basename(c)
    # ------------------------------------------------------------
    # Report type classification
    # ------------------------------------------------------------
    if (stringr::str_detect(fname, "InvestimentoCompExterna")) {
      report_type <- "Investimento Externo"
    } else if (stringr::str_detect(fname, "InvestimentoCompInterna")) {
      report_type <- "Investimento Interno"
    } else if (stringr::str_detect(fname, "OrcamentoFuncionamento")) {
      report_type <- "Funcionamento"
    } else {
      report_type <- NA_character_
    }
    # ------------------------------------------------------------
    # Extract dates (YYYYMMDD patterns)
    # ------------------------------------------------------------
    dates <- stringr::str_extract_all(fname, "\\d{8}")[[1]]
    ref_date    <- dplyr::coalesce(dates[1], NA_character_)
    extract_date <- dplyr::coalesce(dates[2], NA_character_)
    # Convert to real Date objects
    ref_dt     <- base::as.Date(ref_date,     format = "%Y%m%d")
    extract_dt <- base::as.Date(extract_date, format = "%Y%m%d")
    # ------------------------------------------------------------
    # Portuguese month names (ASCII-safe)
    # ------------------------------------------------------------
    meses_pt <- c(
      "Janeiro", "Fevereiro", "Mar\u00E7o", "Abril",
      "Maio", "Junho", "Julho", "Agosto",
      "Setembro", "Outubro", "Novembro", "Dezembro"
    )
    # ------------------------------------------------------------
    # Extract year + month
    # ------------------------------------------------------------
    ano <- if (!base::is.na(ref_dt)) lubridate::year(ref_dt)          else NA_integer_
    mes <- if (!base::is.na(ref_dt)) meses_pt[lubridate::month(ref_dt)] else NA_character_
    # ------------------------------------------------------------
    # Return metadata tibble
    # ------------------------------------------------------------
    tibble::tibble(
      file_name     = fname,
      reporte_tipo  = report_type,
      data_reporte  = ref_dt,
      data_extraido = extract_dt,
      ano           = ano,
      mes           = mes
    )
  }

  purrr::map(caminho, extrair_um) |> purrr::list_rbind()

}


