@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Periodic Granularity Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_VH_DRS_PERIODIC_GRANULARITY as select from I_Language
{
  key cast('MI' as abap.char(2) ) as Value,
      cast('Minutes' as abap.char(20) ) as Description
} where
  Language = $session.system_language

union all select from I_Language
{
    key cast('H' as abap.char(2) ) as Value,
      cast('Hours' as abap.char(20) ) as Description
} where
  Language = $session.system_language

union all select from I_Language
{
  key cast('D' as abap.char(2) ) as Value,
      cast('Days' as abap.char(20) ) as Description
} where
  Language = $session.system_language

union all select from I_Language
{
   key cast('W' as abap.char(2) ) as Value,
      cast('Weeks' as abap.char(20) ) as Description
} where
  Language = $session.system_language

union all select from I_Language
{
    key cast('MO' as abap.char(2) ) as Value,
      cast('Months' as abap.char(20) ) as Description
} where
  Language = $session.system_language
  
union all select from I_Language
{
    key cast('WM' as abap.char(2) ) as Value,
      cast('Week-Months' as abap.char(20) ) as Description
} where
  Language = $session.system_language
