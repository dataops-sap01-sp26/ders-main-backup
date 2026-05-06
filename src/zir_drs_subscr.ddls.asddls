@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Subscription Root Entity'
@Metadata.ignorePropagatedAnnotations: false
define root view entity ZIR_DRS_SUBSCR
  as select from zdrs_subscr as Subscription

  // ═══════════════════════════════════════════════════════════════════════════════
  // ASSOCIATIONS: To master data
  // ═══════════════════════════════════════════════════════════════════════════════
  association [0..1] to ZIR_DRS_CATALOG    as _Catalog   on  $projection.ReportId = _Catalog.ReportId

  association [0..*] to ZIR_DRS_JOB_CONFIG as _JobConfig on  $projection.SubscrUuid = _JobConfig.SubscrUuid
                                                         and $projection.SubscrId   = _JobConfig.SubscrId

  // ═══════════════════════════════════════════════════════════════════════════════
  // COMPOSITION: Report-specific parameters (Child entities)
  // Each Subscription can have ONE set of parameters per report type
  // Lifecycle managed by parent (cascade delete)
  // ═══════════════════════════════════════════════════════════════════════════════
  composition [0..1] of ZI_DRS_PARAM_GL01  as _ParamGL01
  composition [0..1] of ZI_DRS_PARAM_AR01  as _ParamAR01
  composition [0..1] of ZI_DRS_PARAM_AR02  as _ParamAR02
  composition [0..1] of ZI_DRS_PARAM_AR03  as _ParamAR03
  composition [0..1] of ZI_DRS_PARAM_AP01  as _ParamAP01
  composition [0..1] of ZI_DRS_PARAM_AP02  as _ParamAP02
  composition [0..1] of ZI_DRS_PARAM_AP03  as _ParamAP03

{
  key subscr_uuid           as SubscrUuid,
  key subscr_id             as SubscrId,
      subscr_name           as SubscrName,
      report_id             as ReportId,
      bukrs                 as Bukrs,
      output_format         as OutputFormat,
      email_to              as EmailTo,
      email_cc              as EmailCc,

      Subscription.status   as Status,

      // Admin fields
      @Semantics.user.createdBy: true
      created_by            as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,

      @Semantics.user.lastChangedBy: true
      last_changed_by       as LastChangedBy,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      /* Associations */
      _Catalog,
      _ParamGL01,
      _ParamAR01,
      _ParamAR02,
      _ParamAR03,
      _ParamAP01,
      _ParamAP02,
      _ParamAP03,
      _JobConfig
}
