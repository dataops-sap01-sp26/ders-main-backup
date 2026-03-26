@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'IV for Vendor Balances - Items'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define view entity ZI_RPT_AP02_I as select from ZI_RPT_AP02_BASE
  
  association to parent ZI_RPT_AP02 as _Header
    on  $projection.CompanyCode = _Header.CompanyCode
    and $projection.Supplier    = _Header.Supplier
    and $projection.FiscalYear  = _Header.FiscalYear
    and $projection.PostingDate = _Header.PostingDate
{
  key CompanyCode,
  key Supplier,
  key FiscalYear,
  key AccountingDocument,
  key AccountingDocumentItem,
      PostingDate,
      
      @Semantics.amount.currencyCode: 'LocalCurrency'
      Debit,
      
      @Semantics.amount.currencyCode: 'LocalCurrency'
      Credit,
      
      @Semantics.amount.currencyCode: 'LocalCurrency'
      Amount,
      
      LocalCurrency,

      /* Association */
      _Header
}
