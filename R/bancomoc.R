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
#' @param wide Logical. If \code{TRUE} (default), returns a daily wide-format
#'   table with one row per calendar date and one \code{taxa_*} column per
#'   currency (e.g. \code{taxa_dolar}, \code{taxa_euro}), with gaps filled by
#'   the preceding trading-day rate (LOCF). If \code{FALSE}, returns the raw
#'   long-format tibble.
#'
#' @return When \code{wide = FALSE}: a tibble with columns \code{date},
#'   \code{country}, \code{currency}, \code{compra}, \code{venda},
#'   \code{media}, and \code{per_1000}. When \code{wide = TRUE}: a tibble
#'   with \code{date} and one \code{taxa_*} column per currency present in the
#'   data.
#'
#' @export
obter_conversao_bancomoc <- function(
  out_dir = "Data/pdfs_bancomoc",
  url_path = "/pt/tabelas-de-taxas-de-cambio-de-referencia-diarias/2026-2025/",
  keep_countries = c("Estados Unidos", "Uni\u00e3o Europeia"),
  wide = TRUE
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

  if (!wide) {
    return(cambios)
  }

  rates <- cambios |>
    dplyr::select("date", "currency", "compra") |>
    tidyr::pivot_wider(
      names_from = "currency",
      values_from = "compra",
      names_glue = "taxa_{tolower(currency)}"
    ) |>
    dplyr::arrange(.data$date)

  tibble::tibble(date = seq(min(rates$date), max(rates$date), by = "day")) |>
    dplyr::left_join(rates, by = "date") |>
    tidyr::fill(dplyr::where(is.numeric), .direction = "down")
}


#' Add daily exchange rate conversions to a razao contabilistica tibble
#'
#' Joins a wide daily-rates table (from \code{obter_conversao_bancomoc(wide =
#' TRUE)}) to \code{df} on the transaction date, then overwrites the
#' \code{_usd} and \code{_eur} columns using per-row \code{compra} rates.
#' The EUR/USD cross rate is derived as \code{taxa_euro / taxa_dolar}.
#' \code{taxa_dolar} and \code{taxa_euro} are appended and relocated after
#' \code{mes}.
#'
#' @param df Tibble. Output of \code{processar_extracto_razao_c()} or
#'   \code{processar_extracto_absa()}, containing at minimum the columns
#'   \code{source_file}, \code{data}, \code{mes}, \code{valor_lancamento},
#'   \code{valor_lancamento_usd}, \code{valor_lancamento_eur},
#'   \code{saldo_inicial_fim}, \code{saldo_inicial_fim_usd}, and
#'   \code{saldo_inicial_fim_eur}.
#' @param rates_diarias Tibble. Wide daily-rates table returned by
#'   \code{obter_conversao_bancomoc(wide = TRUE)}, with columns \code{date},
#'   \code{taxa_dolar}, and \code{taxa_euro}.
#'
#' @return \code{df} with \code{valor_lancamento_usd},
#'   \code{valor_lancamento_eur}, \code{saldo_inicial_fim_usd}, and
#'   \code{saldo_inicial_fim_eur} overwritten using daily rates, plus
#'   \code{taxa_dolar} and \code{taxa_euro} columns positioned after
#'   \code{mes}.
#'
#' @export
adicionar_conversao_moeda <- function(df, rates_diarias) {
  df |>
    dplyr::left_join(rates_diarias, by = c("data" = "date")) |>
    dplyr::mutate(
      valor_lancamento_usd = dplyr::case_when(
        stringr::str_detect(
          .data$source_file,
          "CENTRAL USD"
        ) ~ .data$valor_lancamento,
        stringr::str_detect(
          .data$source_file,
          "EXTRACTO ABSA BANK USD"
        ) ~ .data$valor_lancamento,
        stringr::str_detect(
          .data$source_file,
          "CENTRAL EUR"
        ) ~ .data$valor_lancamento * (.data$taxa_euro / .data$taxa_dolar),
        .default = .data$valor_lancamento / .data$taxa_dolar
      ),
      valor_lancamento_eur = dplyr::case_when(
        stringr::str_detect(
          .data$source_file,
          "CENTRAL EUR"
        ) ~ .data$valor_lancamento,
        stringr::str_detect(
          .data$source_file,
          "CENTRAL USD"
        ) ~ .data$valor_lancamento / (.data$taxa_euro / .data$taxa_dolar),
        stringr::str_detect(
          .data$source_file,
          "EXTRACTO ABSA BANK USD"
        ) ~ .data$valor_lancamento / (.data$taxa_euro / .data$taxa_dolar),
        .default = .data$valor_lancamento / .data$taxa_euro
      ),
      saldo_inicial_fim_usd = dplyr::case_when(
        stringr::str_detect(
          .data$source_file,
          "CENTRAL USD"
        ) ~ .data$saldo_inicial_fim,
        stringr::str_detect(
          .data$source_file,
          "EXTRACTO ABSA BANK USD"
        ) ~ .data$saldo_inicial_fim,
        stringr::str_detect(
          .data$source_file,
          "CENTRAL EUR"
        ) ~ .data$saldo_inicial_fim * (.data$taxa_euro / .data$taxa_dolar),
        .default = .data$saldo_inicial_fim / .data$taxa_dolar
      ),
      saldo_inicial_fim_eur = dplyr::case_when(
        stringr::str_detect(
          .data$source_file,
          "CENTRAL EUR"
        ) ~ .data$saldo_inicial_fim,
        stringr::str_detect(
          .data$source_file,
          "CENTRAL USD"
        ) ~ .data$saldo_inicial_fim / (.data$taxa_euro / .data$taxa_dolar),
        stringr::str_detect(
          .data$source_file,
          "EXTRACTO ABSA BANK USD"
        ) ~ .data$saldo_inicial_fim / (.data$taxa_euro / .data$taxa_dolar),
        .default = .data$saldo_inicial_fim / .data$taxa_euro
      )
    ) |>
    dplyr::rename(
      valor_lancamento_mzn  = valor_lancamento,
      saldo_inicial_fim_mzn = saldo_inicial_fim
    ) |>
    dplyr::relocate(taxa_dolar, taxa_euro, .after = mes) |>
    dplyr::relocate(
      valor_lancamento_mzn, valor_lancamento_eur, valor_lancamento_usd,
      saldo_inicial_fim_mzn, saldo_inicial_fim_eur, saldo_inicial_fim_usd,
      .after = dplyr::last_col()
    )
}
