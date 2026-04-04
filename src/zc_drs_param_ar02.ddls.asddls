@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AR Report Parameters Projection'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true

// ═══════════════════════════════════════════════════════════════════════════════
// CHILD PROJECTION: AR02 Parameters - Composition child of Subscription
// ═══════════════════════════════════════════════════════════════════════════════
define view entity ZC_DRS_PARAM_AR02 as projection on ZI_DRS_PARAM_AR02
{
    key SubscrUuid,
    key SubscrId,
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCodeStdVH', element: 'CompanyCode' } }]
    CompanyCode,
    
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Customer_VH', element: 'Customer' } }]
    CustomerFrom,

    @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Customer_VH', element: 'Customer' } }]
    CustomerTo,
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'I_FiscalYear', element: 'FiscalYear' } }]
    FiscalYear,
    
    FiscalPeriod,
    PostingDate,
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CurrencyStdVH', element: 'Currency' } }]
    Currency,
    
    MaxRows,
    /* Associations */
    _Subscription : redirected to parent ZCR_DRS_SUBSCR
}
