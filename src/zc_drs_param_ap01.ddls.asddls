@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AR Report Parameters Projection'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true

// ═══════════════════════════════════════════════════════════════════════════════
// CHILD PROJECTION: AP01 Parameters - Composition child of Subscription
// ═══════════════════════════════════════════════════════════════════════════════
define view entity ZC_DRS_PARAM_AP01
  as projection on ZI_DRS_PARAM_AP01
{
  key SubscrUuid,
  key SubscrId,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCodeStdVH', element: 'CompanyCode' } }]
      CompanyCode,

      @Consumption.valueHelpDefinition: [
          { entity: { 
            name: 'I_Supplier_VH', 
            element: 'Supplier' 
          },
          additionalBinding: [{
              localElement: 'CompanyCode',        
              element: 'CompanyCode',             
              usage: #FILTER                      
          }]
      }]
      VendorFrom,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Supplier_VH', element: 'Supplier' } }]
      VendorTo,


      KeyDate,

      MaxRows,

      /* Associations */
      _Subscription : redirected to parent ZCR_DRS_SUBSCR
}
