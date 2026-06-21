.check_unique_key <- function(df, key_col, sheet_name) {
  vals <- df[[key_col]]
  dup_vals <- unique(vals[duplicated(vals)])
  if (length(dup_vals) > 0) {
    stop(glue::glue(
      "A folha '{sheet_name}' tem {length(dup_vals)} valor(es) duplicado(s) em '{key_col}': ",
      "{paste(dup_vals, collapse = ', ')}."
    ))
  }
  df
}


#' Carregar lookups descritivos para enriquecimento de dados 'Demonstrativo Consolidado' do e-SISTAFE
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
#' Apos carregar cada folha, a funcao verifica se a coluna chave tem valores
#' unicos. Se existirem duplicados, e emitido um \code{stop()} com o nome da
#' folha e os valores duplicados, para facilitar a correccao na fonte.
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
  required_sheets <- c(
    "ugb",
    "funcao",
    "programa",
    "ced",
    "ced_2",
    "ced_3",
    "ced_nivel"
  )
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
      dplyr::filter(codigo_ugb != "Total") |>
      .check_unique_key("codigo_ugb", "ugb"),

    funcao = suppressMessages(
      readxl::read_excel(path, sheet = "funcao")
    ) |>
      janitor::clean_names() |>
      dplyr::select(
        funcao,
        funcao_nivel = classificacao_funcional_por_nivel
      ) |>
      dplyr::filter(!is.na(funcao)) |>
      .check_unique_key("funcao", "funcao"),

    programa = suppressMessages(
      readxl::read_excel(path, sheet = "programa")
    ) |>
      janitor::clean_names() |>
      dplyr::select(
        programa_ambito_fr,
        programa_tipo
      ) |>
      dplyr::filter(!is.na(programa_tipo)) |>
      .check_unique_key("programa_ambito_fr", "programa"),

    ced = suppressMessages(
      readxl::read_excel(path, sheet = "ced")
    ) |>
      janitor::clean_names() |>
      dplyr::select(ced, ced_nome) |>
      dplyr::mutate(ced = as.character(ced)) |>
      .check_unique_key("ced", "ced"),

    ced_2 = suppressMessages(
      readxl::read_excel(path, sheet = "ced_2")
    ) |>
      janitor::clean_names() |>
      dplyr::select(ced_2, ced_2_nome) |>
      dplyr::mutate(ced_2 = as.character(ced_2)) |>
      .check_unique_key("ced_2", "ced_2"),

    ced_3 = suppressMessages(
      readxl::read_excel(path, sheet = "ced_3")
    ) |>
      janitor::clean_names() |>
      dplyr::select(ced_3, ced_3_nome) |>
      dplyr::mutate(ced_3 = as.character(ced_3)) |>
      .check_unique_key("ced_3", "ced_3"),

    ced_nivel = suppressMessages(
      readxl::read_excel(path, sheet = "ced_nivel")
    ) |>
      janitor::clean_names() |>
      dplyr::select(ced_3_nome, ced_nivel) |>
      .check_unique_key("ced_3_nome", "ced_nivel")
  )
}


#' Adicionar metadados a um 'tibble' contendo dados do 'Demonstrativo Consolidado' processado
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
#' Todos os joins usam \code{relationship = "many-to-one"} para garantir que
#' as tabelas de lookup nao contem chaves duplicadas. Se uma chave duplicada
#' for detectada no momento do join, e emitido um erro imediato.
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
  required <- c(
    "ugb",
    "funcao",
    "programa",
    "ced",
    "ced_2",
    "ced_3",
    "ced_nivel"
  )
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
    dplyr::left_join(
      lookups$ugb,
      by = dplyr::join_by(ugb_id == codigo_ugb),
      relationship = "many-to-one"
    ) |>
    dplyr::left_join(
      lookups$ced,
      by = dplyr::join_by(ced == ced),
      relationship = "many-to-one"
    ) |>
    dplyr::left_join(
      lookups$ced_2,
      by = dplyr::join_by(ced_2 == ced_2),
      relationship = "many-to-one"
    ) |>
    dplyr::left_join(
      lookups$ced_3,
      by = dplyr::join_by(ced_3 == ced_3),
      relationship = "many-to-one"
    ) |>
    dplyr::left_join(
      lookups$ced_nivel,
      by = dplyr::join_by(ced_3_nome == ced_3_nome),
      relationship = "many-to-one"
    ) |>
    dplyr::left_join(
      lookups$funcao,
      by = dplyr::join_by(funcao == funcao),
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      programa_ambito_fr = stringr::str_c(programa, ambito, fr, sep = "-")
    ) |>
    dplyr::left_join(
      lookups$programa,
      by = dplyr::join_by(programa_ambito_fr == programa_ambito_fr),
      relationship = "many-to-one"
    ) |>
    dplyr::select(-programa_ambito_fr) |>
    dplyr::relocate(funcao_nivel, .after = funcao) |>
    dplyr::relocate(
      ced_nome,
      ced_nivel,
      ced_2,
      ced_2_nome,
      ced_3,
      ced_3_nome,
      provincia,
      distrito,
      ambito,
      dplyr::starts_with("adm"),
      nivel_da_instituicao,
      descricao,
      programa_tipo,
      .after = ced
    )
}


