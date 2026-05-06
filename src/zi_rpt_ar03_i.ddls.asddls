@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'IV for AR Aging Report - Items'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@Search.searchable: true

define view entity ZI_RPT_AR03_I
  as select from ZI_RPT_AR03_BASE

  association to parent ZI_RPT_AR03 as _Header on  $projection.CompanyCode   = _Header.CompanyCode
                                               and $projection.Customer      = _Header.Customer
                                               and $projection.LocalCurrency = _Header.LocalCurrency
{
  key CompanyCode,
  key Customer,
  key FiscalYear,
  key AccountingDocument,
  key AccountingDocumentItem,

      CustomerName,
      PostingDate,
      DocumentDate,
      NetDueDate,
      AccountingDocumentType,

      @Semantics.amount.currencyCode: 'LocalCurrency'
      OriginalAmount,

      LocalCurrency,

      /* Association */
      _Header
}
