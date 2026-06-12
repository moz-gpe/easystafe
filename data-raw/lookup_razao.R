## code to create lookup_razao package data
## run this script to regenerate data/lookup_razao.rda

library(tibble)

lookup_razao <- tribble(
  ~source_file                            , ~descricao                                     , ~provincia              ,
  "CENTRAL EUR.pdf"                       , "Conta 7321000 CUT EUR - MEF"                  , NA                      ,
  "CENTRAL EURO.pdf"                      , "Conta 7321000 CUT EUR - MEF"                  , NA                      ,
  "CENTRAL MT.pdf"                        , "Conta 7321000 CUT MTN - MEF"                  , NA                      ,
  "CENTRAL USD.pdf"                       , "Conta 7321000  CUT USD - MEF"                 , NA                      ,
  "EXTRACTO ABSA BANK MZN.pdf"            , "ABSA BANK MT"                                 , NA                      ,
  "EXTRACTO ABSA BANK MT.pdf"             , "ABSA BANK MT"                                 , NA                      ,
  "EXTRACTO ABSA BANK USD.pdf"            , "ABSA BANK USD"                                , NA                      ,
  "FOREX EUR"                             , "Conta nr.004037601011   EUR  Forex - B.M. "   , NA                      ,
  "FOREX USD"                             , "Conta Especial 004187601014 - USD FOREX B.M." , NA                      ,
  "CABO DELGADO DESCENTRALIZADO.pdf"      , "Cabo Delgado"                                 , "Cabo Delgado"          ,
  "CABO DELGADO.pdf"                      , "Cabo Delgado"                                 , "Cabo Delgado"          ,
  "GAZA DESCENTRALIZADO.pdf"              , "Gaza"                                         , "Gaza"                  ,
  "GAZA.pdf"                              , "Gaza"                                         , "Gaza"                  ,
  "INHAMBANE DESCENTRALIZADO.pdf"         , "Inhambane"                                    , "Inhambane"             ,
  "INHAMBANE.pdf"                         , "Inhambane"                                    , "Inhambane"             ,
  "MANICA DESCENTRALIZADO.pdf"            , "Manica"                                       , "Manica"                ,
  "MANICA.pdf"                            , "Manica"                                       , "Manica"                ,
  "MAPUTO CIDADE.pdf"                     , "Maputo Cidade"                                , "Maputo Cidade"         ,
  "M. PROVINCIA DESCENTRALIZADO.pdf"      , "Maputo Prov\u00edncia"                        , "Maputo Prov\u00edncia" ,
  "MAPUTO PROVINCIA DESCENTRALIZADO .pdf" , "Maputo Prov\u00edncia"                        , "Maputo Prov\u00edncia" ,
  "MAPUTO PROVINCIA DESCETRALIZADO.pdf"   , "Maputo Prov\u00edncia"                        , "Maputo Prov\u00edncia" ,
  "MAPUTO PROVINCIA.pdf"                  , "Maputo Prov\u00edncia"                        , "Maputo Prov\u00edncia" ,
  "NAMPULA DESCENTRALIZADO.pdf"           , "Nampula"                                      , "Nampula"               ,
  "NAMPULA.pdf"                           , "Nampula"                                      , "Nampula"               ,
  "NIASSA DESCENTRALIZADO.pdf"            , "Niassa"                                       , "Niassa"                ,
  "NIASSA.pdf"                            , "Niassa"                                       , "Niassa"                ,
  "SOFALA DESCENTRALIZADO.pdf"            , "Sofala"                                       , "Sofala"                ,
  "SOFALA.pdf"                            , "Sofala"                                       , "Sofala"                ,
  "TETE DESCENTRALIZADO.pdf"              , "Tete"                                         , "Tete"                  ,
  "TETE.pdf"                              , "Tete"                                         , "Tete"                  ,
  "ZAMBEZIA DESCENTRALIZADO.pdf"          , "Zamb\u00e9zia"                                , "Zamb\u00e9zia"         ,
  "ZAMBEZIA.pdf"                          , "Zamb\u00e9zia"                                , "Zamb\u00e9zia"
)

usethis::use_data(lookup_razao, overwrite = TRUE)
