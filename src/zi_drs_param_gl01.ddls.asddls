@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'GL Report Parameters (Composition Child of Subscription)'
@Metadata.ignorePropagatedAnnotations: true

// ═══════════════════════════════════════════════════════════════════════════════
// CHILD ENTITY: GL01 Parameters - Composition child of Subscription
// Lifecycle managed by parent (cascade delete when Subscription deleted)
// ═══════════════════════════════════════════════════════════════════════════════
define view entity ZI_DRS_PARAM_GL01 as select from zdrs_param_gl01 as ParamGL01
  association to parent ZR_DRS_SUBSCR as _Subscription 
    on $projection.SubscrUuid = _Subscription.SubscrUuid
   and $projection.SubscrId = _Subscription.SubscrId
{
    key subscr_uuid as SubscrUuid,
    key subscr_id as SubscrId,
    company_code as CompanyCode,
    fiscal_year as FiscalYear,
    fiscal_period as FiscalPeriod,
    currency as Currency,
    gl_account as GlAccount,
    max_rows as MaxRows,
    
    /* Associations */
    _Subscription
}
