@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View for Vendor Open Items'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define view entity ZI_RPT_AP01
  as select from ZI_RPT_AP01_H( p_key_date : $session.system_date )
  association [0..*] to ZI_RPT_AP01_I as _Items on  $projection.Ledger       = _Items.Ledger
                                                and $projection.SourceLedger = _Items.SourceLedger
                                                and $projection.CompanyCode  = _Items.CompanyCode
                                                and $projection.Supplier     = _Items.Supplier
{
  key Ledger,
  key SourceLedger,
  key CompanyCode,
  key Supplier,

      SupplierName,

      @Semantics.amount.currencyCode: 'LocalCurrency'
      TotalOpenAmount,

      LocalCurrency,

      MaxDaysOverdue,

      NetDueDate,

      /* Associations */
      _Items
}
