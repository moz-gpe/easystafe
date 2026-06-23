#' Razão Contabilística source-file mapping table
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
"razao_map"

#' Province name mapping table for Mozambique
#'
#' Maps variant province name spellings and abbreviations found in e-SISTAFE
#' exports to canonical official names and integer keys. Used to normalise the
#' \code{provincia} column before joining to other dimensional tables.
#'
#' @format A tibble with 15 rows and 3 columns:
#' \describe{
#'   \item{provincia_fonte}{\code{character}. Province name as it appears in
#'     the source data (may include spelling variants, missing accents, or
#'     abbreviations).}
#'   \item{provincia_oficial}{\code{character}. Canonical official province
#'     name (with correct diacritics).}
#'   \item{provincia_id}{\code{integer}. Numeric identifier for the province
#'     (1–11), consistent with the Mozambican administrative numbering scheme.}
#' }
"provincia_map"

#' District name mapping table for Mozambique
#'
#' Maps variant district name spellings found in e-SISTAFE exports to canonical
#' official names and integer keys. Includes encoding artefacts (e.g.
#' mojibake strings) as additional source variants so that raw data can be
#' reliably matched regardless of character-encoding provenance.
#'
#' @format A tibble with 210 rows and 3 columns:
#' \describe{
#'   \item{distrito_fonte}{\code{character}. District name as it appears in
#'     the source data (may include encoding errors, spelling variants, or
#'     alternative administrative labels).}
#'   \item{distrito_oficial}{\code{character}. Canonical official district
#'     name (with correct diacritics).}
#'   \item{distrito_id}{\code{integer}. Numeric identifier for the district.
#'     The first two digits correspond to \code{provincia_id} in
#'     \code{\link{provincia_map}}.}
#' }
"distrito_map"
