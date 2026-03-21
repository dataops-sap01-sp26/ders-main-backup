@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AR Aging - Customer Summary'
@Metadata.allowExtensions: true 

define root view entity ZC_RPT_CUSTOMER_OPEN_ITEMS
  as select from ZI_RPT_CUSTOMER_OPEN_ITEMS_H( p_key_date : $session.system_date )
  
    composition [0..*] of ZC_RPT_CUSTOMER_OPEN_ITEMS_I as _Items

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

      @Semantics.amount.currencyCode: 'LocalCurrency'
      TotalOpenAmount,

      LocalCurrency,

      MaxDaysOverdue, 
      
      _Items
}
