#' Gravar extracto processado do e-SISTAFE em Excel
#'
#' Grava um dataframe processado do e-SISTAFE num ficheiro Excel, construindo
#' automaticamente o nome do ficheiro a partir dos metadados do relatorio
#' (tipo, ano e mes) e da data actual. Cria a pasta de destino se nao existir.
#'
#' @param df Um dataframe processado por \code{processar_extracto_sistafe()}
#'   com \code{include_meta = TRUE}. Deve conter as colunas \code{reporte_tipo},
#'   \code{ano} e \code{mes}.
#' @param output_folder Caractere. Caminho para a pasta de destino onde o
#'   ficheiro Excel sera gravado. Por padrao \code{"Dataout"}. A pasta e
#'   criada automaticamente se nao existir.
#' @param quiet Logico. Se \code{TRUE} (padrao), as mensagens de progresso
#'   sao suprimidas. Se \code{FALSE}, sao emitidas mensagens sobre a criacao
#'   da pasta e o caminho do ficheiro gravado.
#'
#' @return O caminho completo do ficheiro gravado, retornado de forma invisivel.
#'   Pode ser capturado com \code{path <- gravar_extracto_sistafe(df)} para
#'   uso posterior se necessario.
#'
#' @details
#' O nome do ficheiro e construido automaticamente no formato:
#' \code{<reporte_tipo>_<ano>_<mes>_<YYYYMMDD>.xlsx}
#'
#' Por exemplo: \code{Funcionamento_2025_Dezembro_20260320.xlsx}
#'
#' Se o dataframe contiver multiplos valores para \code{reporte_tipo},
#' \code{ano} ou \code{mes} (por exemplo, quando se combinam varios meses),
#' os valores sao concatenados com \code{"-"} no nome do ficheiro.
#'
#' Esta funcao requer que \code{processar_extracto_sistafe()} tenha sido
#' chamado com \code{include_meta = TRUE}. Se as colunas de metadados
#' estiverem em falta, a funcao para com uma mensagem de erro informativa.
#'
#' @examples
#' \dontrun{
#' # Gravar com pasta padrao
#' gravar_extracto_sistafe(df)
#'
#' # Gravar numa pasta personalizada
#' gravar_extracto_sistafe(df, output_folder = "Data/processed")
#'
#' # Gravar com mensagens de progresso
#' gravar_extracto_sistafe(df, quiet = FALSE)
#'
#' # Capturar o caminho do ficheiro gravado
#' path <- gravar_extracto_sistafe(df, quiet = FALSE)
#' }
#'
#' @importFrom dplyr distinct pull
#' @importFrom glue glue
#' @importFrom writexl write_xlsx
#'
#' @export

gravar_extracto_sistafe <- function(
    df,
    output_folder = "Dataout",
    quiet         = TRUE
) {
  # --- Mensagens internas ---
  msg <- function(...) {
    if (!quiet) message(...)
  }

  # --- Verificar que colunas de metadados existem ---
  required_cols <- c("reporte_tipo", "ano", "mes")
  missing_cols  <- base::setdiff(required_cols, base::names(df))

  if (base::length(missing_cols) > 0) {
    stop(glue::glue(
      "Colunas de metadados em falta: {paste(missing_cols, collapse = ', ')}. ",
      "Certifique-se de que include_meta = TRUE foi usado ao processar o ficheiro."
    ))
  }

  # --- Remover trailing slash se presente ---
  output_folder <- base::gsub("/$", "", output_folder)

  # --- Extrair valores unicos dos metadados ---
  reporte_tipo <- df |> dplyr::distinct(reporte_tipo) |> dplyr::pull() |> base::paste(collapse = "-")
  ano          <- df |> dplyr::distinct(ano)          |> dplyr::pull() |> base::paste(collapse = "-")
  mes          <- df |> dplyr::distinct(mes)          |> dplyr::pull() |> base::paste(collapse = "-")
  today        <- base::format(base::Sys.Date(), "%Y%m%d")

  # --- Construir nome do ficheiro ---
  file_name <- glue::glue("{reporte_tipo}_{ano}_{mes}_{today}.xlsx")
  file_path <- base::file.path(output_folder, file_name)

  # --- Criar pasta se nao existir ---
  if (!base::dir.exists(output_folder)) {
    msg(glue::glue("Pasta '{output_folder}' nao encontrada - a criar..."))
    base::dir.create(output_folder, recursive = TRUE)
  }

  # --- Guardar ficheiro ---
  msg(glue::glue("A guardar ficheiro: {file_path}"))
  writexl::write_xlsx(df, file_path)
  msg("Concluido.")

  # --- Retornar caminho invisivel para uso posterior se necessario ---
  base::invisible(file_path)
}





