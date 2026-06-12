#' Gravar extracto processado do e-SISTAFE em Parquet e Excel
#'
#' Grava um dataframe processado do e-SISTAFE em dois formatos (Parquet e Excel),
#' construindo automaticamente o nome dos ficheiros a partir de todos os anos
#' presentes nos dados. Cria a pasta de destino se nao existir.
#'
#' @param df Um dataframe processado contendo pelo menos a coluna \code{ano}.
#' @param output_folder Caractere. Caminho para a pasta de destino. Por padrao
#'   \code{"Dataout/"}. A pasta e criada automaticamente se nao existir.
#' @param quiet Logico. Se \code{TRUE} (padrao), as mensagens de progresso
#'   sao suprimidas. Se \code{FALSE}, sao emitidas mensagens sobre o progresso.
#'
#' @return Um named list com os caminhos completos dos ficheiros gravados
#'   (\code{parquet} e \code{excel}), retornado de forma invisivel.
#'
#' @details
#' O nome dos ficheiros e construido automaticamente no formato:
#' \code{e-SISTAFE_<YYYY-YYYY>_<YYYY-MM-DD>.parquet} e
#' \code{e-SISTAFE_<YYYY-YYYY>_<YYYY-MM-DD>.xlsx}
#' onde os anos sao todos os valores unicos presentes na coluna \code{ano},
#' ordenados e separados por hifen.
#'
#' Por exemplo, dados abrangendo 2025 e 2026 produzem:
#' \code{e-SISTAFE_2025-2026_2026-02-24.parquet} e \code{e-SISTAFE_2025-2026_2026-02-24.xlsx}
#'
#' Se um ficheiro com o mesmo nome ja existir, o utilizador e avisado antes
#' de ser substituido.
#'
#' @examples
#' \dontrun{
#' gravar_esistafe(df_esistafe)
#' gravar_esistafe(df_esistafe, output_folder = "Data/final")
#' paths <- gravar_esistafe(df_esistafe, quiet = FALSE)
#' }
#'
#' @importFrom arrow write_parquet
#' @importFrom dplyr pull
#' @importFrom glue glue
#' @importFrom writexl write_xlsx
#'
#' @export

gravar_esistafe <- function(
    df,
    output_folder = "Dataout/",
    quiet         = TRUE
) {
  msg <- function(...) if (!quiet) message(...)

  if (!"ano" %in% base::names(df)) {
    stop("Coluna 'ano' nao encontrada no dataframe. ",
         "Certifique-se de que o dataframe contem a coluna 'ano'.")
  }

  output_folder <- base::gsub("/$", "", output_folder)

  years <- df |>
    dplyr::pull(ano) |>
    stats::na.omit() |>
    base::unique() |>
    base::sort()

  if (length(years) == 0) stop("A coluna 'ano' nao contem valores validos.")

  years_str    <- base::paste(years, collapse = "-")
  created_date <- base::format(base::Sys.Date(), "%Y-%m-%d")
  base_name    <- glue::glue("e-SISTAFE_{years_str}_{created_date}")
  path_parquet <- base::file.path(output_folder, glue::glue("{base_name}.parquet"))
  path_excel   <- base::file.path(output_folder, glue::glue("{base_name}.xlsx"))

  if (!base::dir.exists(output_folder)) {
    msg(glue::glue("Pasta '{output_folder}' nao encontrada - a criar..."))
    base::dir.create(output_folder, recursive = TRUE)
  }

  for (fp in c(path_parquet, path_excel)) {
    if (base::file.exists(fp)) warning(glue::glue("Ficheiro ja existe e sera substituido: {fp}"))
  }

  msg(glue::glue("A guardar Parquet: {path_parquet}"))
  arrow::write_parquet(df, path_parquet)

  msg(glue::glue("A guardar Excel: {path_excel}"))
  writexl::write_xlsx(df, path_excel)

  msg(glue::glue("Ficheiros do e-SISTAFE gravados em '{output_folder}':"))
  msg(glue::glue("  - {base_name}.parquet"))
  msg(glue::glue("  - {base_name}.xlsx"))

  base::invisible(list(parquet = path_parquet, excel = path_excel))
}


