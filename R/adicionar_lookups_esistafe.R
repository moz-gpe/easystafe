#' Adicionar metados ao dataframe e-SISTAFE com lookups descritivos
#'
#' Junta informacao descritiva de UGB, funcao e programa a um dataframe
#' ja processado por \code{processar_extracto_esistafe()}, adicionando
#' colunas de provincia, distrito, ambito, nivel da instituicao, descricao,
#' nivel funcional e tipo de programa. As colunas adicionadas sao reposicionadas
#' imediatamente apos as colunas de identificacao orcamental.
#'
#' @param df Um dataframe processado por \code{processar_extracto_esistafe()}.
#'   Deve conter as colunas \code{ugb_id}, \code{funcao} e \code{programa}.
#' @param lookups Uma lista com tres elementos nomeados:
#' \describe{
#'   \item{ugb}{Dataframe com a tabela de referencia de UGBs. Deve conter
#'     \code{codigo_ugb} como chave de ligacao, mais as colunas
#'     \code{provincia}, \code{distrito}, \code{ambito},
#'     colunas com prefixo \code{adm}, \code{nivel_da_instituicao} e
#'     \code{descricao}.}
#'   \item{funcao}{Dataframe com a tabela de referencia de funcoes. Deve
#'     conter \code{funcao} como chave de ligacao e \code{funcao_nivel}.}
#'   \item{programa}{Dataframe com a tabela de referencia de programas. Deve
#'     conter \code{programa} como chave de ligacao e \code{programa_tipo}.}
#' }
#'
#' @return O dataframe \code{df} enriquecido com as colunas descritivas dos
#'   tres lookups. As colunas de UGB (\code{provincia}, \code{distrito},
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
#'   \item \code{programa == programa} para o lookup de programas.
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
#'     dplyr::select(programa, programa_tipo) |>
#'     dplyr::filter(!is.na(programa_tipo))
#' )
#'
#' df_enriched <- adicionar_lookups_esistafe(df_esistafe, lookups)
#' }
#'
#' @importFrom dplyr left_join join_by relocate starts_with
#' @importFrom glue glue
#'
#' @export

adicionar_lookups_esistafe <- function(df, lookups) {

  # --- Validar presenca dos elementos obrigatorios ---
  required <- c("ugb", "funcao", "programa")
  missing  <- required[!required %in% names(lookups)]
  if (length(missing) > 0) {
    stop(glue::glue(
      "O seguinte(s) elemento(s) obrigatorio(s) esta(o) ausente(s) da lista 'lookups': ",
      "{paste(missing, collapse = ', ')}."
    ))
  }

  # --- Joins e reposicionamento de colunas ---
  df |>
    dplyr::left_join(lookups$ugb,     by = dplyr::join_by(ugb_id == codigo_ugb)) |>
    dplyr::left_join(lookups$funcao,  by = dplyr::join_by(funcao == funcao))     |>
    dplyr::left_join(lookups$programa, by = dplyr::join_by(programa == programa)) |>
    dplyr::relocate(funcao_nivel, .after = funcao) |>
    dplyr::relocate(
      provincia, distrito, ambito,
      dplyr::starts_with("adm"),
      nivel_da_instituicao, descricao, programa_tipo,
      .after = ced
    )
}
