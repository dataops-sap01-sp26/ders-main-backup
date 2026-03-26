@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'IV For Customer Open Items Total'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_DRS_AR01_TOTAL 
as select from I_JournalEntryItem
{
    key Ledger,
    key CompanyCode,
    
    @Semantics.amount.currencyCode: 'LocalCurrency'
  sum( case when DebitCreditCode = 'H' then - AmountInCompanyCodeCurrency
            else AmountInCompanyCodeCurrency 
       end ) as CompanyTotalAmount,
       
  CompanyCodeCurrency as LocalCurrency
}

where FinancialAccountType = 'D'
  and ClearingDate is initial
group by 
  Ledger,
  CompanyCode,
  CompanyCodeCurrency
