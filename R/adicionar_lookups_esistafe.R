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
#'   \item{programa}{Dataframe com a tabela de referencia de programas para
#'     anos diferentes de 2025. Deve conter \code{programa_ambito_fr} como
#'     chave de ligacao e \code{programa_tipo}.}
#'   \item{programa2025}{Dataframe com a tabela de referencia de programas
#'     para o ano 2025. Deve conter \code{programa_ambito_fr_funcao} como
#'     chave de ligacao e \code{programa_tipo}.}
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
#'   \item Para programas, duas chaves sao construidas internamente e removidas
#'     apos o join: \code{programa_ambito_fr} (concatenacao de \code{programa},
#'     \code{ambito} e \code{fr}) e \code{programa_ambito_fr_funcao}
#'     (concatenacao de \code{programa}, \code{ambito}, \code{fr} e
#'     \code{funcao}). Linhas com \code{ano == 2025} sao ligadas a
#'     \code{lookups$programa2025} via \code{programa_ambito_fr_funcao};
#'     as restantes sao ligadas a \code{lookups$programa} via
#'     \code{programa_ambito_fr}. O \code{programa_tipo} correcto e
#'     seleccionado com \code{if_else} apos ambos os joins.
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
  required <- c("ugb", "funcao", "programa", "programa2025", "ced", "ced_2", "ced_3", "ced_4")
  missing  <- required[!required %in% names(lookups)]
  if (length(missing) > 0) {
    stop(glue::glue(
      "O seguinte(s) elemento(s) obrigatorio(s) esta(o) ausente(s) da lista 'lookups': ",
      "{paste(missing, collapse = ', ')}."
    ))
  }

  # --- Joins e reposicionamento de colunas ---
  df |>
    dplyr::mutate(
      ced_2_temp = stringr::str_c(stringr::str_sub(ced, 1, 2), "0000"),
      ced_3_temp = stringr::str_c(stringr::str_sub(ced, 1, 3), "000"),
      ced_4_temp = stringr::str_c(stringr::str_sub(ced, 1, 4), "00")
    ) |>
    dplyr::left_join(lookups$ugb,    by = dplyr::join_by(ugb_id == codigo_ugb)) |>
    dplyr::left_join(lookups$ced,   by = dplyr::join_by(ced       == ced))       |>
    dplyr::left_join(lookups$ced_2, by = dplyr::join_by(ced_2_temp == ced_2_temp)) |>
    dplyr::left_join(lookups$ced_3, by = dplyr::join_by(ced_3_temp == ced_3_temp)) |>
    dplyr::left_join(lookups$ced_4, by = dplyr::join_by(ced_4_temp == ced_4_temp)) |>
    dplyr::left_join(lookups$funcao, by = dplyr::join_by(funcao == funcao))     |>
    dplyr::mutate(
      programa_ambito_fr        = stringr::str_c(programa, ambito, fr,        sep = "-"),
      programa_ambito_fr_funcao = stringr::str_c(programa, ambito, fr, funcao, sep = "-")
    ) |>
    dplyr::left_join(lookups$programa,     by = dplyr::join_by(programa_ambito_fr        == programa_ambito_fr))        |>
    dplyr::left_join(lookups$programa2025, by = dplyr::join_by(programa_ambito_fr_funcao == programa_ambito_fr_funcao),
                     suffix = c("", "_2025")) |>
    dplyr::mutate(programa_tipo = dplyr::if_else(ano == 2025, programa_tipo_2025, programa_tipo)) |>
    dplyr::select(-programa_ambito_fr, -programa_ambito_fr_funcao, -programa_tipo_2025) |>
    dplyr::relocate(funcao_nivel, .after = funcao) |>
        dplyr::relocate(
      provincia, distrito, ambito,
      dplyr::starts_with("adm"),
      nivel_da_instituicao, descricao, programa_tipo,
      .after = ced
    ) |>
    dplyr::relocate(ced_nome, .after = ced)

}
