@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'GL Report Parameters Projection'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true

// ═══════════════════════════════════════════════════════════════════════════════
// CHILD PROJECTION: GL01 Parameters - Composition child of Subscription
// ═══════════════════════════════════════════════════════════════════════════════
define view entity ZC_DRS_PARAM_GL01 as projection on ZI_DRS_PARAM_GL01
{
    key SubscrUuid,
    key SubscrId,
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCodeStdVH', element: 'CompanyCode' } }]
    CompanyCode,
    
    FiscalYear,
    FiscalPeriod,
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CurrencyStdVH', element: 'Currency' } }]
    Currency,
    
    GlAccount,
    MaxRows,
    
    /* Associations */
    _Subscription : redirected to parent ZC_DRS_SUBSCR
}
