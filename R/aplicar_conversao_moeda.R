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


#' Parse a Banco de Mocambique exchange rate PDF into a tidy tibble
#'
#' @param filepath Path to a PDF file downloaded from bancomoc.mz. The filename
#'   must contain an 8-digit date string in \code{DDMMYYYY} format.
#'
#' @return A tibble with columns \code{date}, \code{country}, \code{currency},
#'   \code{compra}, \code{venda}, \code{media}, and \code{per_1000}.
#'
#' @export
parse_bancomoc_pdf <- function(filepath) {
  date_str <- stringr::str_extract(basename(filepath), "\\d{8}(?=\\.pdf)")
  date <- lubridate::dmy(date_str)

  lines <- pdftools::pdf_text(filepath) |>
    stringr::str_split("\n") |>
    unlist()

  num <- "\\d[\\d\\.]*,\\d+"
  pat <- paste0(
    "^(\\s*.+?)\\s{2,}(\\S+)\\s{2,}(",
    num,
    ")\\s+(",
    num,
    ")\\s+(",
    num,
    ")\\s*$"
  )

  per_1000 <- FALSE
  rows <- list()

  for (line in lines) {
    if (stringr::str_detect(line, "1000 Unidades")) {
      per_1000 <- TRUE
    } else if (stringr::str_detect(line, "Unidade de Moeda")) {
      per_1000 <- FALSE
    }

    m <- stringr::str_match(line, pat)
    if (!is.na(m[1, 1])) {
      rows[[length(rows) + 1]] <- tibble::tibble(
        date = date,
        country = stringr::str_remove(
          stringr::str_trim(m[1, 2]),
          "\\(\\w\\)$"
        ) |>
          stringr::str_trim(),
        currency = stringr::str_trim(m[1, 3]),
        compra = readr::parse_number(
          m[1, 4],
          locale = readr::locale(decimal_mark = ",", grouping_mark = ".")
        ),
        venda = readr::parse_number(
          m[1, 5],
          locale = readr::locale(decimal_mark = ",", grouping_mark = ".")
        ),
        media = readr::parse_number(
          m[1, 6],
          locale = readr::locale(decimal_mark = ",", grouping_mark = ".")
        ),
        per_1000 = per_1000
      )
    }
  }

  dplyr::bind_rows(rows)
}


#' Download and parse Banco de Mocambique exchange rate PDFs
#'
#' Scrapes PDF links from the Banco de Mocambique website, downloads any new
#' files to \code{out_dir}, parses all files in that directory, and returns a
#' combined tidy tibble.
#'
#' @param out_dir Directory where PDFs are saved. Created if it does not exist.
#'   Defaults to \code{"Data/pdfs_bancomoc"}.
#' @param url_path URL path on \url{https://www.bancomoc.mz} for the page
#'   listing exchange rate PDFs.
#' @param keep_countries Character vector of country names to retain. Pass
#'   \code{character(0)} to return all countries. Defaults to
#'   \code{c("Estados Unidos", "Uni\u00e3o Europeia")}.
#'
#' @return A tibble with columns \code{date}, \code{country}, \code{currency},
#'   \code{compra}, \code{venda}, \code{media}, and \code{per_1000}.
#'
#' @export
obter_conversao_bancomoc <- function(
  out_dir = "Data/pdfs_bancomoc",
  url_path = "/pt/tabelas-de-taxas-de-cambio-de-referencia-diarias/2026-2025/",
  keep_countries = c("Estados Unidos", "Uni\u00e3o Europeia")
) {
  base_url <- "https://www.bancomoc.mz"
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  page <- rvest::read_html(paste0(base_url, url_path))

  pdf_links <- page |>
    rvest::html_elements("a[href$='.pdf']") |>
    rvest::html_attr("href") |>
    stringr::str_subset("taxas-de-c")

  purrr::walk(pdf_links, \(link) {
    date_str <- stringr::str_extract(link, "\\d{8}(?=\\.pdf)")
    dest <- file.path(out_dir, paste0("taxas_", date_str, ".pdf"))
    if (file.exists(dest)) {
      return(invisible(NULL))
    }
    tryCatch(
      download.file(
        paste0(base_url, link),
        destfile = dest,
        mode = "wb",
        quiet = TRUE
      ),
      error = \(e) message("Failed: ", link, " - ", e$message)
    )
  })

  pdf_files <- list.files(out_dir, pattern = "\\.pdf$", full.names = TRUE)
  cambios <- purrr::map(pdf_files, parse_bancomoc_pdf) |> dplyr::bind_rows()

  if (length(keep_countries) > 0) {
    cambios <- dplyr::filter(cambios, .data$country %in% keep_countries)
  }

  cambios
}
