@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View For GL - Items'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_RPT_GL01_I
  as select from I_JournalEntryItem

  association to parent ZIR_RPT_GL01_BASE as _Header on 
        $projection.Ledger       = _Header.Ledger
    and $projection.SourceLedger = _Header.SourceLedger
    and $projection.FiscalYear  = _Header.FiscalYear
    and $projection.Period      = _Header.Period
    and $projection.CompanyCode = _Header.CompanyCode
    and $projection.GLAccount   = _Header.GLAccount
    
{
    key Ledger, 
    key SourceLedger,
    
    key CompanyCode,
    key FiscalYear,
    key AccountingDocument,
    key LedgerGLLineItem,
    ProfitCenter,
    CostCenter,  
    
    FiscalPeriod as Period,
    GLAccount,
    GLAccountType as GLAccountCategory, 
    PostingDate,
    @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
    AmountInCompanyCodeCurrency,
    CompanyCodeCurrency,
    DocumentItemText,
    
    _Header
}
