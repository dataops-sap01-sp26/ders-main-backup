@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Customer Projection'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true

// ═══════════════════════════════════════════════════════════════════════════════
// CHILD PROJECTION: Customer List - Composition child of Subscription
// ═══════════════════════════════════════════════════════════════════════════════
define view entity ZC_DRS_CUSTOMERS
  as projection on ZI_DRS_CUSTOMERS
{
  key SubscrUuid,
  key SubscrId,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Customer_VH', element: 'Customer' } }]
  key Customer,

      CreatedBy,
      CreatedAt,  

      _CustomerMaster.CustomerName as CustomerName,
      _CustomerMaster.Country      as Country,
      _CustomerMaster.CityName     as City,
      _CustomerMaster.StreetName   as Street,
      _CustomerMaster.PostalCode   as PostalCode,

      /* Associations */
      _Subscription : redirected to parent ZCR_DRS_SUBSCR
}
