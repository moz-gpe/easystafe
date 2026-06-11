#' Adicionar metados ao dataframe e-SISTAFE com lookups descritivos
#'
#' Junta informacao descritiva de UGB, funcao e programa a um dataframe
#' ja processado por \code{processar_extracto_esistafe()}, adicionando
#' colunas de provincia, distrito, ambito, nivel da instituicao, descricao,
#' nivel funcional e tipo de programa. As colunas adicionadas sao reposicionadas
#' imediatamente apos as colunas de identificacao orcamental.
#'
#' @param df Um dataframe processado por \code{processar_extracto_esistafe()}.
#'   Deve conter as colunas \code{ugb_id}, \code{funcao}, \code{programa} e
#'   \code{fr}.
#' @param lookups Uma lista com quatro elementos nomeados:
#' \describe{
#'   \item{ugb}{Dataframe com a tabela de referencia de UGBs. Deve conter
#'     \code{codigo_ugb} como chave de ligacao, mais as colunas
#'     \code{provincia}, \code{distrito}, \code{ambito},
#'     colunas com prefixo \code{adm}, \code{nivel_da_instituicao} e
#'     \code{descricao}.}
#'   \item{funcao}{Dataframe com a tabela de referencia de funcoes. Deve
#'     conter \code{funcao} como chave de ligacao e \code{funcao_nivel}.}
#'   \item{programa}{Dataframe com a tabela de referencia de programas.
#'     Deve conter \code{programa_ambito_fr} como chave de ligacao e
#'     \code{programa_tipo}.}
#' }
#'
#' @return O dataframe \code{df} enriquecido com as colunas descritivas dos
#'   quatro lookups. As colunas de UGB (\code{provincia}, \code{distrito},
#'   \code{ambito}, colunas \code{adm*}, \code{nivel_da_instituicao},
#'   \code{descricao}) e de programa (\code{programa_tipo}) sao posicionadas
#'   apos \code{ced}. A coluna \code{funcao_nivel} e posicionada apos
#'   \code{funcao}.
#'
#' @details
#' A funcao valida a presenca dos tres elementos obrigatorios na lista
#' \code{lookups} antes de executar qualquer join. Se algum elemento estiver
#' ausente, e emitido um \code{stop()} imediato com o nome do elemento em falta.
#'
#' As ligacoes sao feitas por:
#' \itemize{
#'   \item \code{ugb_id == codigo_ugb} para o lookup de UGBs.
#'   \item \code{funcao == funcao} para o lookup de funcoes.
#'   \item Para programas, uma chave e construida internamente e removida
#'     apos o join: \code{programa_ambito_fr} (concatenacao de \code{programa},
#'     \code{ambito} e \code{fr}). Todas as linhas sao ligadas a
#'     \code{lookups$programa} via \code{programa_ambito_fr}.
#' }
#'
#' @examples
#' \dontrun{
#' lookups <- list(
#'   ugb = readxl::read_excel("Data/lookups.xlsx", sheet = "ugb") |>
#'     janitor::clean_names() |>
#'     dplyr::select(codigo_ugb, provincia, distrito, ambito,
#'                   dplyr::starts_with("adm"),
#'                   nivel_da_instituicao, descricao) |>
#'     dplyr::filter(!codigo_ugb == "Total"),
#'   funcao = readxl::read_excel("Data/lookups.xlsx", sheet = "funcao") |>
#'     janitor::clean_names() |>
#'     dplyr::select(funcao, funcao_nivel = classificacao_funcional_por_nivel) |>
#'     dplyr::filter(!is.na(funcao)),
#'   programa = readxl::read_excel("Data/lookups.xlsx", sheet = "programa") |>
#'     janitor::clean_names() |>
#'     dplyr::select(programa_ambito_fr, programa_tipo) |>
#'     dplyr::filter(!is.na(programa_tipo))
#' )
#'
#' df_enriched <- adicionar_lookups_esistafe(df_esistafe, lookups)
#' }
#'
#' @importFrom dplyr left_join join_by mutate select relocate starts_with if_else
#' @importFrom stringr str_c str_sub
#' @importFrom glue glue
#'
#' @export

adicionar_lookups_esistafe <- function(df, lookups) {
  # --- Validar presenca dos elementos obrigatorios ---
  required <- c("ugb", "funcao", "programa", "ced", "ced_2", "ced_3")
  missing <- required[!required %in% names(lookups)]
  if (length(missing) > 0) {
    stop(glue::glue(
      "O seguinte(s) elemento(s) obrigatorio(s) esta(o) ausente(s) da lista 'lookups': ",
      "{paste(missing, collapse = ', ')}."
    ))
  }

  # --- Joins e reposicionamento de colunas ---
  df |>
    dplyr::mutate(
      ced_2 = stringr::str_c(stringr::str_sub(ced, 1, 2), "0000"),
      ced_3 = stringr::str_c(stringr::str_sub(ced, 1, 3), "000")
    ) |>
    dplyr::left_join(lookups$ugb, by = dplyr::join_by(ugb_id == codigo_ugb)) |>
    dplyr::left_join(lookups$ced, by = dplyr::join_by(ced == ced)) |>
    dplyr::left_join(
      lookups$ced_2,
      by = dplyr::join_by(ced_2 == ced_2)
    ) |>
    dplyr::left_join(
      lookups$ced_3,
      by = dplyr::join_by(ced_3 == ced_3)
    ) |>
    dplyr::left_join(lookups$funcao, by = dplyr::join_by(funcao == funcao)) |>
    dplyr::mutate(
      programa_ambito_fr = stringr::str_c(programa, ambito, fr, sep = "-")
    ) |>
    dplyr::left_join(
      lookups$programa,
      by = dplyr::join_by(programa_ambito_fr == programa_ambito_fr)
    ) |>
    dplyr::select(-programa_ambito_fr) |>
    dplyr::relocate(funcao_nivel, .after = funcao) |>
    dplyr::relocate(
      ced_2,
      ced_3,
      provincia,
      distrito,
      ambito,
      dplyr::starts_with("adm"),
      nivel_da_instituicao,
      descricao,
      programa_tipo,
      .after = ced
    ) |>
    dplyr::relocate(ced_nome, ced_2_nome, ced_3_nome, .after = ced)
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
    dplyr::relocate(taxa_dolar, taxa_euro, .after = mes)
}