#' Gravar extracto da razao contabilistico processado em Excel
#'
#' Grava um dataframe processado por \code{processar_extracto_razao_c()} num
#' ficheiro Excel, construindo automaticamente o nome do ficheiro a partir do
#' intervalo de datas do relatorio e da data actual. Cria a pasta de destino
#' se nao existir.
#'
#' @param df Um tibble processado por \code{processar_extracto_razao_c()}.
#'   Deve conter o atributo \code{date_range_txt} gerado por essa funcao.
#' @param output_folder Caractere. Caminho para a pasta de destino onde o
#'   ficheiro Excel sera gravado. Por padrao \code{"Dataout"}. A pasta e
#'   criada automaticamente se nao existir.
#' @param quiet Logico. Se \code{TRUE} (padrao), as mensagens de progresso
#'   sao suprimidas. Se \code{FALSE}, sao emitidas mensagens sobre a criacao
#'   da pasta e o caminho do ficheiro gravado.
#'
#' @return O caminho completo do ficheiro gravado, retornado de forma invisivel.
#'   Pode ser capturado com \code{path <- gravar_extracto_razao_c(df)} para
#'   uso posterior se necessario.
#'
#' @details
#' O nome do ficheiro e construido automaticamente no formato:
#' \code{Razao_C_<data_inicio>_a_<data_fim>_<YYYYMMDD>.xlsx}
#'
#' Por exemplo: \code{Razao_C_2025-01-01_a_2025-12-31_20260323.xlsx}
#'
#' Se o atributo \code{date_range_txt} nao estiver presente no dataframe
#' (por exemplo, se o objeto foi modificado apos o processamento), o nome
#' do ficheiro usa \code{"sem_datas"} como sufixo.
#'
#' @examples
#' \dontrun{
#' # Gravar com pasta padrao
#' gravar_extracto_razao_c(df_razao)
#'
#' # Gravar numa pasta personalizada
#' gravar_extracto_razao_c(df_razao, output_folder = "Data/processed")
#'
#' # Gravar com mensagens de progresso
#' gravar_extracto_razao_c(df_razao, quiet = FALSE)
#'
#' # Capturar o caminho do ficheiro gravado
#' path <- gravar_extracto_razao_c(df_razao, quiet = FALSE)
#' }
#'
#' @importFrom glue glue
#' @importFrom writexl write_xlsx
#'
#' @export

gravar_extracto_razao_c <- function(
    df,
    output_folder = "Dataout",
    quiet         = TRUE
) {
  # --- Mensagens internas ---
  msg <- function(...) {
    if (!quiet) message(...)
  }

  # --- Recuperar date_range_txt do atributo ---
  date_range_txt <- attr(df, "date_range_txt")

  if (is.null(date_range_txt)) {
    message(
      "Atributo 'date_range_txt' nao encontrado - ",
      "a usar 'sem_datas' no nome do ficheiro."
    )
    date_range_txt <- "sem_datas"
  }

  # --- Remover trailing slash se presente ---
  output_folder <- base::gsub("/$", "", output_folder)

  # --- Construir nome do ficheiro ---
  today     <- base::format(base::Sys.Date(), "%Y%m%d")
  file_name <- glue::glue("Razao-Cont_{date_range_txt}_{today}.xlsx")
  file_path <- base::file.path(output_folder, file_name)

  # --- Criar pasta se nao existir ---
  if (!base::dir.exists(output_folder)) {
    msg(glue::glue("Pasta '{output_folder}' nao encontrada - a criar..."))
    base::dir.create(output_folder, recursive = TRUE)
  }

  # --- Guardar ficheiro ---
  msg(glue::glue("A guardar ficheiro: {file_path}"))
  writexl::write_xlsx(df, file_path)
  msg("Concluido.")

  # --- Retornar caminho invisivel para uso posterior ---
  base::invisible(file_path)
}


