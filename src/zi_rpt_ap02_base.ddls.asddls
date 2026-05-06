@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View For Vendor Balances'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_RPT_AP02_BASE
  as select from I_JournalEntryItem

  association [0..1] to I_Supplier as _Supplier on $projection.Supplier = _Supplier.Supplier

{

      /* ===================== KEY ===================== */

  key CompanyCode,
  key FiscalYear,

      @UI.lineItem: [{
          position: 5,
          type: #FOR_INTENT_BASED_NAVIGATION,
          semanticObject: 'JournalEntry',
          semanticObjectAction: 'display'
      }]
  key AccountingDocument,
  key AccountingDocumentItem,
  key Ledger,

      /* ===================== SUPPLIER ===================== */
      Supplier,

      _Supplier.SupplierName,

      _Supplier.CityName                                    as Address,

      Supplier                                              as SupplierAccount,

      /* ===================== DATE ===================== */

      PostingDate,

      CompanyCodeCurrency                                   as LocalCurrency,

      /* ===================== AMOUNT ===================== */

      @Aggregation.default: #SUM
      cast( AmountInCompanyCodeCurrency as abap.dec(23,2) ) as Amount,

      /* ===================== OPENING BALANCE ===================== */
      /*
          @Aggregation.default: #SUM
          cast(
              case
                  when PostingDate < $session.system_date
                  then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
                  else cast( 0 as abap.dec(23,2) )
              end
              as abap.dec(23,2)
          ) as OpeningBalance,
      */
      /* ===================== DEBIT ===================== */

      @Aggregation.default: #SUM
      cast(
          case
              when DebitCreditCode = 'S'
              then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
              else cast( 0 as abap.dec(23,2) )
          end
          as abap.dec(23,2)
      )                                                     as Debit,

      /* ===================== CREDIT ===================== */

      @Aggregation.default: #SUM
      cast(
          case
              when DebitCreditCode = 'H'
              then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
              else cast( 0 as abap.dec(23,2) )
          end
          as abap.dec(23,2)
      )                                                     as Credit

      /* ===================== CLOSING ===================== */
      /*
      @Aggregation.default: #SUM
      cast(
          case
              when DebitCreditCode = 'S'
              then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
              when DebitCreditCode = 'H'
              then - cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
              else cast( 0 as abap.dec(23,2) )
          end
          as abap.dec(23,2)
      ) as ClosingBalance,
      */
      /* ===================== PERIOD ACTIVITY ===================== */
      /*
      @Aggregation.default: #SUM
      cast(
          case
              when PostingDate = $session.system_date
              then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
              else cast( 0 as abap.dec(23,2) )
          end
          as abap.dec(23,2)
      ) as PeriodActivity
      */
}
where
      Ledger               = '0L'
  and FinancialAccountType = 'K'
