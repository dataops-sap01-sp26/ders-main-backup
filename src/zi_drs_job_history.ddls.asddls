@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job History Interface Entity'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_DRS_JOB_HISTORY
  as select from zdrs_job_history as JobHistory
  association        to parent ZIR_DRS_JOB_CONFIG as _JobConfig on $projection.JobUuid = _JobConfig.JobUuid
  association [0..1] to ZI_DRS_FILE               as _File      on $projection.FileUuid = _File.FileUuid
  association [0..1] to ZIR_DRS_CATALOG           as _Catalog   on $projection.ReportId = _Catalog.ReportId
{
  key job_hist_uuid         as JobHistUuid,
      job_uuid              as JobUuid,
      report_id             as ReportId,
      job_name              as JobName,
      job_count             as JobCount,
      job_catalog_entry     as JobCatalogEntry,
      job_template_name     as JobTemplateName,
      job_status            as JobStatus,
      start_timestamp       as StartTimestamp,
      end_timestamp         as EndTimestamp,
      duration_ms           as DurationMs,
      file_uuid             as FileUuid,
      output_format         as OutputFormat,
      message               as Message,
      retry_count           as RetryCount,
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

      case job_status
      when 'F' then 3  // Finished = Green
      when 'S' then 5  // Scheduled = Blue
      when 'A' then 1  // Cancel = Red
      else 0
      end                   as JobStatusCriticality,

      cast( substring( cast( start_timestamp as abap.char(23) ), 1, 8 )
      as abap.dats )        as JobDate,

      // Association
      _JobConfig,
      _File,
      _Catalog
}
