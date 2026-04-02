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
  required_cols <- c("ano", "mes")
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
  today        <- base::format(base::Sys.Date(), "%Y%m%d")

  # --- Construir nome do ficheiro ---
  ano_num <- df |> dplyr::distinct(ano) |> dplyr::pull() |> base::paste(collapse = "-")
  mes_num <- df |> dplyr::distinct(mes) |> dplyr::pull() |>
    purrr::map_chr(~ stringr::str_pad(
      match(.x, c("Janeiro","Fevereiro","Marco","Abril","Maio","Junho",
                  "Julho","Agosto","Setembro","Outubro","Novembro","Dezembro")),
      2, pad = "0")) |>
    base::paste(collapse = "-")
  file_name <- glue::glue("eSISTAFE_{ano_num}{mes_num}_{today}.xlsx")
  file_path <- base::file.path(output_folder, file_name)

  # --- Criar pasta se nao existir ---
  if (!base::dir.exists(output_folder)) {
    msg(glue::glue("Pasta '{output_folder}' nao encontrada - a criar..."))
    base::dir.create(output_folder, recursive = TRUE)
  }

  # --- Guardar ficheiro ---
  msg(glue::glue("A guardar ficheiro: {file_path}"))
  writexl::write_xlsx(df, file_path)
  message(glue::glue("Ficheiro do e-SISTAFE gravado: {file_path}"))
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
  today   <- base::format(base::Sys.Date(), "%Y%m%d")
  date_ym <- stringr::str_extract(date_range_txt, "\\d{4}-\\d{2}") |>
    stringr::str_remove("-")
  file_name <- glue::glue("RazaoCont_{date_ym}_{today}.xlsx")
  file_path <- base::file.path(output_folder, file_name)

  # --- Criar pasta se nao existir ---
  if (!base::dir.exists(output_folder)) {
    msg(glue::glue("Pasta '{output_folder}' nao encontrada - a criar..."))
    base::dir.create(output_folder, recursive = TRUE)
  }

  # --- Guardar ficheiro ---
  msg(glue::glue("A guardar ficheiro: {file_path}"))
  writexl::write_xlsx(df, file_path)
  message(glue::glue("Ficheiro da Razao Contabilistica gravado: {file_path}"))
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
#' @param df Um dataframe processado por \code{processar_extracto_absa()}.
#'   Deve conter as colunas \code{ano} e \code{mes}.
#' @param output_folder Caractere. Caminho para a pasta de destino onde o
#'   ficheiro Excel sera gravado. Por padrao \code{"Dataout"}. A pasta e
#'   criada automaticamente se nao existir.
#' @param quiet Logico. Se \code{TRUE} (padrao), suprime as mensagens de
#'   progresso. Se \code{FALSE}, sao emitidas mensagens sobre a criacao
#'   da pasta e o caminho do ficheiro gravado. Independentemente deste
#'   parametro, e sempre emitida uma mensagem final com o caminho do
#'   ficheiro gravado.
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

gravar_extracto_absa <- function(
    df,
    output_folder = "Dataout",
    quiet         = TRUE
) {
  # --- Mensagens internas ---
  msg <- function(...) {
    if (!quiet) message(...)
  }

  # --- Verificar que colunas de metadados existem ---
  required_cols <- c("ano", "mes")
  missing_cols  <- base::setdiff(required_cols, base::names(df))
  if (base::length(missing_cols) > 0) {
    stop(glue::glue(
      "Colunas de metadados em falta: {paste(missing_cols, collapse = ', ')}."
    ))
  }

  # --- Remover trailing slash se presente ---
  output_folder <- base::gsub("/$", "", output_folder)

  # --- Extrair ano e mes de linhas MOVIMENTO ---
  df_meta <- if ("tipo" %in% base::names(df)) {
    dplyr::filter(df, tipo == "MOVIMENTO")
  } else {
    df
  }
  if (nrow(df_meta) == 0) df_meta <- df

  # --- Construir nome do ficheiro ---
  today   <- base::format(base::Sys.Date(), "%Y%m%d")
  ano_num <- df_meta |> dplyr::pull(ano) |> stats::na.omit() |> unique() |> sort() |> base::paste(collapse = "-")
  mes_num <- df_meta |> dplyr::pull(mes) |> stats::na.omit() |> unique() |>
    purrr::map_chr(~ stringr::str_pad(
      match(.x, c("Janeiro","Fevereiro","Marco","Abril","Maio","Junho",
                  "Julho","Agosto","Setembro","Outubro","Novembro","Dezembro")),
      2, pad = "0")) |>
    base::paste(collapse = "-")

  if (nchar(ano_num) == 0) ano_num <- "ano_desconhecido"
  if (nchar(mes_num) == 0) mes_num <- "mes_desconhecido"

  file_name <- glue::glue("ABSA_{ano_num}{mes_num}_{today}.xlsx")
  file_path <- base::file.path(output_folder, file_name)

  # --- Criar pasta se nao existir ---
  if (!base::dir.exists(output_folder)) {
    msg(glue::glue("Pasta '{output_folder}' nao encontrada - a criar..."))
    base::dir.create(output_folder, recursive = TRUE)
  }

  # --- Guardar ficheiro ---
  msg(glue::glue("A guardar ficheiro: {file_path}"))
  writexl::write_xlsx(df, file_path)
  message(glue::glue("Ficheiro da ABSA gravado: {file_path}"))
  msg("Concluido.")

  # --- Retornar caminho invisivel para uso posterior ---
  base::invisible(file_path)
}
