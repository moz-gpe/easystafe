#' Recode programa column to programa_tipo
#'
#' @description
#' Adds a \code{programa_tipo} column to a dataframe by matching patterns in the
#' \code{programa} column against known e-SISTAFE programme descriptions. Unmatched
#' values are assigned \code{"Outro"}.
#'
#' @param df A dataframe containing a column named \code{programa}.
#'
#' @return The input dataframe with an additional column \code{programa_tipo} (character).
#'
#' @examples
#' \dontrun{
#'   df_clean <- df |> recode_programa_tipo()
#' }
#'
#' @importFrom dplyr mutate case_when
#' @importFrom stringr str_detect regex
#'
#' @export

recode_programa_tipo <- function(df) {

  df %>%
    dplyr::mutate(
      programa_tipo = dplyr::case_when(

        # ADE - ESG
        stringr::str_detect(programa, stringr::regex("Apoiar Escolas Secund", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("ADE\\s*-\\s*ESG", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("ADE \\* ESG", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("ESG\\s*-\\s*ADE", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("ESG1\\s*-\\s*1\\s*CICLO", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("ESG\\s*-\\s*I\\s*CICLO", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("Ensino Secund\u00e1rio Geral 1 Ciclo", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("ADE Ensino Secundario", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("APOIO DIRECTO PARA AS ESCOLAS SECUNDARIAS", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("Apoiar as Escolas Secundarias atraves do Fundo de Apoio Directo as Escolas", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("APOIAR AS ESCOLAS SECUNDARIAS, ATRAVES DO FUNDO DE APOIO DIRECTO AS ESCOLAS", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("APOIO DIRECTO AS ESCOLAS ESG", ignore_case = TRUE)) ~ "ADE - ESG",

        # ADE - Basica
        stringr::str_detect(programa, stringr::regex("Apoiar as escolas basicas, atraves do fundo de apoio directo as escolas", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("Apoiar Escolas B\u00e1sicas atrav\u00e9s do Fundo do Apoio Directo as Escolas", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("Apoiar Escolas B\u00e1sicas atrav\u00e9s do Fundo  do Apoio Directo as Escolas", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("Apoiar Escolas B\u00e1sicas atrav\u00e9s do Fundo de Apoio Directo as Escolas", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("Apoiar Escolas B\u00e1sicas atrav\u00e9s de Fundo de Apoio directo as Escolas", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("Apoiar Escolas Basicas atraves de Fundo de Apoio Directo as Escolas", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("Apoiar Escolas B\u00e1sicas Atrav\u00e9s de Fundos de Apoio Directo as Escolas", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("APOIAR AS ESCOLAS BASICAS ATRAVES DO FUNDO DE APOIO DIRECTO AS ESCOLAS", ignore_case = TRUE)) ~ "ADE - Basica",

        # ADE Primaria
        stringr::str_detect(programa, stringr::regex("APOIO DIRECTO AS ESCOLA \\(ADE\\)", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("APOIAR AS ESCOLAS PRIMARIAS ATRAVES DO FUNDO DIRECTO AS ESCOLAS", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("APOIO DIRECTO AS ESCOLAS", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("APOIO DIRECTO PARA AS ESCOLAS PRIMARIAS \\(ADE\\)", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("APOIO DIRECTO AS ESCOLAS PRIM\\]ARIAS \\(ADE\\)", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("APOIO DIRECTO A ESCOLAS", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("Apoiar as Escolas Primarias atrav\u00e9s do Fundo Directo as Escolas", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("Apoiar as Escolas Primarias atrav\u00e9s do Fundo de apoio as Escolas", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("APOIO DIRECTO  AS ESCOLAS PRIMARIAS \\(ADE\\)", ignore_case = TRUE)) ~ "ADE Prim\u00e1ria",

        # Supervisao Distrital
        stringr::str_detect(programa, stringr::regex("SUPERVISAO DISTRITAL", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("Supervis\u00e3o Distrital", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("Supervisao das Escolas", ignore_case = TRUE)) ~ "Supervis\u00e3o Distrital",

        # Supervisao Provincial
        stringr::str_detect(programa, stringr::regex("SUPERVISAO PROVINCI", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("Supervis\u00e3o Provincial", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("PROVINCIA PARA A REALIZACAO DA SUPERVISAO", ignore_case = TRUE)) ~ "Supervis\u00e3o Provincial",

        # Controlo Interno
        stringr::str_detect(programa, stringr::regex("Control", ignore_case = TRUE)) ~ "Controlo Interno da Educa\u00e7\u00e3o",

        # Professores
        stringr::str_detect(programa, stringr::regex("Profess", ignore_case = TRUE)) ~ "Capacita\u00e7\u00e3o e Forma\u00e7\u00e3o de Professores",

        # Primeira Infancia
        stringr::str_detect(programa, stringr::regex("Inf", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("Facilita", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("Pilot", ignore_case = TRUE)) ~ "Projecto Piloto da Primeira Inf\u00e2ncia",

        # HIV
        stringr::str_detect(programa, stringr::regex("HIV", ignore_case = TRUE)) ~ "Preven\u00e7\u00e3o e Combate do HIV/SIDA",

        # Livro
        stringr::str_detect(programa, stringr::regex("Livro", ignore_case = TRUE)) ~ "Livro Escolar",

        # Material Informatico
        stringr::str_detect(programa, stringr::regex("Adqui", ignore_case = TRUE)) ~ "Adquirir Material Inform\u00e1ticos",

        # Construcao ESG
        stringr::str_detect(programa, stringr::regex("Constr", ignore_case = TRUE)) &
          stringr::str_detect(programa, stringr::regex("ESG", ignore_case = TRUE)) ~ "Constru\u00e7\u00e3o ESG",

        # Construcao Basica
        stringr::str_detect(programa, stringr::regex("Constr", ignore_case = TRUE)) &
          stringr::str_detect(programa, stringr::regex("Basic", ignore_case = TRUE)) ~ "Constru\u00e7\u00e3o Basica",

        # Construcao Primaria
        (
          stringr::str_detect(programa, stringr::regex("Constr", ignore_case = TRUE)) &
            stringr::str_detect(programa, stringr::regex("ACELER", ignore_case = TRUE))
        ) |
          stringr::str_detect(programa, stringr::regex("Construir e apetrechar escolinhas comunitarias", ignore_case = TRUE)) |
          stringr::str_detect(programa, stringr::regex("CONSTRUIR CENTROS DE APOIO A PRENDIZAGEM NO AMBITO DO PROJECTO MOZLEANING", ignore_case = TRUE)) ~ "Constru\u00e7\u00e3o Prim\u00e1ria",

        # Requalificacao
        stringr::str_detect(programa, stringr::regex("Requ", ignore_case = TRUE)) ~ "Requalifica\u00e7\u00e3o de escolas prim\u00e1rias em basicas",

        # Alimentacao
        stringr::str_detect(programa, stringr::regex("Aliment", ignore_case = TRUE)) ~ "Alimenta\u00e7\u00e3o",

        # Lares
        stringr::str_detect(programa, stringr::regex("Lare", ignore_case = TRUE)) ~ "Fundo de Apoio Alimentar para os Centros Internatos e Lares",

        TRUE ~ "Outro"
      )
    )
}



#' Recodificar variaveis padrao de exportacoes e-SISTAFE
#'
#' @description
#' A wrapper function that detects the presence of known e-SISTAFE columns and
#' applies standard recoding transformations to each one found. Columns not
#' present in the dataframe are silently skipped.
#'
#' Currently handles:
#' \itemize{
#'   \item \code{distrito}: applies title case with lowercase prepositions (de, da, do, dos, das)
#'   \item \code{programa}: recodes to standardised \code{programa_tipo} categories via \code{recode_programa_tipo()}
#' }
#'
#' @param df A dataframe containing one or more standard e-SISTAFE columns.
#'
#' @return The input dataframe with transformations applied to detected columns.
#'   A \code{programa_tipo} column is added if \code{programa} is present.
#'
#' @seealso \code{\link{recode_programa_tipo}}
#'
#' @examples
#' \dontrun{
#'   df_clean <- df |>
#'     dplyr::left_join(ugb_lookup, by = dplyr::join_by(ugb_id == codigo_ugb)) |>
#'     recodificar_esistafe_vars()
#' }
#'
#' @importFrom dplyr mutate
#' @importFrom stringr str_to_title str_replace_all
#'
#' @export

recodificar_esistafe_vars <- function(df) {

  # distrito: title case with lowercase prepositions
  if ("distrito" %in% names(df)) {
    df <- df %>%
      dplyr::mutate(
        distrito = distrito %>%
          stringr::str_to_title() %>%
          stringr::str_replace_all("\\b(De|Da|Do|Dos|Das)\\b", ~ stringr::str_to_lower(.x))
      )
  }

  # programa: recode to programa_tipo
  if ("programa" %in% names(df)) {
    df <- df %>%
      dplyr::mutate(programa_tipo = recode_programa_tipo(programa))
  }

  df
}
