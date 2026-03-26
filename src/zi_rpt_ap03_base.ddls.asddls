@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View For AP Aging Report'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_RPT_AP03_BASE
  as select from I_JournalEntryItem

  association [0..1] to I_Supplier as _Supplier
      on $projection.Supplier = _Supplier.Supplier

{

    /* ===================== KEY ===================== */
    key CompanyCode,
    
    key FiscalYear,

    key AccountingDocument,

    key AccountingDocumentItem,

    key Ledger,

    /* ===================== DIMENSION ===================== */
    Supplier,

    _Supplier.SupplierName,

    PostingDate,

    DocumentDate,

    NetDueDate,

    AccountingDocumentType,

    CompanyCodeCurrency as LocalCurrency,

    /* ===================== ORIGINAL AMOUNT ===================== */
    @Semantics.amount.currencyCode: 'LocalCurrency'
    @Aggregation.default: #SUM
    cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
        as OriginalAmount,

    /* ===================== AGING DAYS ===================== */
    cast(
        dats_days_between( NetDueDate, $session.system_date )
        as abap.int4
    ) as AgingDays,

    /* ===================== NOT DUE ===================== */
    @Semantics.amount.currencyCode: 'LocalCurrency'
    @Aggregation.default: #SUM
    cast(
        case
            when NetDueDate is not null
             and dats_days_between( NetDueDate, $session.system_date ) < 0
            then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
            else cast( 0 as abap.dec(23,2) )
        end
        as abap.dec(23,2)
    ) as Bucket_NotDue,
    
    /* ===================== BUCKET 0–30 ===================== */
    @Semantics.amount.currencyCode: 'LocalCurrency'
    @Aggregation.default: #SUM
    cast(
        case
            when NetDueDate is not null
             and dats_days_between( NetDueDate, $session.system_date ) between 0 and 30
            then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
            else cast( 0 as abap.dec(23,2) )
        end
        as abap.dec(23,2)
    ) as Bucket_0_30,

    /* ===================== BUCKET 31–60 ===================== */
    @Semantics.amount.currencyCode: 'LocalCurrency'
    @Aggregation.default: #SUM
    cast(
        case
            when NetDueDate is not null
             and dats_days_between( NetDueDate, $session.system_date ) between 31 and 60
            then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
            else cast( 0 as abap.dec(23,2) )
        end
        as abap.dec(23,2)
    ) as Bucket_31_60,

    /* ===================== BUCKET 61–90 ===================== */
    @Semantics.amount.currencyCode: 'LocalCurrency'
    @Aggregation.default: #SUM
    cast(
        case
            when NetDueDate is not null
             and dats_days_between( NetDueDate, $session.system_date ) between 61 and 90
            then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
            else cast( 0 as abap.dec(23,2) )
        end
        as abap.dec(23,2)
    ) as Bucket_61_90,

    /* ===================== BUCKET > 90 ===================== */
    @Semantics.amount.currencyCode: 'LocalCurrency'
    @Aggregation.default: #SUM
    cast(
        case
            when NetDueDate is not null
             and dats_days_between( NetDueDate, $session.system_date ) > 90
            then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
            else cast( 0 as abap.dec(23,2) )
        end
        as abap.dec(23,2)
    ) as Bucket_Over_90

}

where
      Ledger = '0L'
  and Supplier is not null
  and FinancialAccountType = 'K'
  and ClearingAccountingDocument is initial
