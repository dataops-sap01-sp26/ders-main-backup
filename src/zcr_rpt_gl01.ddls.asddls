@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View for GL Account Balances'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define root view entity ZCR_RPT_GL01
  provider contract transactional_query
  as projection on ZIR_RPT_GL01_BASE

{
  key Ledger,

  key SourceLedger,

      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_FiscalYear', element: 'FiscalYear' } }]
  key FiscalYear,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_FiscalPeriodForVariant', element: 'FiscalPeriod' } }]
  key Period,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCode', element: 'CompanyCode' } }]
  key CompanyCode,

      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_GLAccount', element: 'GLAccount' } }]
  key GLAccount,

      @Search.defaultSearchElement: true
      GLAccountName,

      @Semantics.amount.currencyCode: 'LocalCurrency'
      DebitAmount,

      @Semantics.amount.currencyCode: 'LocalCurrency'
      CreditAmount,

      //      @Semantics.amount.currencyCode: 'LocalCurrency'
      //      BalanceAmount,

      @UI.hidden: true
      LocalCurrency,


      //      /* Association */
      _Items : redirected to composition child ZC_RPT_GL01_I
}