#' Gravar extracto da razao contabilistico processado em Parquet e Excel
#'
#' Grava um dataframe processado por \code{processar_extracto_razao_c()} em
#' dois formatos (Parquet e Excel), construindo automaticamente o nome dos
#' ficheiros a partir de todos os anos presentes na coluna \code{ano}. Cria
#' a pasta de destino se nao existir.
#'
#' @param df Um tibble processado por \code{processar_extracto_razao_c()}.
#'   Deve conter pelo menos a coluna \code{ano}.
#' @param output_folder Caractere. Caminho para a pasta de destino onde os
#'   ficheiros serao gravados. Por padrao \code{"Dataout"}. A pasta e
#'   criada automaticamente se nao existir.
#' @param quiet Logico. Se \code{TRUE} (padrao), as mensagens de progresso
#'   sao suprimidas. Se \code{FALSE}, sao emitidas mensagens sobre a criacao
#'   da pasta e os caminhos dos ficheiros gravados.
#'
#' @return Um named list com os caminhos completos dos ficheiros gravados
#'   (\code{parquet} e \code{excel}), retornado de forma invisivel.
#'
#' @details
#' O nome dos ficheiros e construido automaticamente no formato:
#' \code{RazaoCont_<YYYY-YYYY>_<YYYY-MM-DD>.parquet} e
#' \code{RazaoCont_<YYYY-YYYY>_<YYYY-MM-DD>.xlsx}.
#'
#' @examples
#' \dontrun{
#' gravar_extracto_razao_c(df_razao)
#' gravar_extracto_razao_c(df_razao, output_folder = "Dataout/subpasta")
#' paths <- gravar_extracto_razao_c(df_razao, quiet = FALSE)
#' }
#'
#' @importFrom arrow write_parquet
#' @importFrom dplyr pull
#' @importFrom glue glue
#' @importFrom writexl write_xlsx
#'
#' @export

gravar_extracto_razao_c <- function(
    df,
    output_folder = "Dataout",
    quiet         = TRUE
) {
  msg <- function(...) if (!quiet) message(...)

  if (!"ano" %in% base::names(df)) {
    stop("Coluna 'ano' nao encontrada no dataframe. ",
         "Certifique-se de que o dataframe contem a coluna 'ano'.")
  }

  output_folder <- base::gsub("/$", "", output_folder)

  years <- df |>
    dplyr::pull(ano) |>
    stats::na.omit() |>
    base::unique() |>
    base::sort()

  if (length(years) == 0) stop("A coluna 'ano' nao contem valores validos.")

  years_str    <- base::paste(years, collapse = "-")
  created_date <- base::format(base::Sys.Date(), "%Y-%m-%d")
  base_name    <- glue::glue("RazaoCont_{years_str}_{created_date}")
  path_parquet <- base::file.path(output_folder, glue::glue("{base_name}.parquet"))
  path_excel   <- base::file.path(output_folder, glue::glue("{base_name}.xlsx"))

  if (!base::dir.exists(output_folder)) {
    msg(glue::glue("Pasta '{output_folder}' nao encontrada - a criar..."))
    base::dir.create(output_folder, recursive = TRUE)
  }

  for (fp in c(path_parquet, path_excel)) {
    if (base::file.exists(fp)) warning(glue::glue("Ficheiro ja existe e sera substituido: {fp}"))
  }

  msg(glue::glue("A guardar Parquet: {path_parquet}"))
  arrow::write_parquet(df, path_parquet)

  msg(glue::glue("A guardar Excel: {path_excel}"))
  writexl::write_xlsx(df, path_excel)

  message(glue::glue("Ficheiros da Razao Contabilistica gravados em '{output_folder}':"))
  message(glue::glue("  - {base_name}.parquet"))
  message(glue::glue("  - {base_name}.xlsx"))

  base::invisible(list(parquet = path_parquet, excel = path_excel))
}


#' Gravar Extracto Bancario ABSA em Excel
#'
#' Guarda o tibble devolvido por \code{\link{processar_extracto_absa}} num
#' ficheiro Excel com um nome de ficheiro construido automaticamente a partir
#' dos metadados do proprio dataframe (ano, mes e data de execucao).
#'
#' @param df Um dataframe processado por \code{processar_extracto_absa()}.
#'   Deve conter as colunas \code{ano} e \code{mes}.
#' @param output_folder Caractere. Caminho para a pasta de destino onde o
#'   ficheiro Excel sera gravado. Por padrao \code{"Dataout"}. A pasta e
#'   criada automaticamente se nao existir.
#' @param quiet Logico. Se \code{TRUE} (padrao), suprime as mensagens de
#'   progresso. Se \code{FALSE}, sao emitidas mensagens sobre a criacao
#'   da pasta e o caminho do ficheiro gravado.
#'
#' @return Invisivel: o caminho completo do ficheiro gravado (\code{character(1)}).
#'
#' @details
#' O nome do ficheiro e construido no formato \code{ABSA_<YYYYMM>.xlsx}.
#' O ano e mes mais recentes sao extraidos das linhas de movimento.
#'
#' @examples
#' \dontrun{
#' df_absa <- processar_extracto_absa("Data/razao_cont/2026_02/outro/")
#' gravar_extracto_absa(df_absa)
#' gravar_extracto_absa(df_absa, output_folder = "Dataout/banco")
#' }
#'
#' @importFrom dplyr filter pull
#' @importFrom glue glue
#' @importFrom purrr map_int
#' @importFrom stringr str_pad
#' @importFrom writexl write_xlsx
#' @export

