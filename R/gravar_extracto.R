#' Gravar extracto processado do e-SISTAFE em Excel
#'
#' Grava um dataframe processado do e-SISTAFE num ficheiro Excel, construindo
#' automaticamente o nome do ficheiro a partir do ano e mes mais recentes
#' presentes nos dados. Cria a pasta de destino se nao existir.
#'
#' @param df Um dataframe processado contendo pelo menos as colunas \code{ano}
#'   e \code{mes}.
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
#' \code{eSISTAFE_<YYYYMM>.xlsx}, onde \code{YYYY} e o ano mais recente e
#' \code{MM} o mes mais recente presentes no dataframe.
#'
#' Por exemplo: \code{eSISTAFE_202512.xlsx}
#'
#' Se o dataframe abranger varios meses ou anos, e sempre utilizado o valor
#' mais recente para construir o nome do ficheiro.
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
#' @importFrom dplyr pull
#' @importFrom glue glue
#' @importFrom purrr map_int
#' @importFrom stringr str_pad
#' @importFrom writexl write_xlsx
#'
#' @export

gravar_extracto_sistafe <- function(
    df,
    output_folder = "Data/processed/",
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
      "Certifique-se de que o dataframe contem as colunas 'ano' e 'mes'."
    ))
  }

  # --- Remover trailing slash se presente ---
  output_folder <- base::gsub("/$", "", output_folder)

  # --- Construir nome do ficheiro ---
  latest_ano <- df |> dplyr::pull(ano) |> max(na.rm = TRUE)
  latest_mes <- df |>
    dplyr::pull(mes) |>
    purrr::map_int(~ match(.x, c("Janeiro","Fevereiro","Marco","Abril","Maio","Junho",
                                 "Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"))) |>
    max(na.rm = TRUE) |>
    stringr::str_pad(2, pad = "0")

  file_name <- glue::glue("eSISTAFE_{latest_ano}{latest_mes}.xlsx")
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
#' \code{RazaoCont_<YYYYMM>.xlsx}, onde \code{YYYYMM} corresponde ao ano e
#' mes da data final do intervalo presente no atributo \code{date_range_txt}.
#'
#' Por exemplo: \code{RazaoCont_202512.xlsx}
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
    output_folder = "Data/processed",
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
  date_ym <- stringr::str_extract(date_range_txt, "\\d{4}-\\d{2}-\\d{2}_a_(\\d{4}-\\d{2})", group = 1) |>
    stringr::str_remove("-")
  file_name <- glue::glue("RazaoCont_{date_ym}.xlsx")
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
#' ABSA_<YYYYMM>.xlsx
#' # exemplo: ABSA_202602.xlsx
#' }
#'
#' Os valores de \code{ano} e \code{mes} sao extraidos das linhas
#' \code{MOVIMENTO} do dataframe (excluindo as linhas de saldo, que podem ter
#' datas atipicas). Se o dataframe nao contiver movimentos, os valores sao
#' retirados de todas as linhas. E sempre utilizado o ano e mes mais recentes
#' para construir o nome do ficheiro.
#'
#' @examples
#' \dontrun{
#' df_absa <- processar_extracto_absa("Data/razao_cont/2026_02/outro/")
#'
#' # Gravar com as definicoes predefinidas
#' gravar_extracto_absa(df_absa)
#' # -> Dataout/ABSA_202602.xlsx
#'
#' # Pasta de destino personalizada
#' gravar_extracto_absa(df_absa, output_folder = "Dataout/banco")
#' # -> Dataout/banco/ABSA_202602.xlsx
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
