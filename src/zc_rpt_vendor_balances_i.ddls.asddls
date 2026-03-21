@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View for Vendor Balances - Items'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define view entity ZC_RPT_VENDOR_BALANCES_I as select from ZI_RPT_VENDOR_BALANCES
  
  association to parent ZC_RPT_VENDOR_BALANCES as _Header
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
