#' Gravar extracto processado do e-SISTAFE em Excel
#'
#' Grava um dataframe processado do e-SISTAFE num ficheiro Excel, construindo
#' automaticamente o nome do ficheiro a partir dos metadados do relatório
#' (tipo, ano e mês) e da data actual. Cria a pasta de destino se não existir.
#'
#' @param df Um dataframe processado por \code{processar_extracto_sistafe()}
#'   com \code{include_meta = TRUE}. Deve conter as colunas \code{reporte_tipo},
#'   \code{ano} e \code{mes}.
#' @param output_folder Caractere. Caminho para a pasta de destino onde o
#'   ficheiro Excel será gravado. Por padrão \code{"Dataout"}. A pasta é
#'   criada automaticamente se não existir.
#' @param quiet Lógico. Se \code{TRUE} (padrão), as mensagens de progresso
#'   são suprimidas. Se \code{FALSE}, são emitidas mensagens sobre a criação
#'   da pasta e o caminho do ficheiro gravado.
#'
#' @return O caminho completo do ficheiro gravado, retornado de forma invisível.
#'   Pode ser capturado com \code{path <- gravar_extracto_sistafe(df)} para
#'   uso posterior se necessário.
#'
#' @details
#' O nome do ficheiro é construído automaticamente no formato:
#' \code{<reporte_tipo>_<ano>_<mes>_<YYYYMMDD>.xlsx}
#'
#' Por exemplo: \code{Funcionamento_2025_Dezembro_20260320.xlsx}
#'
#' Se o dataframe contiver múltiplos valores para \code{reporte_tipo},
#' \code{ano} ou \code{mes} (por exemplo, quando se combinam vários meses),
#' os valores são concatenados com \code{"-"} no nome do ficheiro.
#'
#' Esta função requer que \code{processar_extracto_sistafe()} tenha sido
#' chamado com \code{include_meta = TRUE}. Se as colunas de metadados
#' estiverem em falta, a função para com uma mensagem de erro informativa.
#'
#' @examples
#' \dontrun{
#' # Gravar com pasta padrão
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

  # --- Extrair valores únicos dos metadados ---
  reporte_tipo <- df |> dplyr::distinct(reporte_tipo) |> dplyr::pull() |> base::paste(collapse = "-")
  ano          <- df |> dplyr::distinct(ano)          |> dplyr::pull() |> base::paste(collapse = "-")
  mes          <- df |> dplyr::distinct(mes)          |> dplyr::pull() |> base::paste(collapse = "-")
  today        <- base::format(base::Sys.Date(), "%Y%m%d")

  # --- Construir nome do ficheiro ---
  file_name <- glue::glue("{reporte_tipo}_{ano}_{mes}_{today}.xlsx")
  file_path <- base::file.path(output_folder, file_name)

  # --- Criar pasta se não existir ---
  if (!base::dir.exists(output_folder)) {
    msg(glue::glue("Pasta '{output_folder}' n\u00e3o encontrada \u2014 a criar..."))
    base::dir.create(output_folder, recursive = TRUE)
  }

  # --- Guardar ficheiro ---
  msg(glue::glue("A guardar ficheiro: {file_path}"))
  writexl::write_xlsx(df, file_path)
  msg("Conclu\u00eddo.")

  # --- Retornar caminho invisível para uso posterior se necessário ---
  base::invisible(file_path)

}
