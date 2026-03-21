// ═══════════════════════════════════════════════════════════════════════════════
// CONSUMPTION CDS: G/L Account Balances Preview
// PURPOSE: Fiori preview with filters for GL01 report
// NOTE: Regular view (not analytical query) for Service Binding preview
// ═══════════════════════════════════════════════════════════════════════════════
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'G/L Balances - Preview'
@Metadata.ignorePropagatedAnnotations: true

@VDM.viewType: #CONSUMPTION
@Search.searchable: true

@UI.headerInfo: {
  typeName: 'G/L Balance',
  typeNamePlural: 'G/L Balances'
}

@UI.presentationVariant: [{
  sortOrder: [{ by: 'CompanyCode', direction: #ASC }, 
              { by: 'GLAccount', direction: #ASC }],
  visualizations: [{ type: #AS_LINEITEM }]
}]

define view entity ZC_DRS_GL01_PREVIEW
  as select from ZI_DRS_GL01
{
      // ─────────────────────────────────────────────────────────────────────────
      // FILTER FIELDS
      // ─────────────────────────────────────────────────────────────────────────
      @UI.selectionField: [{ position: 10 }]
      @UI.lineItem: [{ position: 10, importance: #HIGH }]
      key CompanyCode,
      
      @UI.selectionField: [{ position: 20 }]
      @UI.lineItem: [{ position: 20, importance: #HIGH }]
      key FiscalYear,
      
      @UI.selectionField: [{ position: 30 }]
      @UI.lineItem: [{ position: 30, importance: #MEDIUM }]
      key FiscalPeriod,
      
      @UI.selectionField: [{ position: 40 }]
      @UI.lineItem: [{ position: 40, importance: #HIGH }]
      @Search.defaultSearchElement: true
      key GLAccount,
      
      @UI.hidden: true
      key Ledger,
      
      // ─────────────────────────────────────────────────────────────────────────
      // DISPLAY FIELDS
      // ─────────────────────────────────────────────────────────────────────────
      @UI.lineItem: [{ position: 50, importance: #HIGH }]
      @Search.defaultSearchElement: true
      GLAccountName,
      
      @UI.lineItem: [{ position: 55, importance: #LOW }]
      ChartOfAccounts,
      
      @UI.lineItem: [{ position: 60, importance: #MEDIUM }]
      LocalCurrency,
      
      // ─────────────────────────────────────────────────────────────────────────
      // MEASURES
      // ─────────────────────────────────────────────────────────────────────────
      @UI.lineItem: [{ position: 70, importance: #HIGH }]
      @Semantics.amount.currencyCode: 'LocalCurrency'
      DebitAmount,
      
      @UI.lineItem: [{ position: 80, importance: #HIGH }]
      @Semantics.amount.currencyCode: 'LocalCurrency'
      CreditAmount,
      
      @UI.lineItem: [{ position: 90, importance: #HIGH }]
      @Semantics.amount.currencyCode: 'LocalCurrency'
      BalanceAmount
}
