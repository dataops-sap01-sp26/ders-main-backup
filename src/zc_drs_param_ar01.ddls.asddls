@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AR Report Parameters Projection'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true

// ═══════════════════════════════════════════════════════════════════════════════
// CHILD PROJECTION: AR01 Parameters - Composition child of Subscription
// ═══════════════════════════════════════════════════════════════════════════════
define view entity ZC_DRS_PARAM_AR01 as projection on ZI_DRS_PARAM_AR01
{
    key SubscrUuid,
    key SubscrId,
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCodeStdVH', element: 'CompanyCode' } }]
    CompanyCode,
    
    CustomerFrom,
    CustomerTo,
    
    KeyDate,
    MaxRows,
    
    /* Associations */
    _Subscription : redirected to parent ZCR_DRS_SUBSCR
}
