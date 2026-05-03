@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Project view for AR 02'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true 


define view entity ZI_RPT_AR02
  as select from ZI_RPT_AR02_BASE
  
  association [0..*] to ZI_RPT_AR02_I as _Items
    on  $projection.CompanyCode = _Items.CompanyCode
    and $projection.Customer    = _Items.Customer
    and $projection.FiscalYear  = _Items.FiscalYear
    and $projection.PostingDate = _Items.PostingDate
{
      @Search.defaultSearchElement: true
      @Consumption.filter: { mandatory: true, selectionType: #SINGLE }
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCode', element: 'CompanyCode' } }]
  key CompanyCode,

      @Search.defaultSearchElement: true
      @Consumption.filter: { selectionType: #SINGLE }
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Customer', element: 'Customer' } }]
  key Customer,

      @Consumption.filter: { selectionType: #SINGLE }
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_FiscalYear', element: 'FiscalYear' } }]
  key FiscalYear,

      @Consumption.filter: { selectionType: #INTERVAL }
  key PostingDate,

      CustomerName,
      Address,
      LocalCurrency,

/*    @Semantics.amount.currencyCode: 'LocalCurrency'
      sum( OpeningBalance ) as OpeningBalance,
*/
      @Semantics.amount.currencyCode: 'LocalCurrency'
      sum( Debit )          as Debit,

      @Semantics.amount.currencyCode: 'LocalCurrency'
      sum( Credit )         as Credit,

/*      @Semantics.amount.currencyCode: 'LocalCurrency'
      sum( PeriodActivity ) as PeriodActivity,
*/
/*       @Semantics.amount.currencyCode: 'LocalCurrency'
      sum( ClosingBalance ) as ClosingBalance,
*/
      _Items
}
group by
    CompanyCode,
    Customer,
    FiscalYear,
    PostingDate,
    CustomerName,
    Address,
    LocalCurrency
