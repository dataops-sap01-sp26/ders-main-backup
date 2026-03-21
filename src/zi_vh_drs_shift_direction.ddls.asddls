@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Shift Direction Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_VH_DRS_SHIFT_DIRECTION as select from I_Language
{
  key cast( '1' as abap.char(1) ) as Value,
      cast( 'Begining of month' as abap.char(30) ) as ShiftDirectionText
}
where
  Language = $session.system_language

union all select from I_Language
{
  key cast( '2' as abap.char(1) ) as Value,
      cast( 'Ending of month' as abap.char(30) ) as ShiftDirectionText
}
where
  Language = $session.system_language
