@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View for GL - Items'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define view entity ZC_RPT_GL_ACCOUNT_BALANCES_I
  as projection on ZI_RPT_GL_ACCOUNT_BALANCES_I 
{
    key Ledger,
    key SourceLedger,
    key CompanyCode,
    key FiscalYear,
    key AccountingDocument,
    key LedgerGLLineItem,
    
    ProfitCenter,
    CostCenter,
    GLAccount,
    GLAccountCategory, 
    PostingDate,

    @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
    AmountInCompanyCodeCurrency,

    CompanyCodeCurrency,
    
    DocumentItemText,
    Period,
    
    /* REDIRECT ASSOCIATION */
    _Header : redirected to parent ZC_RPT_GL_ACCOUNT_BALANCES
}
