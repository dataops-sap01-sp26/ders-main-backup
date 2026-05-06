@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AR01 - Customer Open Items'
@Metadata.allowExtensions: true

define view entity ZI_RPT_AR01
  as select from ZI_RPT_AR01_H( p_key_date : $session.system_date )

  composition [0..*] of ZI_RPT_AR01_I as _Items

{
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Ledger', element: 'Ledger' } }]
  key Ledger,

  key SourceLedger,

      @Consumption.filter.mandatory: true
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCode', element: 'CompanyCode' } }]
  key CompanyCode,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Customer', element: 'Customer' } }]
  key Customer,

      CustomerName,

      NetDueDate,

      @Semantics.amount.currencyCode: 'LocalCurrency'
      @DefaultAggregation: #SUM
      TotalOpenAmount,

      LocalCurrency,

      MaxDaysOverdue,

      _Items
}
