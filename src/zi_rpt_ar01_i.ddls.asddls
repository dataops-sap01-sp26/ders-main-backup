@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AR Aging - Item Details'
@Metadata.allowExtensions: true

define view entity ZI_RPT_AR01_I
  as select from ZI_RPT_AR01_BASE

  association to parent ZI_RPT_AR01 as _Header on  $projection.Ledger       = _Header.Ledger
                                               and $projection.SourceLedger = _Header.SourceLedger
                                               and $projection.CompanyCode  = _Header.CompanyCode
                                               and $projection.Customer     = _Header.Customer
{
  key Ledger,
  key SourceLedger,
  key CompanyCode,
  key Customer,
  key AccountingDocument,
  key FiscalYear,
  key LedgerGLLineItem,

      DocumentType,
      PostingDate,
      NetDueDate,

      @Semantics.amount.currencyCode: 'LocalCurrency'
      OpenAmount,

      LocalCurrency,

      case
          when NetDueDate is initial
               or NetDueDate >= $session.system_date
          then 0
          else dats_days_between(
                  NetDueDate,
                  $session.system_date
               )
      end as DaysOverdue,

      /* Association */
      _Header
}
