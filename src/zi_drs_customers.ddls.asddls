@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Customer Interface Entity'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_DRS_CUSTOMERS
  as select from zdrs_customers
  association to parent ZIR_DRS_SUBSCR as _Subscription on  $projection.SubscrUuid = _Subscription.SubscrUuid
                                                        and $projection.SubscrId   = _Subscription.SubscrId
  association [1..1] to I_Customer as _CustomerMaster
    on $projection.Customer = _CustomerMaster.Customer  
{
  key subscr_uuid   as SubscrUuid,
  key subscr_id     as SubscrId,
  key customer      as Customer,
      

      @Semantics.user.createdBy: true
      created_by    as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at    as CreatedAt,

      /* Associations */
      _Subscription,
      _CustomerMaster
}