gravar_extracto_absa <- function(
    df,
    output_folder = "Dataout",
    quiet         = TRUE
) {
  msg <- function(...) if (!quiet) message(...)

  required_cols <- c("ano", "mes")
  missing_cols  <- base::setdiff(required_cols, base::names(df))
  if (base::length(missing_cols) > 0) {
    stop(glue::glue("Colunas de metadados em falta: {paste(missing_cols, collapse = ', ')}."))
  }

  output_folder <- base::gsub("/$", "", output_folder)

  df_meta <- if ("tipo" %in% base::names(df)) dplyr::filter(df, tipo == "MOVIMENTO") else df
  if (nrow(df_meta) == 0) df_meta <- df

  latest_ano <- df_meta |> dplyr::pull(ano) |> max(na.rm = TRUE)
  latest_mes <- df_meta |>
    dplyr::pull(mes) |>
    purrr::map_int(~ match(.x, c("Janeiro","Fevereiro","Marco","Abril","Maio","Junho",
                                 "Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"))) |>
    max(na.rm = TRUE) |>
    stringr::str_pad(2, pad = "0")

  if (is.infinite(latest_ano)) latest_ano <- "ano_desconhecido"
  if (is.infinite(as.numeric(latest_mes))) latest_mes <- "mes_desconhecido"

  file_name <- glue::glue("ABSA_{latest_ano}{latest_mes}.xlsx")
  file_path <- base::file.path(output_folder, file_name)

  if (!base::dir.exists(output_folder)) {
    msg(glue::glue("Pasta '{output_folder}' nao encontrada - a criar..."))
    base::dir.create(output_folder, recursive = TRUE)
  }

  msg(glue::glue("A guardar ficheiro: {file_path}"))
  writexl::write_xlsx(df, file_path)
  message(glue::glue("Ficheiro da ABSA gravado: {file_path}"))

  base::invisible(file_path)
}


#' Compilar ficheiros eSISTAFE processados num unico Excel
#'
#' Localiza todos os ficheiros Excel com o padrao \code{"eSISTAFE_"} numa
#' pasta de entrada, combina-os num unico tibble e grava o resultado em disco.
#'
#' @param input_folder Caractere. Caminho para a pasta que contem os ficheiros
#'   Excel a compilar. Por padrao \code{"Data/processed"}.
#' @param output_folder Caractere. Caminho para a pasta de destino. Por padrao
#'   \code{"Dataout"}. A pasta e criada automaticamente se nao existir.
#' @param quiet Logico. Se \code{TRUE} (padrao), suprime as mensagens de
#'   progresso.
#'
#' @return Invisivel: o caminho completo do ficheiro gravado (\code{character(1)}).
#'
#' @examples
#' \dontrun{
#' gravar_compilacao_sistafe()
#' gravar_compilacao_sistafe(input_folder = "Data/processed", output_folder = "Dataout/compilado")
#' }
#'
#' @importFrom dplyr bind_rows pull
#' @importFrom glue glue
#' @importFrom purrr map set_names list_rbind walk
#' @importFrom readxl read_xlsx
#' @importFrom writexl write_xlsx
#'
#' @export

gravar_compilacao_sistafe <- function(
    input_folder  = "Data/processed",
    output_folder = "Dataout",
    quiet         = TRUE
) {
  msg <- function(...) if (!quiet) message(...)

  if (!base::dir.exists(input_folder)) {
    cli::cli_abort("A pasta de entrada {.path {input_folder}} nao existe.")
  }

  input_folder  <- base::gsub("/$", "", input_folder)
  output_folder <- base::gsub("/$", "", output_folder)

  input_files <- base::list.files(
    path = input_folder, pattern = "^eSISTAFE_.*\\.xlsx$",
    full.names = TRUE, recursive = FALSE
  )

  if (base::length(input_files) == 0) {
    cli::cli_abort("Nenhum ficheiro com o padrao 'eSISTAFE_*.xlsx' encontrado em {.path {input_folder}}.")
  }

  msg(glue::glue("{length(input_files)} ficheiro(s) encontrado(s) em '{input_folder}':"))
  purrr::walk(input_files, ~ msg(glue::glue("  \u2714 {basename(.x)}")))

  df_compiled <- input_files |>
    purrr::set_names(basename) |>
    purrr::map(\(f) readxl::read_xlsx(f)) |>
    purrr::list_rbind()

  ano_min <- df_compiled |> dplyr::pull(ano) |> min(na.rm = TRUE)
  ano_max <- df_compiled |> dplyr::pull(ano) |> max(na.rm = TRUE)
  ano_str <- if (ano_min == ano_max) as.character(ano_min) else glue::glue("{ano_min}-{ano_max}")

  file_name <- glue::glue("eSISTAFE_{ano_str}.xlsx")
  file_path <- base::file.path(output_folder, file_name)

  if (!base::dir.exists(output_folder)) {
    msg(glue::glue("Pasta '{output_folder}' nao encontrada - a criar..."))
    base::dir.create(output_folder, recursive = TRUE)
  }

  if (base::file.exists(file_path)) {
    warning(glue::glue("O ficheiro '{file_name}' ja existe em '{output_folder}' e sera substituido."))
  }

  msg(glue::glue("A guardar ficheiro: {file_path}"))
  writexl::write_xlsx(df_compiled, file_path)
  message(glue::glue(
    "Compilacao eSISTAFE gravada: {file_path} ({nrow(df_compiled)} linhas, {length(input_files)} ficheiro(s))"
  ))

  base::invisible(file_path)
}


