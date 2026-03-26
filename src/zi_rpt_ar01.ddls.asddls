@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AR Aging - Customer Summary'
@Metadata.allowExtensions: true 

define view entity ZI_RPT_AR01
  as select from ZI_DRS_AR01_H( p_key_date : $session.system_date )
  
    composition [0..*] of ZI_RPT_AR01_I as _Items
     
    association [1..1] to ZI_DRS_AR01_TOTAL as _Total
      on  $projection.CompanyCode = _Total.CompanyCode
      and $projection.Ledger = _Total.Ledger
      
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
      
      @Semantics.amount.currencyCode: 'LocalCurrency'
      _Total.CompanyTotalAmount, 
      
      LocalCurrency,

      MaxDaysOverdue,
      
      _Items
}
