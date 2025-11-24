#' Deduplicação de múltiplos extractos do e-SISTAFE com inclusão automática de metadados
#'
#' Esta função aplica \code{processar_esistafe_extracto_unico()} a vários
#' ficheiros de extracto do e-SISTAFE, elimina duplicações ao combinar
#' os resultados e acrescenta metadados extraídos automaticamente
#' do nome de cada ficheiro através de \code{extrair_meta_extracto()}.
#'
#' O processo inclui:
#' * deduplicação após o processamento dos extractos individuais;
#' * extração e anexação automática de metadados (tipo de reporte, datas, mês, ano);
#' * gestão robusta de erros (ficheiros problemáticos não interrompem o fluxo).
#'
#' @param caminhos Vetor com os caminhos completos dos ficheiros a processar.
#' @param lista_ugb Vetor de UGBs válidas a passar para \code{processar_esistafe_extracto_unico()}.
#'
#' @return Um `tibble` consolidado contendo os dados processados de todos os
#' ficheiros, incluindo metadados adicionais.
#'
#' @examples
#' \dontrun{
#' arquivos <- list.files("Data/", pattern = "\\\\.xlsx$", full.names = TRUE)
#' df <- processar_esistafe_extracto(
#'   caminhos   = arquivos,
#'   lista_ugb = c("010100001", "010100003")
#' )
#' }
#'
#' @export

processar_esistafe_extracto <- function(caminhos, lista_ugb) {

  # -----------------------------------------------
  # Safe wrapper for processing individual files
  # -----------------------------------------------
  safe_process <- purrr::possibly(
    .f = ~{

      # Extract metadata using the NEW function
      meta <- extrair_meta_extracto(base::basename(.x))

      # Process file using the renamed main function
      df <- processar_esistafe_extracto_unico(.x, lista_ugb)

      # Attach metadata
      df <- df %>%
        dplyr::mutate(
          source_file   = base::basename(.x),
          fonte_reporte = meta$file_name,
          reporte_tipo  = meta$reporte_tipo,
          data_reporte  = meta$data_reporte,
          data_extraido = meta$data_extraido,
          ano           = meta$ano,
          mes           = meta$mes
        )

      return(df)
    },
    otherwise = dplyr::tibble()
  )

  # -----------------------------------------------
  # Progress bar
  # -----------------------------------------------
  pb <- progress::progress_bar$new(
    total = base::length(caminhos),
    format = "  Processing files [:bar] :percent (:current/:total) eta::eta"
  )

  # -----------------------------------------------
  # Apply processor to each file
  # -----------------------------------------------
  results <- purrr::map_df(caminhos, function(p) {
    pb$tick()
    safe_process(p)
  })

  return(results)
}