#' Compilar ficheiros RazaoCont processados num unico Excel
#'
#' Localiza todos os ficheiros Excel com o padrao \code{"RazaoCont_"} numa
#' pasta de entrada, combina-os num unico tibble e grava o resultado em disco.
#'
#' @param input_folder Caractere. Caminho para a pasta que contem os ficheiros
#'   Excel a compilar. Por padrao \code{"Data/processed"}.
#' @param output_folder Caractere. Caminho para a pasta de destino. Por padrao
#'   \code{"Dataout"}. A pasta e criada automaticamente se nao existir.
#' @param quiet Logico. Se \code{TRUE} (padrao), suprime as mensagens de
#'   progresso.
#'
#' @return Invisivel: o caminho completo do ficheiro gravado (\code{character(1)}).
#'
#' @examples
#' \dontrun{
#' gravar_compilacao_razao_c()
#' gravar_compilacao_razao_c(input_folder = "Data/processed", output_folder = "Dataout/compilado")
#' }
#'
#' @importFrom dplyr bind_rows pull
#' @importFrom glue glue
#' @importFrom purrr map set_names list_rbind walk
#' @importFrom readxl read_xlsx
#' @importFrom writexl write_xlsx
#'
#' @export

gravar_compilacao_razao_c <- function(
    input_folder  = "Data/razao_cont",
    output_folder = "Dataout",
    quiet         = TRUE
) {
  msg <- function(...) if (!quiet) message(...)

  if (!base::dir.exists(input_folder)) {
    cli::cli_abort("A pasta de entrada {.path {input_folder}} nao existe.")
  }

  input_folder  <- base::gsub("/$", "", input_folder)
  output_folder <- base::gsub("/$", "", output_folder)

  input_files <- base::list.files(
    path = input_folder, pattern = "^RazaoCont_.*\\.xlsx$",
    full.names = TRUE, recursive = FALSE
  )

  if (base::length(input_files) == 0) {
    cli::cli_abort("Nenhum ficheiro com o padrao 'RazaoCont_*.xlsx' encontrado em {.path {input_folder}}.")
  }

  msg(glue::glue("{length(input_files)} ficheiro(s) encontrado(s) em '{input_folder}':"))
  purrr::walk(input_files, ~ msg(glue::glue("  \u2714 {basename(.x)}")))

  df_compiled <- input_files |>
    purrr::set_names(basename) |>
    purrr::map(\(f) readxl::read_xlsx(f)) |>
    purrr::list_rbind()

  ano_min <- df_compiled |> dplyr::pull(ano) |> min(na.rm = TRUE)
  ano_max <- df_compiled |> dplyr::pull(ano) |> max(na.rm = TRUE)
  ano_str <- if (ano_min == ano_max) as.character(ano_min) else glue::glue("{ano_min}-{ano_max}")

  file_name <- glue::glue("RazaoCont_{ano_str}.xlsx")
  file_path <- base::file.path(output_folder, file_name)

  if (!base::dir.exists(output_folder)) {
    msg(glue::glue("Pasta '{output_folder}' nao encontrada - a criar..."))
    base::dir.create(output_folder, recursive = TRUE)
  }

  if (base::file.exists(file_path)) {
    warning(glue::glue("O ficheiro '{file_name}' ja existe em '{output_folder}' e sera substituido."))
  }

  msg(glue::glue("A guardar ficheiro: {file_path}"))
  writexl::write_xlsx(df_compiled, file_path)
  message(glue::glue(
    "Compilacao RazaoCont gravada: {file_path} ({nrow(df_compiled)} linhas, {length(input_files)} ficheiro(s))"
  ))

  base::invisible(file_path)
}
