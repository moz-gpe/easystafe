' Diagnostico de lacunas de lookup apos processamento do e-SISTAFE
#'
#' Detecta e reporta lacunas de enriquecimento no dataframe produzido por
#' \code{processar_extracto_esistafe() |> adicionar_lookups_esistafe()}: casos
#' onde os \emph{left joins} silenciosamente produziram \code{NA} por falta de
#' correspondencia no ficheiro de lookup. Imprime um resumo em portugues
#' com instrucoes de remediacao (qual folha actualizar, por que ordem),
#' e grava um ficheiro Excel em disco com o detalhe de cada lacuna.
#' Tambem apresenta um quadro de completude de UGBs (Funcionamento).
#'
#' @param df Tibble enriquecido, produzido por
#'   \code{processar_extracto_esistafe()} seguido de
#'   \code{adicionar_lookups_esistafe()}. Deve conter as colunas:
#'   \code{funcao}, \code{funcao_nivel}, \code{programa}, \code{ambito},
#'   \code{fr}, \code{programa_tipo}, \code{ced}, \code{ced_nome},
#'   \code{ced_2}, \code{ced_2_nome}, \code{ced_3}, \code{ced_3_nome},
#'   \code{ced_nivel}, \code{dotacao_actualizada_da}, \code{reporte_tipo},
#'   \code{data_tipo}.
#' @param lookups Lista devolvida por \code{\link{carregar_lookups_esistafe}},
#'   carregada a partir da versao actual do ficheiro Excel de lookup.
#' @param lookup_path Caracter. Caminho para o ficheiro
#'   \code{esistafe_dim_lookup.xlsx}; apresentado nas instrucoes de
#'   consola. Quando \code{NULL} (padrao), as mensagens referem o ficheiro
#'   genericamente. Em \code{esistafe_processar.R} passe
#'   \code{lookup_path = metadata_lookup}.
#' @param output_folder Caracter. Pasta de destino do ficheiro Excel de
#'   diagnostico. Criada automaticamente se nao existir. Padrao:
#'   \code{"Dataout/sitrep"}.
#' @param quiet Logico. Se \code{FALSE} (padrao), imprime o resumo na
#'   consola. Se \code{TRUE}, suprime toda a saida mas continua a gravar
#'   o ficheiro Excel e a devolver a lista.
#'
#' @return Uma lista nomeada (invisivelmente), com os seguintes elementos:
#' \describe{
#'   \item{funcao_em_falta}{Tibble com uma linha por codigo \code{funcao}
#'     ausente do lookup. Colunas: \code{funcao},
#'     \code{sugestao_funcao_nivel} (\code{NA} -- analista preenche),
#'     \code{n_linhas}, \code{dotacao_total}, \code{reporte_tipos}.}
#'   \item{programa_em_falta}{Tibble com uma linha por chave composta
#'     \code{programa_ambito_fr} ausente do lookup. Colunas:
#'     \code{programa_ambito_fr}, \code{sugestao_programa_tipo} (\code{NA}),
#'     \code{programa}, \code{ambito}, \code{fr}, \code{n_linhas},
#'     \code{dotacao_total}, \code{reporte_tipos}.}
#'   \item{ced_em_falta}{Tibble com uma linha por codigo CED ausente.
#'     Inclui flags de cascata: \code{ced_3_existe}, \code{ced_nivel_existe}
#'     (\code{NA} se \code{ced_3} tambem e novo), \code{ced_2_existe}, e
#'     colunas \code{sugestao_*} (\code{NA}) para o analista preencher.}
#'   \item{ugb_completude}{Tibble com combinacoes
#'     \code{periodo} x \code{codigo_ugb} que tem lacunas de
#'     completude em Funcionamento. Ver \code{\link{ugb_incompletas_esistafe}}.}
#'   \item{n_afectados}{Tibble-resumo das lacunas de lookup (A/B/C). Colunas:
#'     \code{gap_tipo}, \code{n_gap}, \code{n_linhas}, \code{dotacao_total}.}
#' }
#'
#' @details
#' A funcao trabalha apenas sobre linhas \code{data_tipo == "Valor"}.
#' Para o CED, a cascata de actualizacao segue a ordem:
#' \enumerate{
#'   \item \code{ced} -- sempre.
#'   \item \code{ced_3} -- apenas se \code{ced_3_existe = FALSE}.
#'   \item \code{ced_nivel} -- se \code{ced_3} e novo ou
#'     \code{ced_nivel_existe = FALSE}.
#'   \item \code{ced_2} -- apenas se \code{ced_2_existe = FALSE}.
#' }
#' O ficheiro Excel e gravado apenas quando existe pelo menos uma lacuna
#' (lookup ou completude). Se tudo estiver correcto, nenhum ficheiro e criado.
#'
#' @examples
#' \dontrun{
#' # Apos correr o pipeline ETL (existafe_processar.R), na mesma sessao:
#' gaps <- sitrep_processamento_esistafe(
#'   df          = df_esistafe,
#'   lookups     = lookups,
#'   lookup_path = metadata_lookup
#' )
#'
#' # Inspeccionar lacunas especificas
#' gaps$funcao_em_falta
#' gaps$ced_em_falta
#' gaps$n_afectados
#'
#' # Apos corrigir o ficheiro de lookup, recarregar e verificar novamente
#' lookups     <- carregar_lookups_esistafe(metadata_lookup)
#' df_esistafe <- df_esistafe_raw |> adicionar_lookups_esistafe(lookups)
#' gaps        <- sitrep_processamento_esistafe(df_esistafe, lookups, lookup_path = metadata_lookup)
#' }
#'
#' @seealso \code{\link{verificar_ugb_completude}},
#'   \code{\link{ugb_incompletas_esistafe}},
#'   \code{\link{resumir_processamento_esistafe}}
#'
#' @importFrom dplyr filter mutate summarise group_by relocate left_join select if_else n
#' @importFrom stringr str_c
#' @importFrom glue glue
#' @importFrom tibble tibble
#' @importFrom scales comma
#' @importFrom writexl write_xlsx
#' @importFrom cli cli_h1 cli_rule cli_alert_info cli_alert_success cli_alert_warning
#'
#' @export
sitrep_processamento_esistafe <- function(
    df,
    lookups,
    lookup_path   = NULL,
    output_folder = "Dataout/sitrep",
    quiet         = FALSE
) {

  # --- Validar colunas obrigatorias ---
  required_cols <- c(
    "funcao", "funcao_nivel", "programa", "ambito", "fr", "programa_tipo",
    "ced", "ced_nome", "ced_2", "ced_2_nome", "ced_3", "ced_3_nome", "ced_nivel",
    "dotacao_actualizada_da", "reporte_tipo", "data_tipo"
  )
  missing_cols <- required_cols[!required_cols %in% base::names(df)]
  if (base::length(missing_cols) > 0) {
    stop(glue::glue(
      "A(s) seguinte(s) coluna(s) obrigatoria(s) nao foi(foram) encontrada(s) em 'df': ",
      "{paste(missing_cols, collapse = ', ')}. ",
      "Certifique-se de que 'df' foi produzido por ",
      "processar_extracto_esistafe() |> adicionar_lookups_esistafe()."
    ))
  }

  # Referencia ao ficheiro de lookup para mensagens de consola
  lookup_ref <- if (!base::is.null(lookup_path)) lookup_path else "esistafe_dim_lookup.xlsx"

  # Trabalhar apenas sobre linhas de tipo "Valor"
  df_valor <- dplyr::filter(df, data_tipo == "Valor")

  # --- A. funcao_em_falta ---
  funcao_em_falta <- df_valor |>
    dplyr::filter(base::is.na(funcao_nivel)) |>
    dplyr::group_by(funcao) |>
    dplyr::summarise(
      n_linhas      = dplyr::n(),
      dotacao_total = base::sum(dotacao_actualizada_da, na.rm = TRUE),
      reporte_tipos = base::paste(base::sort(base::unique(reporte_tipo)), collapse = ", "),
      .groups       = "drop"
    ) |>
    dplyr::mutate(sugestao_funcao_nivel = NA_character_) |>
    dplyr::relocate(sugestao_funcao_nivel, .after = funcao)

  # --- B. programa_em_falta ---
  programa_em_falta <- df_valor |>
    dplyr::filter(base::is.na(programa_tipo)) |>
    dplyr::mutate(programa_ambito_fr = stringr::str_c(programa, ambito, fr, sep = "-")) |>
    dplyr::group_by(programa_ambito_fr, programa, ambito, fr) |>
    dplyr::summarise(
      n_linhas      = dplyr::n(),
      dotacao_total = base::sum(dotacao_actualizada_da, na.rm = TRUE),
      reporte_tipos = base::paste(base::sort(base::unique(reporte_tipo)), collapse = ", "),
      .groups       = "drop"
    ) |>
    dplyr::mutate(sugestao_programa_tipo = NA_character_) |>
    dplyr::relocate(sugestao_programa_tipo, .after = programa_ambito_fr)

  # --- C. ced_em_falta (com flags de cascata) ---
  ced_gaps_raw <- df_valor |>
    dplyr::filter(base::is.na(ced_nome)) |>
    dplyr::group_by(ced, ced_3, ced_2) |>
    dplyr::summarise(
      n_linhas      = dplyr::n(),
      dotacao_total = base::sum(dotacao_actualizada_da, na.rm = TRUE),
      .groups       = "drop"
    )

  ced_em_falta <- ced_gaps_raw |>
    dplyr::left_join(
      dplyr::select(lookups$ced_3, ced_3, ced_3_nome),
      by = "ced_3"
    ) |>
    dplyr::mutate(
      ced_3_existe     = ced_3 %in% lookups$ced_3$ced_3,
      ced_nivel_existe = dplyr::if_else(
        ced_3_existe,
        ced_3_nome %in% lookups$ced_nivel$ced_3_nome,
        NA
      ),
      ced_2_existe        = ced_2 %in% lookups$ced_2$ced_2,
      sugestao_ced_nome   = NA_character_,
      sugestao_ced_3_nome = NA_character_,
      sugestao_ced_2_nome = NA_character_,
      sugestao_ced_nivel  = NA_character_
    ) |>
    dplyr::select(-ced_3_nome) |>
    dplyr::relocate(
      ced, ced_3, ced_2,
      ced_3_existe, ced_nivel_existe, ced_2_existe,
      sugestao_ced_nome, sugestao_ced_3_nome, sugestao_ced_2_nome, sugestao_ced_nivel,
      n_linhas, dotacao_total
    )

  # --- D. ugb_completude (reutiliza ugb_incompletas_esistafe) ---
  ugb_completude <- ugb_incompletas_esistafe(df, lookups$ugb)

  # --- E. n_afectados (resumo das lacunas de lookup A/B/C apenas) ---
  n_afectados <- tibble::tibble(
    gap_tipo      = c("funcao_nivel", "programa_tipo", "ced_nome"),
    n_gap         = c(nrow(funcao_em_falta), nrow(programa_em_falta), nrow(ced_em_falta)),
    n_linhas      = c(
      base::sum(funcao_em_falta$n_linhas),
      base::sum(programa_em_falta$n_linhas),
      base::sum(ced_em_falta$n_linhas)
    ),
    dotacao_total = c(
      base::sum(funcao_em_falta$dotacao_total),
      base::sum(programa_em_falta$dotacao_total),
      base::sum(ced_em_falta$dotacao_total)
    )
  )

  # --- Gravar Excel (apenas se existirem lacunas) ---
  tem_lacunas_lookup  <- base::any(n_afectados$n_gap > 0)
  tem_lacunas_ugb     <- nrow(ugb_completude) > 0
  tem_qualquer_lacuna <- tem_lacunas_lookup || tem_lacunas_ugb

  excel_path <- NULL
  if (tem_qualquer_lacuna) {
    output_folder <- base::gsub("/$", "", output_folder)
    if (!base::dir.exists(output_folder)) {
      base::dir.create(output_folder, recursive = TRUE)
    }
    data_hoje  <- base::format(base::Sys.Date(), "%Y-%m-%d")
    excel_path <- base::file.path(output_folder, glue::glue("sitrep_esistafe_{data_hoje}.xlsx"))

    sheets <- base::list()
    if (nrow(funcao_em_falta)   > 0) sheets[["funcao"]]         <- funcao_em_falta
    if (nrow(programa_em_falta) > 0) sheets[["programa"]]       <- programa_em_falta
    if (nrow(ced_em_falta)      > 0) sheets[["ced"]]            <- ced_em_falta
    if (nrow(ugb_completude)    > 0) sheets[["ugb_completude"]] <- ugb_completude

    writexl::write_xlsx(sheets, excel_path)
  }

  # --- Saida de consola ---
  if (!quiet) {
    cli::cli_h1(cli::col_blue(glue::glue("sitrep: lacunas no {base::basename(lookup_ref)}")))

    # [A] funcao_nivel
    cli::cli_rule(left = cli::col_blue("[A] funcao_nivel"))
    if (nrow(funcao_em_falta) == 0) {
      cli::cli_alert_success("Sem lacunas.")
    } else {
      cli::cli_alert_warning(
        "{nrow(funcao_em_falta)} valores em falta no lookup \u00b7 {scales::comma(sum(funcao_em_falta$n_linhas))} linhas \u00b7 MT {scales::comma(sum(funcao_em_falta$dotacao_total), accuracy = 1)}"
      )
      cat(glue::glue(
        "\n  \u27a4 Acc\u00e3o: adicione uma linha por valor em falta",
        "\n    Ficheiro : {lookup_ref}",
        "\n    Folha    : funcao",
        "\n    Colunas  : funcao | classificacao_funcional_por_nivel\n\n"
      ))
    }

    # [B] programa_tipo
    cli::cli_rule(left = cli::col_blue("[B] programa_tipo"))
    if (nrow(programa_em_falta) == 0) {
      cli::cli_alert_success("Sem lacunas.")
    } else {
      cli::cli_alert_warning(
        "{nrow(programa_em_falta)} valores em falta no lookup \u00b7 {scales::comma(sum(programa_em_falta$n_linhas))} linhas \u00b7 MT {scales::comma(sum(programa_em_falta$dotacao_total), accuracy = 1)}"
      )
      cat(glue::glue(
        "\n  \u27a4 Acc\u00e3o: adicione uma linha por valor em falta",
        "\n    Ficheiro : {lookup_ref}",
        "\n    Folha    : programa",
        "\n    Colunas  : programa_ambito_fr | programa_tipo",
        "\n    Nota     : o valor tem o formato 'programa-ambito-fr' (tr\u00eas componentes concatenados com '-')\n\n"
      ))
    }

    # [C] ced_nome
    cli::cli_rule(left = cli::col_blue("[C] ced_nome"))
    if (nrow(ced_em_falta) == 0) {
      cli::cli_alert_success("Sem lacunas.")
    } else {
      cli::cli_alert_warning(
        "{nrow(ced_em_falta)} c\u00f3digo(s) CED em falta \u00b7 {scales::comma(sum(ced_em_falta$n_linhas))} linhas \u00b7 MT {scales::comma(sum(ced_em_falta$dotacao_total), accuracy = 1)}"
      )
      cat(glue::glue(
        "\n  \u27a4 Acc\u00e3o: actualize as folhas abaixo, POR ESTA ORDEM (cascata):",
        "\n    Ficheiro : {lookup_ref}",
        "\n    1. Folha 'ced'       \u2014 sempre                                          \u2014 Colunas: ced | ced_nome",
        "\n    2. Folha 'ced_3'     \u2014 se ced_3_existe = FALSE                        \u2014 Colunas: ced_3 | ced_3_nome",
        "\n    3. Folha 'ced_nivel' \u2014 se ced_3 \u00e9 novo ou ced_nivel_existe = FALSE \u2014 Colunas: ced_3_nome | ced_nivel",
        "\n    4. Folha 'ced_2'     \u2014 se ced_2_existe = FALSE                        \u2014 Colunas: ced_2 | ced_2_nome",
        "\n    Ver ficheiro Excel gravado para os flags de cascata por c\u00f3digo CED.\n\n"
      ))
    }

    # [D] ugb_completude
    cli::cli_rule(left = cli::col_blue("[D] Completude de UGBs (Funcionamento)"))
    if (nrow(ugb_completude) == 0) {
      cli::cli_alert_success(
        "Todas as UGBs do lookup t\u00eam dados de Funcionamento em todos os per\u00edodos."
      )
    } else {
      cli::cli_alert_warning(
        "{nrow(ugb_completude)} combina\u00e7\u00e3o(oes) per\u00edodo \u00d7 UGB com falta de informacao"
      )
    }

    # Relatorio gravado / estado geral
    if (!base::is.null(excel_path)) {
      cli::cli_rule(left = "Relat\u00f3rio gravado")
      cli::cli_alert_info("{excel_path}")
    } else {
      cli::cli_rule(left = "Estado geral")
      cli::cli_alert_success("Sem lacunas detectadas \u2014 nenhum ficheiro gravado.")
    }

    cli::cli_rule()
  }

  base::invisible(base::list(
    funcao_em_falta   = funcao_em_falta,
    programa_em_falta = programa_em_falta,
    ced_em_falta      = ced_em_falta,
    ugb_completude    = ugb_completude,
    n_afectados       = n_afectados
  ))
}
