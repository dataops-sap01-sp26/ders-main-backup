@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Calendar ID Value Help'
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
define view entity ZI_VH_DRS_CALENDAR_ID as select from tfacd
  association [0..*] to I_FactoryCalendarText as _Text on $projection.FactoryCalendar = _Text.FactoryCalendar
{
      @ObjectModel.text.element: ['CalendarName']
      @Search: { defaultSearchElement: true, fuzzinessThreshold: 0.8 }
  key cast( ident as cr_wfcid preserving type )                        as FactoryCalendar,

      @Semantics.text: true
      @Search: { defaultSearchElement: true, ranking: #HIGH }
      // Select 1 language text based on login language of user
      _Text[1:Language = $session.system_language].FactoryCalendarName as CalendarName,

      @Semantics.calendar.year: true
      cast( vjahr as pph_vjahr preserving type )                       as ValidityStartYear,

      @Semantics.calendar.year: true
      cast( bjahr as pph_bjahr preserving type )                       as ValidityEndYear
}
