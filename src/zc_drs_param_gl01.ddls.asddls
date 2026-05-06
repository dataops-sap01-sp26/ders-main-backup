@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'GL Report Parameters Projection'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true

// ═══════════════════════════════════════════════════════════════════════════════
// CHILD PROJECTION: GL01 Parameters - Composition child of Subscription
// ═══════════════════════════════════════════════════════════════════════════════
define view entity ZC_DRS_PARAM_GL01
  as projection on ZI_DRS_PARAM_GL01
{
  key SubscrUuid,
  key SubscrId,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCodeStdVH', element: 'CompanyCode' } }]
      CompanyCode,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_FiscalYear', element: 'FiscalYear' } }]
      FiscalYear,

      FiscalPeriodFr,

      FiscalPeriodTo,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CurrencyStdVH', element: 'Currency' } }]
      Currency,

      @Consumption.valueHelpDefinition: [{
          entity: { name: 'I_GLAccountInCompanyCodeStdVH', element: 'GLAccount' },
          additionalBinding: [{ localElement: 'CompanyCode', element: 'CompanyCode', usage: #FILTER }]
      }]
      GlAccountFr,

      @Consumption.valueHelpDefinition: [{
          entity: { name: 'I_GLAccountInCompanyCodeStdVH', element: 'GLAccount' },
          additionalBinding: [{ localElement: 'CompanyCode', element: 'CompanyCode', usage: #FILTER }]
      }]
      GlAccountTo,


      MaxRows,

      /* Associations */
      _Subscription : redirected to parent ZCR_DRS_SUBSCR
}
