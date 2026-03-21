@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View for Vendor Open Items'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define root view entity ZC_RPT_VENDOR_OPEN_ITEMS
  as select from ZI_RPT_VENDOR_OPEN_ITEMS_H( p_key_date : $session.system_date )
  association [0..*] to ZC_RPT_VENDOR_OPEN_ITEMS as _Items
    on  $projection.Ledger       = _Items.Ledger
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

      /* Associations */
      _Items
}
