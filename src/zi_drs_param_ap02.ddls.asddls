@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vendor Open Items (Composition Child of Subscription)'
@Metadata.ignorePropagatedAnnotations: true

// ═══════════════════════════════════════════════════════════════════════════════
// CHILD ENTITY: AP02 Parameters - Composition child of Subscription
// Lifecycle managed by parent (cascade delete when Subscription deleted)
// ═══════════════════════════════════════════════════════════════════════════════
define view entity ZI_DRS_PARAM_AP02
  as select from zdrs_param_ap02
  association to parent ZIR_DRS_SUBSCR as _Subscription 
      on  $projection.SubscrUuid = _Subscription.SubscrUuid
      and $projection.SubscrId   = _Subscription.SubscrId
{
  key subscr_uuid  as SubscrUuid,
  key subscr_id    as SubscrId,
      company_code as CompanyCode,
      vendor_from  as VendorFrom,
      vendor_to    as VendorTo,
      fiscal_year  as FiscalYear,
      max_rows     as MaxRows,

      /* Associations */
      _Subscription
}
