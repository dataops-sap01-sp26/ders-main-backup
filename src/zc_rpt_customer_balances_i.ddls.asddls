@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AR Aging - Item Details'
@Metadata.allowExtensions: true -- Cho phép MDE ghi đè

define view entity ZC_RPT_CUSTOMER_BALANCES_I
  as select from ZI_RPT_CUSTOMER_BALANCES
  
  -- Sửa thành association to parent để đúng chuẩn Header-Item
  association to parent ZC_RPT_CUSTOMER_BALANCES as _Header
    on  $projection.CompanyCode = _Header.CompanyCode
    and $projection.Customer    = _Header.Customer
    and $projection.FiscalYear  = _Header.FiscalYear
    and $projection.PostingDate = _Header.PostingDate
{
  key CompanyCode,
  key Customer,
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
