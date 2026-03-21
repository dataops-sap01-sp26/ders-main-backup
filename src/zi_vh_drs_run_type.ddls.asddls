@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Run Type Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_VH_DRS_RUN_TYPE as select from I_Language
{
  key cast( 'I' as abap.char(1) )            as Value,
      cast( 'Immediately' as abap.char(20) ) as RunTypeText
}
where
  Language = $session.system_language

union all select from I_Language
{
  key cast( 'O' as abap.char(1) )     as Value,
      cast( 'Once' as abap.char(20) ) as RunTypeText
}
where
  Language = $session.system_language

union all select from I_Language
{
  key cast( 'P' as abap.char(1) )         as Value,
      cast( 'Periodic' as abap.char(20) ) as RunTypeText
}
where
  Language = $session.system_language
