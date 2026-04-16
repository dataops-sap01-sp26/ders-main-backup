@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AR Report Parameters Projection'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true

// ═══════════════════════════════════════════════════════════════════════════════
// CHILD PROJECTION: AP03 Parameters - Composition child of Subscription
// ═══════════════════════════════════════════════════════════════════════════════
define view entity ZC_DRS_PARAM_AP03
  as projection on ZI_DRS_PARAM_AP03
{
  key SubscrUuid,
  key SubscrId,

      @Consumption.valueHelpDefinition: [{
          entity: { name: 'I_CompanyCode', element: 'CompanyCode' }
        }]
      CompanyCode,

      @Consumption.valueHelpDefinition: [{
      entity: { name: 'I_SupplierCompany', element: 'Supplier' },
      additionalBinding: [{
        localElement: 'CompanyCode',
        element: 'CompanyCode',
        usage: #FILTER_AND_RESULT
      }]
      }]
      VendorFrom,

      @Consumption.valueHelpDefinition: [{
      entity: { name: 'I_SupplierCompany', element: 'Supplier' },
      additionalBinding: [{
        localElement: 'CompanyCode',
        element: 'CompanyCode',
        usage: #FILTER_AND_RESULT
      }]
      }]
      VendorTo,

      KeyDate,

      MaxRows,
      /* Associations */
      _Subscription : redirected to parent ZCR_DRS_SUBSCR
}
