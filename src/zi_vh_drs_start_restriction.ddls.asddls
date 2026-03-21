@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Start Restriction Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_VH_DRS_START_RESTRICTION as select from I_Language
{
  key cast( 'D' as abap.char(1) ) as Value,
      cast( 'Not process on holiday' as abap.char(30) ) as StartRestrictionText
}
where
  Language = $session.system_language

union all select from I_Language
{
  key cast( 'B' as abap.char(1) ) as Value,
      cast( 'Process before holiday' as abap.char(30) ) as StartRestrictionText
}
where
  Language = $session.system_language

union all select from I_Language
{
  key cast( 'A' as abap.char(1) ) as Value,
      cast( 'Process after holiday' as abap.char(30) ) as StartRestrictionText
}
where
  Language = $session.system_language
union all select from I_Language
{
  key cast( '' as abap.char(1) ) as Value,
      cast( 'No restriction' as abap.char(30) ) as StartRestrictionText
}
where
  Language = $session.system_language
