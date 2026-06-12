#' Lookup table mapping razao contabilistica source file names to descriptions
#'
#' A reference table that maps the PDF filenames produced by the e-SISTAFE
#' razao contabilistica and ABSA bank extract exports to human-readable
#' descriptions and province names. Used to enrich the output of
#' \code{\link{processar_extracto_razao_c}} and
#' \code{\link{processar_extracto_absa}} via a \code{left_join} on
#' \code{source_file}.
#'
#' @format A tibble with 32 rows and 3 columns:
#' \describe{
#'   \item{source_file}{\code{character}. The PDF filename as it appears in
#'     the \code{source_file} column of the processed output (e.g.
#'     \code{"MAPUTO PROVINCIA.pdf"}).}
#'   \item{descricao}{\code{character}. Human-readable description of the
#'     account or province corresponding to the file.}
#'   \item{provincia}{\code{character}. Province name, or \code{NA} for
#'     central/national accounts (CUT, ABSA, FOREX).}
#' }
"lookup_razao"
