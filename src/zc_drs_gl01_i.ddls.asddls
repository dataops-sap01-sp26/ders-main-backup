@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View for GL - Items'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define view entity ZC_DRS_GL01_I
  as projection on ZI_DRS_GL01_I 
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
    _Header : redirected to parent ZCR_DRS_GL01
}