#' Prepare enriched e-SISTAFE output for loading into DuckDB
#'
#' Filters rows to \code{data_tipo == "Valor"} and selects a fixed set of
#' columns from the dataframe produced by the pipeline
#' \code{processar_extracto_esistafe()} |> \code{adicionar_lookups_esistafe()}.
#'
#' @param df A dataframe produced by \code{processar_extracto_esistafe()}
#'   followed by \code{adicionar_lookups_esistafe()}. Must contain the column
#'   \code{data_tipo} and the standard budget identifier and lookup columns.
#'
#' @return A tibble filtered to \code{data_tipo == "Valor"} rows, containing
#'   the following columns when present: \code{reporte_tipo}, \code{periodo},
#'   \code{ugb_id}, \code{funcao}, \code{funcao_nivel}, \code{programa},
#'   \code{fr}, \code{ced}, \code{ced_nome}, \code{ced_nivel},
#'   \code{ced_2_nome}, \code{ced_3_nome}, \code{provincia}, \code{distrito},
#'   \code{ambito}, \code{nivel_da_instituicao}, \code{descricao},
#'   \code{programa_tipo}, and the 11 numeric budget execution columns from
#'   \code{dotacao_inicial} to \code{liq_ad_fundos_via_directa_lafvd}.
#'
#' @details
#' Column selection uses \code{dplyr::any_of()} so the function does not
#' error when optional columns are absent -- for example \code{reporte_tipo},
#' which is only present when \code{include_file_metadata = TRUE} in
#' \code{processar_extracto_esistafe()}.
#'
#' @examples
#' \dontrun{
#' lookups <- carregar_lookups_esistafe("Data/lookups.xlsx")
#'
#' df <- processar_extracto_esistafe(
#'   source_path   = "Data/202602/",
#'   df_ugb_lookup = lookups$ugb
#' ) |>
#'   adicionar_lookups_esistafe(lookups) |>
#'   config_para_duckdb()
#' }
#'
#' @importFrom dplyr filter select any_of
#'
#' @export
config_para_duckdb <- function(df) {
  keep_cols <- c(
    "reporte_tipo",
    "periodo",
    "ugb_id",
    "funcao",
    "funcao_nivel",
    "programa",
    "fr",
    "ced",
    "ced_nome",
    "ced_nivel",
    "ced_2_nome",
    "ced_3_nome",
    "provincia",
    "distrito",
    "ambito",
    "nivel_da_instituicao",
    "descricao",
    "programa_tipo",
    "dotacao_inicial",
    "dotacao_revista",
    "dotacao_actualizada_da",
    "dotacao_disponivel",
    "dotacao_cabimentada_dc",
    "ad_fundos_concedidos_af",
    "despesa_paga_via_directa_dp",
    "ad_fundos_desp_paga_vd_afdp",
    "ad_fundos_liquidados_laf",
    "despesa_liquidada_via_directa_lvd",
    "liq_ad_fundos_via_directa_lafvd"
  )

  df |>
    dplyr::filter(data_tipo == "Valor") |>
    dplyr::select(dplyr::any_of(keep_cols))
}


