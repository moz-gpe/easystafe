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





#' Gravar extracto do Razao C processado em Excel
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
