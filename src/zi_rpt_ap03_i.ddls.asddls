@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'IV for AP Aging Report - Items'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true 

define view entity ZI_RPT_AP03_I
  as select from ZI_RPT_AP03_BASE
 
  association to parent ZI_RPT_AP03 as _Header
    on  $projection.CompanyCode = _Header.CompanyCode
    and $projection.Supplier    = _Header.Supplier
    and $projection.LocalCurrency = _Header.LocalCurrency
{
  key CompanyCode,
  key Supplier,
  key FiscalYear,
  key AccountingDocument,
  key AccountingDocumentItem,

      SupplierName,
      PostingDate,
      DocumentDate,
      NetDueDate,
      AccountingDocumentType,

      @Semantics.amount.currencyCode: 'LocalCurrency'
      OriginalAmount,

      LocalCurrency,

      _Header
}