#' Gravar Extracto Bancario ABSA em Excel
#'
#' Guarda o tibble devolvido por \code{\link{processar_extracto_absa}} num
#' ficheiro Excel com um nome de ficheiro construido automaticamente a partir
#' dos metadados do proprio dataframe (ano, mes e data de execucao).
#'
#' @param df \code{data.frame} ou \code{tibble}. O objecto devolvido por
#'   \code{\link{processar_extracto_absa}}. Deve conter pelo menos as colunas
#'   \code{ano} e \code{mes}.
#' @param output_path \code{character(1)}. Caminho para a pasta de destino.
#'   A pasta e criada automaticamente se nao existir. Default: \code{"Dataout"}.
#' @param prefix \code{character(1)}. Prefixo do nome de ficheiro. Permite
#'   identificar o tipo de extracto. Default: \code{"extracto_absa"}.
#' @param include_date \code{logical(1)}. Se \code{TRUE}, acrescenta a data de
#'   execucao (\code{YYYYMMDD}) ao nome do ficheiro, evitando sobreescritas
#'   acidentais. Default: \code{TRUE}.
#' @param overwrite \code{logical(1)}. Se \code{FALSE} e o ficheiro ja existir,
#'   a funcao lanca um erro em vez de sobreescrever. Default: \code{FALSE}.
#' @param verbose \code{logical(1)}. Se \code{TRUE}, imprime o caminho
#'   completo do ficheiro gravado. Default: \code{TRUE}.
#'
#' @return Invisivel: o caminho completo do ficheiro gravado (\code{character(1)}).
#'   Permite encadear com \code{|>} se necessario.
#'
#' @details
#' O nome do ficheiro e construido da seguinte forma:
#'
#' \preformatted{
#' <prefix>_<ano>_<mes>_<YYYYMMDD>.xlsx
#' # exemplo: extracto_absa_2026_February_20260401.xlsx
#' }
#'
#' Os valores de \code{ano} e \code{mes} sao extraidos das linhas
#' \code{MOVIMENTO} do dataframe (excluindo as linhas de saldo, que podem ter
#' datas atipicas). Se o dataframe nao contiver movimentos, os valores sao
#' retirados de todas as linhas.
#'
#' @examples
#' \dontrun{
#' df_absa <- processar_extracto_absa("Data/razao_cont/2026_02/outro/")
#'
#' # Gravar com as definicoes predefinidas
#' gravar_extracto_absa(df_absa)
#' # -> Dataout/extracto_absa_2026_February_20260401.xlsx
#'
#' # Pasta de destino personalizada, sem data no nome
#' gravar_extracto_absa(df_absa, output_path = "Dataout/banco", include_date = FALSE)
#' # -> Dataout/banco/extracto_absa_2026_February.xlsx
#' }
#'
#' @importFrom writexl write_xlsx
#' @importFrom dplyr filter pull
#' @export

gravar_extracto_absa <- function(df,
                                 output_path  = "Dataout",
                                 prefix       = "extracto_absa",
                                 include_date = TRUE,
                                 overwrite    = FALSE,
                                 verbose      = TRUE) {

  # --- 0. Validate input -----------------------------------------------------
  stopifnot(
    "df must be a data frame"           = is.data.frame(df),
    "df must contain column 'ano'"      = "ano" %in% names(df),
    "df must contain column 'mes'"      = "mes" %in% names(df),
    "output_path must be a string"      = is.character(output_path) && length(output_path) == 1,
    "prefix must be a string"           = is.character(prefix) && length(prefix) == 1,
    "include_date must be TRUE or FALSE" = is.logical(include_date) && length(include_date) == 1,
    "overwrite must be TRUE or FALSE"   = is.logical(overwrite) && length(overwrite) == 1,
    "verbose must be TRUE or FALSE"     = is.logical(verbose) && length(verbose) == 1
  )

  # --- 1. Extract year and month from MOVIMENTO rows -------------------------
  # Prefer MOVIMENTO rows to avoid atypical dates on SALDO_INICIAL/SALDO_FINAL
  df_meta <- if ("tipo" %in% names(df)) {
    dplyr::filter(df, tipo == "MOVIMENTO")
  } else {
    df
  }

  # Fall back to full df if no MOVIMENTO rows present
  if (nrow(df_meta) == 0) df_meta <- df

  ano_val <- df_meta |> dplyr::pull(ano) |> na.omit() |> unique() |> sort() |> paste(collapse = "-")
  mes_val <- df_meta |> dplyr::pull(mes) |> na.omit() |> unique() |> sort() |> paste(collapse = "-")

  if (nchar(ano_val) == 0) ano_val <- "ano_desconhecido"
  if (nchar(mes_val) == 0) mes_val <- "mes_desconhecido"

  # --- 2. Build filename -----------------------------------------------------
  date_stamp <- if (include_date) paste0("_", format(Sys.Date(), "%Y%m%d")) else ""

  filename <- paste0(prefix, "_", ano_val, "_", mes_val, date_stamp, ".xlsx")
  filepath <- file.path(output_path, filename)

  # --- 3. Create output directory if needed ----------------------------------
  if (!dir.exists(output_path)) {
    dir.create(output_path, recursive = TRUE)
    if (verbose) message("Pasta criada: ", output_path)
  }

  # --- 4. Check for existing file --------------------------------------------
  if (file.exists(filepath) && !overwrite) {
    stop(
      "O ficheiro j\u00e1 existe: ", filepath,
      "\nUse overwrite = TRUE para substituir."
    )
  }

  # --- 5. Write to Excel -----------------------------------------------------
  writexl::write_xlsx(df, filepath)

  if (verbose) message("Ficheiro gravado: ", filepath)

  invisible(filepath)
}