#' Codificar variaveis de dimensao para modelacao dimensional
#'
#' Substitui variaveis geograficas de texto por identificadores numericos
#' compactos adequados para carregamento em DuckDB ou outras bases de dados
#' relacionais. A funcao e aplicada apos \code{config_para_duckdb()} no
#' pipeline de preparacao de dados.
#'
#' Codifica as seguintes dimensoes:
#' \describe{
#'   \item{provincia_id}{Inteiro de dois digitos derivado de \code{provincia}.
#'     Valores nao reconhecidos ou \code{NA} sao codificados como \code{99L}.
#'     A coluna \code{provincia} original e removida.}
#'   \item{distrito_id}{Inteiro de quatro digitos (prefixo de provincia mais
#'     numero sequencial do distrito) derivado de \code{distrito}. Valores nao
#'     reconhecidos ou \code{NA} sao codificados como \code{9999L}.
#'     A coluna \code{distrito} original e removida.}
#' }
#'
#' @param df Um dataframe, tipicamente o resultado de
#'   \code{config_para_duckdb()}.
#'
#' @return O dataframe de entrada com \code{provincia} e \code{distrito}
#'   substituidas por \code{provincia_id} e \code{distrito_id} (inteiros).
#'
#' @examples
#' \dontrun{
#' lookups <- carregar_lookups_esistafe("Data/lookups.xlsx")
#'
#' df <- processar_extracto_esistafe(
#'   source_path   = "Data/202602/",
#'   df_ugb_lookup = lookups$ugb
#' ) |>
#'   adicionar_lookups_esistafe(lookups) |>
#'   config_para_duckdb() |>
#'   codificar_dimensoes()
#' }
#'
#' @importFrom dplyr mutate select coalesce
#'
#' @export
codificar_dimensoes <- function(df) {
  provincia_map <- c(
    "Cabo Delgado" = 1L,
    "Niassa" = 2L,
    "Nampula" = 3L,
    "Zamb\u00e9zia" = 4L,
    "Tete" = 5L,
    "Manica" = 6L,
    "Sofala" = 7L,
    "Inhambane" = 8L,
    "Gaza" = 9L,
    "Maputo Prov\u00edncia" = 10L,
    "Maputo Cidade" = 11L
  )

  distrito_map <- c(
    "Ancuabe" = 101L,
    "Chi\u00fare" = 102L,
    "Ibo" = 103L,
    "Macomia" = 104L,
    "Mec\u00fafi" = 105L,
    "Meluco" = 106L,
    "Moc\u00edmboa da Praia" = 107L,
    "Montepuez" = 108L,
    "Mueda" = 109L,
    "Namuno" = 110L,
    "Palma" = 111L,
    "Pemba - Metuge" = 112L,
    "Quissanga" = 113L,
    "Cidade de Pemba" = 114L,
    "Balama" = 115L,
    "Muidumbe" = 116L,
    "Nangade" = 117L,
    "Cuamba" = 201L,
    "Majune" = 202L,
    "Mandimba" = 203L,
    "Marrupa" = 204L,
    "Ma\u00faa" = 205L,
    "Mavago" = 206L,
    "Mecanhelas" = 207L,
    "Mecula" = 208L,
    "Lago" = 209L,
    "Chimbunila" = 210L,
    "Lichinga" = 211L,
    "Sanga" = 212L,
    "Muembe" = 213L,
    "N'Gauma" = 214L,
    "Metarica" = 215L,
    "Nipepe" = 216L,
    "Angoche" = 301L,
    "Nacar\u00f4a" = 302L,
    "Ilha de Mo\u00e7ambique" = 303L,
    "Nacala - Porto" = 304L,
    "Malema" = 305L,
    "Meconta" = 306L,
    "Mecub\u00fari" = 307L,
    "Memba" = 308L,
    "Mogincual" = 309L,
    "Mogovolas" = 310L,
    "Moma" = 311L,
    "Monapo" = 312L,
    "Mossuril" = 313L,
    "Muecate" = 314L,
    "Murrupula" = 315L,
    "Nacala - Velha" = 316L,
    "Nampula - Distrito" = 317L,
    "Cidade de Nampula" = 318L,
    "Ribau\u00e9" = 319L,
    "Lalaua" = 320L,
    "Namapa - Er\u00e1ti" = 321L,
    "Larde" = 322L,
    "Liupo" = 323L,
    "Alto Mol\u00f3cu\u00e9" = 401L,
    "Chinde" = 402L,
    "Gil\u00e9" = 403L,
    "Guru\u00e9" = 404L,
    "Ile" = 405L,
    "Lugela" = 406L,
    "Maganja da Costa" = 407L,
    "Milange" = 408L,
    "Mocuba" = 409L,
    "Mopeia" = 410L,
    "Morrumbala" = 411L,
    "Namacurra" = 412L,
    "Namarroi" = 413L,
    "Pebane" = 414L,
    "Cidade de Quelimane" = 415L,
    "Nicoadala" = 416L,
    "Inhassungue" = 417L,
    "Luabo" = 418L,
    "Mocubela" = 419L,
    "Mulevala" = 420L,
    "Molumbo" = 421L,
    "Derre" = 422L,
    "Ang\u00f3nia" = 501L,
    "Cahora Bassa" = 502L,
    "Chi\u00fata" = 503L,
    "Macanga" = 504L,
    "Mar\u00e1via" = 505L,
    "Moatize" = 506L,
    "M\u00e1goe" = 507L,
    "Mutarara" = 508L,
    "Cidade de Tete" = 509L,
    "Zumbo" = 510L,
    "Changara" = 511L,
    "Tsangano" = 512L,
    "Chifunde" = 513L,
    "D\u00f4a" = 514L,
    "Marara" = 515L,
    "B\u00e1ru\u00e9" = 601L,
    "Gondola" = 602L,
    "Cidade de Chimoio" = 603L,
    "Guro" = 604L,
    "Manica" = 605L,
    "Mossurize" = 606L,
    "Sussundenga" = 607L,
    "Tambara" = 608L,
    "Machaze" = 609L,
    "Macossa" = 610L,
    "Macate" = 611L,
    "Vanduzi" = 612L,
    "Cidade da Beira" = 701L,
    "B\u00fazi" = 702L,
    "Caia" = 703L,
    "Chemba" = 704L,
    "Cheringoma" = 705L,
    "Muanza" = 706L,
    "Chibabava" = 707L,
    "Machanga" = 708L,
    "Dondo" = 709L,
    "Nhamatanda" = 710L,
    "Gorongosa" = 711L,
    "Mar\u00edngue" = 712L,
    "Marromeu" = 713L,
    "Govuro" = 801L,
    "Mabote" = 802L,
    "Homo\u00edne" = 803L,
    "Cidade de Inhambane" = 804L,
    "Jangamo" = 805L,
    "Inharrime" = 806L,
    "Massinga" = 807L,
    "Funhalouro" = 808L,
    "Morrumbene" = 809L,
    "Panda" = 810L,
    "Vilankulo" = 811L,
    "Zavala" = 812L,
    "Cidade da Maxixe" = 813L,
    "Inhassoro" = 814L,
    "Bilene - Macia" = 901L,
    "Guij\u00e1" = 902L,
    "Chibuto" = 903L,
    "Chicualacuala" = 904L,
    "Chongoene" = 905L,
    "Chokwe" = 906L,
    "Manjacaze - Dingane" = 907L,
    "Massingir" = 908L,
    "Cidade de Xai-Xai" = 909L,
    "Chigubo" = 910L,
    "Mabalane" = 911L,
    "Massangena" = 912L,
    "Mapai" = 913L,
    "Limpopo" = 914L,
    "Boane" = 1001L,
    "Magude" = 1002L,
    "Manhi\u00e7a" = 1003L,
    "Marracuene" = 1004L,
    "Matutu\u00edne" = 1005L,
    "Moamba" = 1006L,
    "Namaacha" = 1007L,
    "Cidade da Matola" = 1008L,
    "Municipal KaMfumo (DU 1)" = 1101L,
    "Municipal de Nhlamankulo (DU 2)" = 1102L,
    "Municipal KaMaxakeni (DU 3)" = 1103L,
    "Municipal Ka Mavota (DU 4)" = 1104L,
    "Municipal KaMubukwana (DU 5)" = 1105L,
    "Municipal KaTembe" = 1106L,
    "Municipal de Inhaca" = 1107L
  )

  df |>
    dplyr::mutate(
      provincia_id = dplyr::coalesce(provincia_map[provincia], 99L),
      distrito_id = dplyr::coalesce(distrito_map[distrito], 9999L)
    )
}
