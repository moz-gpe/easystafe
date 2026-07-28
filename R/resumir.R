#' Resumo consolidado do processamento de extractos e-SISTAFE
#'
#' Produz um resumo unico depois de todos os periodos terem sido processados e
#' combinados (por exemplo, com \code{purrr::map()} seguido de
#' \code{purrr::list_rbind()}). Substitui as mensagens de completude que eram
#' emitidas repetidamente por cada pasta durante o processamento, apresentando
#' em vez disso um conjunto de tabelas-resumo no fim.
#'
#' @param df O dataframe combinado devolvido pelo processamento de um ou mais
#'   periodos com \code{\link{processar_extracto_esistafe}} (antes ou depois de
#'   \code{\link{adicionar_lookups_esistafe}}). Deve conter pelo menos as colunas
#'   \code{pasta_fonte}, \code{periodo}, \code{reporte_tipo}, \code{ugb_id},
#'   \code{dotacao_actualizada_da} e \code{ad_fundos_desp_paga_vd_afdp}.
#' @param lookup_ugb Dataframe com a tabela de referencia das UGBs de educacao.
#'   Deve conter pelo menos a coluna \code{codigo_ugb}.
#' @param quiet Logico. Se \code{FALSE} (padrao), as tabelas-resumo sao impressas
#'   na consola. Se \code{TRUE}, nada e impresso e apenas a lista de tibbles e
#'   devolvida (invisivelmente).
#'
#' @return Invisivelmente, uma lista nomeada de tibbles:
#'   \itemize{
#'     \item \code{overview}: ficheiros e linhas por periodo.
#'     \item \code{completude}: completude de UGBs (Funcionamento) por periodo.
#'     \item \code{negativos}: correccao de valores negativos por periodo
#'       (\code{NULL} se \code{correct_negatives = FALSE} no processamento).
#'     \item \code{ugb_ausentes}: UGBs do lookup que nao aparecem em nenhum
#'       periodo dos dados.
#'   }
#'
#' @details
#' Todas as metricas sao recuperadas do dataframe combinado (abordagem
#' \emph{post-hoc}). Nota: as UGBs presentes nos ficheiros de origem que foram
#' removidas por nao pertencerem ao sector da educacao (filtragem em
#' \code{processar_extracto_esistafe()}) nao sao recuperaveis a partir do
#' dataframe combinado; \code{ugb_ausentes} reporta apenas o inverso -- UGBs do
#' lookup que nunca aparecem nos dados.
#'
#' @examples
#' \dontrun{
#' lookups <- carregar_lookups_esistafe("Documents/lookup.xlsx")
#'
#' df_esistafe <- paths_esistafe |>
#'   purrr::map(\(path) processar_extracto_esistafe(
#'     source_path   = path,
#'     df_ugb_lookup = lookups$ugb
#'   )) |>
#'   purrr::list_rbind()
#'
#' resumir_processamento_esistafe(df_esistafe, lookups$ugb)
#' }
#'
#' @importFrom dplyr n_distinct summarise group_by ungroup arrange filter mutate distinct pull if_else across all_of n
#' @importFrom tidyr replace_na
#' @importFrom tibble tibble
#' @importFrom scales comma percent
#' @importFrom purrr keep
#' @importFrom cli cli_h1 cli_h2 cli_rule cli_alert_info cli_alert_warning cli_alert_success cli_text
#'
#' @seealso \code{\link{verificar_ugb_completude}}
#' @export
resumir_processamento_esistafe <- function(df, lookup_ugb, quiet = FALSE) {

  has_file_name <- "file_name" %in% names(df)

  # --- A. Periodos e ficheiros -------------------------------------------
  overview <- df |>
    dplyr::group_by(pasta_fonte, periodo) |>
    dplyr::summarise(
      n_ficheiros = if (has_file_name) dplyr::n_distinct(file_name) else NA_integer_,
      n_linhas    = dplyr::n(),
      .groups     = "drop"
    ) |>
    dplyr::arrange(periodo, pasta_fonte)

  n_periodos  <- nrow(overview)
  n_ficheiros <- if (has_file_name) dplyr::n_distinct(df$file_name) else NA_integer_
  n_linhas    <- nrow(df)
  periodo_min <- suppressWarnings(min(df$periodo, na.rm = TRUE))
  periodo_max <- suppressWarnings(max(df$periodo, na.rm = TRUE))

  pastas_sem_formato <- overview |>
    dplyr::filter(is.na(periodo)) |>
    dplyr::pull(pasta_fonte)

  # --- B. Completude de UGBs por periodo ---------------------------------
  completude <- .calcular_ugb_completude(df, lookup_ugb, por_periodo = TRUE) |>
    dplyr::group_by(periodo) |>
    dplyr::summarise(
      n_ugb_lookup  = dplyr::n(),
      n_sem_dotacao = sum(!has_dotacao),
      n_sem_afdp    = sum(!has_afdp),
      ugb_sem_dotacao = paste(sort(codigo_ugb[!has_dotacao]), collapse = ", "),
      ugb_sem_afdp    = paste(sort(codigo_ugb[!has_afdp]),    collapse = ", "),
      .groups       = "drop"
    ) |>
    dplyr::arrange(periodo)

  # --- C. UGBs ausentes (nunca aparecem nos dados) -----------------------
  codigos_lookup <- lookup_ugb |>
    dplyr::distinct(codigo_ugb) |>
    dplyr::mutate(codigo_ugb = as.character(codigo_ugb)) |>
    dplyr::pull(codigo_ugb)
  codigos_dados <- unique(as.character(df$ugb_id))
  codigos_ausentes <- sort(setdiff(codigos_lookup, codigos_dados))
  ugb_ausentes <- tibble::tibble(codigo_ugb = codigos_ausentes)

  # --- D. Correccao de negativos por periodo -----------------------------
  tem_correccao <- "valor_corregido" %in% names(df) &&
    any(df$data_tipo == "Corregido", na.rm = TRUE)

  negativos <- NULL
  if (tem_correccao) {
    neg_cols <- c(
      "dotacao_inicial", "dotacao_revista", "dotacao_actualizada_da",
      "dotacao_disponivel", "dotacao_cabimentada_dc", "ad_fundos_concedidos_af",
      "despesa_paga_via_directa_dp", "ad_fundos_desp_paga_vd_afdp",
      "ad_fundos_liquidados_laf", "despesa_liquidada_via_directa_lvd",
      "liq_ad_fundos_via_directa_lafvd"
    ) |>
      purrr::keep(~ .x %in% names(df))

    total_periodo <- df |>
      dplyr::filter(data_tipo == "Valor") |>
      dplyr::group_by(periodo) |>
      dplyr::summarise(
        total_valor = sum(rowSums(dplyr::across(dplyr::all_of(neg_cols)), na.rm = TRUE), na.rm = TRUE),
        .groups = "drop"
      )

    neg_periodo <- df |>
      dplyr::filter(data_tipo == "Corregido") |>
      dplyr::group_by(periodo) |>
      dplyr::summarise(
        n_ugb_corrigidos = dplyr::n_distinct(ugb_funcao_prog_fr),
        soma_negativos   = abs(sum(rowSums(dplyr::across(dplyr::all_of(neg_cols), ~ pmin(.x, 0)), na.rm = TRUE), na.rm = TRUE)),
        .groups = "drop"
      )

    negativos <- total_periodo |>
      dplyr::left_join(neg_periodo, by = "periodo") |>
      dplyr::mutate(
        n_ugb_corrigidos = tidyr::replace_na(n_ugb_corrigidos, 0L),
        soma_negativos   = tidyr::replace_na(soma_negativos, 0),
        pct_do_total     = dplyr::if_else(
          total_valor != 0,
          scales::percent(soma_negativos / abs(total_valor), accuracy = 0.01),
          "N/A"
        )
      ) |>
      dplyr::arrange(periodo)
  }

  # --- Impressao ---------------------------------------------------------
  if (!quiet) {
    cli::cli_h1("Resumo do processamento e-SISTAFE")
    cli::cli_alert_info("Periodos processados : {n_periodos}")
    cli::cli_alert_info(
      "Ficheiros processados: {if (is.na(n_ficheiros)) 'n/d (file_name removido)' else n_ficheiros}"
    )
    cli::cli_alert_info("Linhas totais        : {scales::comma(n_linhas)}")
    cli::cli_alert_info(
      "Intervalo de datas   : {format(periodo_min)} a {format(periodo_max)}"
    )
    if (length(pastas_sem_formato) > 0) {
      cli::cli_alert_warning(
        "Pastas sem formato YYYYMM (ano/mes/periodo = NA): {paste(pastas_sem_formato, collapse = ', ')}"
      )
    }

    cli::cli_h2("Ficheiros e linhas por periodo")
    print(overview)

    cli::cli_h2("Completude de UGBs (Funcionamento) por periodo")
    print(completude)

    cli::cli_h2("Correccao de valores negativos por periodo")
    if (tem_correccao) {
      print(negativos)
    } else {
      cli::cli_alert_info("Correccao de negativos desactivada (correct_negatives = FALSE).")
    }

    cli::cli_h2("UGBs do lookup ausentes dos dados")
    if (nrow(ugb_ausentes) > 0) {
      cli::cli_alert_warning(
        "{nrow(ugb_ausentes)} UGB(s) no lookup nunca aparecem nos dados: {paste(ugb_ausentes$codigo_ugb, collapse = ', ')}"
      )
    } else {
      cli::cli_alert_success("Todas as UGBs do lookup aparecem nos dados.")
    }
    cli::cli_rule()
  }

  invisible(list(
    overview     = overview,
    completude   = completude,
    negativos    = negativos,
    ugb_ausentes = ugb_ausentes
  ))
}
