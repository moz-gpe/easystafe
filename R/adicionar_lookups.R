#' Carregar lookups descritivos para enriquecimento de dados e-SISTAFE
#'
#' Le e processa as tabelas de referencia de UGBs, funcoes e programas a
#' partir de um ficheiro Excel, devolvendo uma lista nomeada pronta a ser
#' passada a \code{adicionar_lookups_esistafe()}.
#'
#' @param path Um caracter com o caminho completo ou relativo para o ficheiro
#'   Excel que contem as folhas de lookup. Deve conter as folhas \code{"ugb"},
#'   \code{"funcao"}, \code{"programa"}, \code{"ced"}, \code{"ced_2"},
#'   \code{"ced_3"} e \code{"ced_nivel"}.
#'
#' @return Uma lista nomeada com oito elementos:
#' \describe{
#'   \item{ugb}{Dataframe com colunas \code{codigo_ugb}, \code{provincia},
#'     \code{distrito}, \code{ambito}, colunas com prefixo \code{adm},
#'     \code{nivel_da_instituicao} e \code{descricao}. Linhas com
#'     \code{codigo_ugb == "Total"} sao removidas.}
#'   \item{funcao}{Dataframe com colunas \code{funcao} e \code{funcao_nivel}.
#'     Linhas com \code{funcao} em branco sao removidas.}
#'   \item{programa}{Dataframe com colunas \code{programa_ambito_fr} e
#'     \code{programa_tipo}. Linhas com \code{programa_tipo} em branco
#'     sao removidas. Usado para anos diferentes de 2025.}
#'   \item{programa2025}{Dataframe com colunas \code{programa_ambito_fr_funcao}
#'     e \code{programa_tipo}. Linhas com \code{programa_tipo} em branco
#'     sao removidas. Usado para o ano 2025.}
#'   \item{ced}{Dataframe com colunas \code{ced} e \code{ced_nome}.}
#'   \item{ced_2}{Dataframe com colunas \code{ced_2} e \code{ced_2_nome}.
#'     Chave de 6 digitos construida com os 2 primeiros digitos do CED mais
#'     \code{"0000"}.}
#'   \item{ced_3}{Dataframe com colunas \code{ced_3} e \code{ced_3_nome}.
#'     Chave de 6 digitos construida com os 3 primeiros digitos do CED mais
#'     \code{"000"}.}
#'   \item{ced_nivel}{Dataframe com colunas \code{ced_3_nome} e
#'     \code{ced_nivel}. Classifica cada agrupamento de nivel 3 do CED com
#'     o seu nivel hierarquico.}
#' }
#'
#' @details
#' A funcao valida a presenca de todas as folhas obrigatorias antes de tentar
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
#' @importFrom dplyr select filter starts_with mutate
#'
#' @export

carregar_lookups_esistafe <- function(path) {

  # --- Validar presenca das folhas obrigatorias ---
  required_sheets <- c("ugb", "funcao", "programa", "ced", "ced_2", "ced_3", "ced_nivel")
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
        programa_ambito_fr,
        programa_tipo
      ) |>
      dplyr::filter(!is.na(programa_tipo)),

    ced = suppressMessages(
      readxl::read_excel(path, sheet = "ced")
    ) |>
      janitor::clean_names() |>
      dplyr::select(ced, ced_nome) |>
      dplyr::mutate(ced = as.character(ced)),

    ced_2 = suppressMessages(
      readxl::read_excel(path, sheet = "ced_2")
    ) |>
      janitor::clean_names() |>
      dplyr::select(ced_2, ced_2_nome) |>
      dplyr::mutate(ced_2 = as.character(ced_2)),

    ced_3 = suppressMessages(
      readxl::read_excel(path, sheet = "ced_3")
    ) |>
      janitor::clean_names() |>
      dplyr::select(ced_3, ced_3_nome) |>
      dplyr::mutate(ced_3 = as.character(ced_3)),

    ced_nivel = suppressMessages(
      readxl::read_excel(path, sheet = "ced_nivel")
    ) |>
      janitor::clean_names() |>
      dplyr::select(ced_3_nome, ced_nivel)
  )
}


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
#'   \item{ced_nivel}{Dataframe com colunas \code{ced_3_nome} e
#'     \code{ced_nivel}. Ligado por \code{ced_3_nome} apos o join do
#'     \code{ced_3}.}
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
  required <- c("ugb", "funcao", "programa", "ced", "ced_2", "ced_3", "ced_nivel")
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
    dplyr::left_join(
      lookups$ced_nivel,
      by = dplyr::join_by(ced_3_nome == ced_3_nome)
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
      ced_nome, ced_nivel, ced_2, ced_2_nome, ced_3, ced_3_nome, ced_4,
      provincia, distrito, ambito,
      dplyr::starts_with("adm"),
      nivel_da_instituicao, descricao, programa_tipo,
      .after = ced
    )
}
