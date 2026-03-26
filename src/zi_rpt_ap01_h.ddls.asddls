@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'IV For Vendor Open Items Header'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_RPT_AP01_H
  with parameters p_key_date : abap.dats

  as select from ZI_RPT_AP01_BASE
{
  key Ledger,
  key SourceLedger,
  key CompanyCode,
  key Supplier,

  max(SupplierName) as SupplierName,
  
  max(NetDueDate) as NetDueDate,
  
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
