@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vendors Projection'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true

// ═══════════════════════════════════════════════════════════════════════════════
// CHILD PROJECTION: Vendor List - Composition child of Subscription
// ═══════════════════════════════════════════════════════════════════════════════
define view entity ZC_DRS_VENDORS
  as projection on ZI_DRS_VENDORS
{
  key SubscrUuid,
  key SubscrId,

      @Consumption.valueHelpDefinition: [{
       entity: { name: 'I_Supplier_VH', element: 'Supplier' }, // Dùng Value Help chuẩn
       useForValidation: true
      }]
  key Vendor,

      CreatedBy,
      CreatedAt,



      _SupplierMaster.SupplierName as SupplierName,
      _SupplierMaster.Country      as Country,
      _SupplierMaster.CityName     as City,
      _SupplierMaster.StreetName   as Street,
      _SupplierMaster.PostalCode   as PostalCode,
      /* Associations */
      _Subscription : redirected to parent ZCR_DRS_SUBSCR
}
