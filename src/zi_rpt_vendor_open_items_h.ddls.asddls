@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View For Vendor Open Items Header'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_RPT_VENDOR_OPEN_ITEMS_H
  with parameters p_key_date : abap.dats

  as select from ZI_DERS_AP01
{
  key Ledger,
  key SourceLedger,
  key CompanyCode,
  key Supplier,

  max(SupplierName) as SupplierName,

  @Semantics.amount.currencyCode: 'LocalCurrency'
  sum(OpenAmount) as TotalOpenAmount,

  LocalCurrency,

  max(
      case
          when NetDueDate is initial
               or NetDueDate >= $parameters.p_key_date
          then 0
          else dats_days_between(
                  NetDueDate,
                  $parameters.p_key_date
               )
      end
  ) as MaxDaysOverdue

}
group by
  Ledger,
  SourceLedger,
  CompanyCode,
  Supplier,
  LocalCurrency
