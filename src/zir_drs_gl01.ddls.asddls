@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View For GL Account Balances'
@Metadata.ignorePropagatedAnnotations: true

define root view entity ZIR_DRS_GL01
  -- Bảng nguồn phải là Journal Entry Item (Dữ liệu kế toán)
  as select from    I_JournalEntryItem      as J 
    
    left outer join I_GLAccountText  as T on  T.GLAccount    = J.GLAccount
                                        and T.Language     = $session.system_language
                                        and T.ChartOfAccounts = J.ChartOfAccounts
                                                                                
    composition [0..*] of ZI_DRS_GL01_I as _Items
    
{  
    key J.Ledger,
    key J.SourceLedger,
    key J.FiscalYear,
    key J.FiscalPeriod as Period,
    key J.CompanyCode, 
    key J.GLAccount,
    
    T.GLAccountName,
    J.CompanyCodeCurrency as LocalCurrency,

    @Semantics.amount.currencyCode: 'LocalCurrency'
    @Aggregation.default: #SUM
    sum( case when J.DebitCreditCode = 'S' 
              then cast( J.AmountInCompanyCodeCurrency as abap.dec(23,2) ) 
              else 0 end ) as DebitAmount,

    @Semantics.amount.currencyCode: 'LocalCurrency'
    @Aggregation.default: #SUM
    sum( case when J.DebitCreditCode = 'H' 
              then cast( J.AmountInCompanyCodeCurrency as abap.dec(23,2) ) 
              else 0 end ) as CreditAmount,

    @Semantics.amount.currencyCode: 'LocalCurrency'
    @Aggregation.default: #SUM
    sum( case when J.DebitCreditCode = 'S' then cast( J.AmountInCompanyCodeCurrency as abap.dec(23,2) )
              when J.DebitCreditCode = 'H' then -cast( J.AmountInCompanyCodeCurrency as abap.dec(23,2) )
              else 0 end ) as BalanceAmount,
    
    _Items          
}
where J.Ledger = '0L' -- Lọc sổ cái chính tại đây


group by
    J.Ledger, 
    J.SourceLedger,
    J.FiscalYear, 
    J.FiscalPeriod, 
    J.CompanyCode, 
    J.GLAccount,
    T.GLAccountName, 
    J.CompanyCodeCurrency
