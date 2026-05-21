#' Carregar lookups descritivos para enriquecimento de dados e-SISTAFE
#'
#' Le e processa as tabelas de referencia de UGBs, funcoes e programas a
#' partir de um ficheiro Excel, devolvendo uma lista nomeada pronta a ser
#' passada a \code{adicionar_lookups_esistafe()}.
#'
#' @param path Um caracter com o caminho completo ou relativo para o ficheiro
#'   Excel que contem as folhas de lookup. Deve conter as folhas \code{"ugb"},
#'   \code{"funcao"} e \code{"programa"}.
#'
#' @return Uma lista nomeada com tres elementos:
#' \describe{
#'   \item{ugb}{Dataframe com colunas \code{codigo_ugb}, \code{provincia},
#'     \code{distrito}, \code{ambito}, colunas com prefixo \code{adm},
#'     \code{nivel_da_instituicao} e \code{descricao}. Linhas com
#'     \code{codigo_ugb == "Total"} sao removidas.}
#'   \item{funcao}{Dataframe com colunas \code{funcao} e \code{funcao_nivel}.
#'     Linhas com \code{funcao} em branco sao removidas.}
#'   \item{programa}{Dataframe com colunas \code{programa} e
#'     \code{programa_tipo}. Linhas com \code{programa_tipo} em branco
#'     sao removidas.}
#' }
#'
#' @details
#' A funcao valida a presenca das tres folhas obrigatorias antes de tentar
#' ler qualquer dado. Se alguma folha estiver ausente, e emitido um
#' \code{stop()} imediato com o nome da folha em falta.
#'
#' A leitura e feita com \code{suppressMessages()} para suprimir os avisos
#' de tipo de coluna emitidos por \code{readxl::read_excel()}.
#'
#' @examples
#' \dontrun{
#' lookups <- carregar_lookups_esistafe("Data/Metadados esistafe.xlsx")
#'
#' # Usar directamente com adicionar_lookups_esistafe()
#' df <- adicionar_lookups_esistafe(df_esistafe, lookups)
#' }
#'
#' @importFrom readxl read_excel excel_sheets
#' @importFrom janitor clean_names
#' @importFrom dplyr select filter starts_with
#'
#' @export

carregar_lookups_esistafe <- function(path) {

  # --- Validar presenca das folhas obrigatorias ---
  required_sheets <- c("ugb", "funcao", "programa")
  available_sheets <- readxl::excel_sheets(path)
  missing_sheets <- required_sheets[!required_sheets %in% available_sheets]
  if (length(missing_sheets) > 0) {
    stop(glue::glue(
      "A(s) seguinte(s) folha(s) obrigatoria(s) nao foi(foram) encontrada(s) em '{basename(path)}': ",
      "{paste(missing_sheets, collapse = ', ')}."
    ))
  }

  # --- Carregar e processar cada lookup ---
  list(
    ugb = suppressMessages(
      readxl::read_excel(path, sheet = "ugb")
    ) |>
      janitor::clean_names() |>
      dplyr::select(
        codigo_ugb,
        provincia,
        distrito,
        ambito,
        dplyr::starts_with("adm"),
        nivel_da_instituicao,
        descricao
      ) |>
      dplyr::filter(codigo_ugb != "Total"),

    funcao = suppressMessages(
      readxl::read_excel(path, sheet = "funcao")
    ) |>
      janitor::clean_names() |>
      dplyr::select(
        funcao,
        funcao_nivel = classificacao_funcional_por_nivel
      ) |>
      dplyr::filter(!is.na(funcao)),

    programa = suppressMessages(
      readxl::read_excel(path, sheet = "programa")
    ) |>
      janitor::clean_names() |>
      dplyr::select(
        programa,
        programa_tipo
      ) |>
      dplyr::filter(!is.na(programa_tipo))
  )
}
