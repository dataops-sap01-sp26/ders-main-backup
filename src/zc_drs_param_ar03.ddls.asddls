@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AR Report Parameters Projection'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true

// ═══════════════════════════════════════════════════════════════════════════════
// CHILD PROJECTION: AR02 Parameters - Composition child of Subscription
// ═══════════════════════════════════════════════════════════════════════════════
define view entity ZC_DRS_PARAM_AR03 as projection on ZI_DRS_PARAM_AR03
{
    key SubscrUuid,
    key SubscrId,
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCodeStdVH', element: 'CompanyCode' } }]
    CompanyCode,
    
    @Consumption.valueHelpDefinition: [
                { entity: {
                  name: 'I_Customer_VH',
                  element: 'Customer'
                },
                additionalBinding: [{
                    localElement: 'CompanyCode',
                    element: 'CompanyCode',
                    usage: #FILTER
                }]
            }]
    CustomerFrom,

    @Consumption.valueHelpDefinition: [
                { entity: {
                  name: 'I_Customer_VH',
                  element: 'Customer'
                },
                additionalBinding: [{
                    localElement: 'CompanyCode',
                    element: 'CompanyCode',
                    usage: #FILTER
                }]
            }]
    CustomerTo,
    
    KeyDate,
    MaxRows,
    /* Associations */
    _Subscription : redirected to parent ZCR_DRS_SUBSCR
}
