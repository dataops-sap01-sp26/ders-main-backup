@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vendor Interface Entity'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_DRS_VENDORS
  as select from zdrs_vendors
  association to parent ZIR_DRS_SUBSCR as _Subscription on  $projection.SubscrUuid = _Subscription.SubscrUuid
                                                        and $projection.SubscrId   = _Subscription.SubscrId
  association [1..1] to I_Supplier as _SupplierMaster
    on $projection.Vendor = _SupplierMaster.Supplier  
{
  key subscr_uuid as SubscrUuid,
  key subscr_id   as SubscrId,
  key vendor      as Vendor,
      
        
      @Semantics.user.createdBy: true
      created_by  as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at  as CreatedAt,

      /* Associations */
      _Subscription,
      _SupplierMaster
}
