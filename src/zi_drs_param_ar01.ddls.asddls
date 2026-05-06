@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Customer Open Items (Composition Child of Subscription)'
@Metadata.ignorePropagatedAnnotations: true

// ═══════════════════════════════════════════════════════════════════════════════
// CHILD ENTITY: AR01 Parameters - Composition child of Subscription
// Lifecycle managed by parent (cascade delete when Subscription deleted)
// ═══════════════════════════════════════════════════════════════════════════════
define view entity ZI_DRS_PARAM_AR01
  as select from zdrs_param_ar01
  association to parent ZIR_DRS_SUBSCR as _Subscription on  $projection.SubscrUuid = _Subscription.SubscrUuid
                                                        and $projection.SubscrId   = _Subscription.SubscrId
{
  key subscr_uuid   as SubscrUuid,
  key subscr_id     as SubscrId,
      company_code  as CompanyCode,
      customer_from as CustomerFrom,
      customer_to   as CustomerTo,
      key_date      as KeyDate,
      max_rows      as MaxRows,

      /* Associations */
      _Subscription
}
