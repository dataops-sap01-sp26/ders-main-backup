@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job History Query for Analytics'
@Metadata.ignorePropagatedAnnotations: false
@Analytics.dataCategory: #FACT
@Analytics.internalName: #LOCAL

define view entity ZI_DRS_JOB_HISTORY_FACT
  as select from zdrs_job_history as JobHistoryAnalytics
  association [0..1] to ZIR_DRS_JOB_CONFIG as _JobConfig on $projection.JobUuid = _JobConfig.JobUuid
  association [0..1] to ZI_DRS_FILE        as _File      on $projection.FileUuid = _File.FileUuid
{
  key JobHistoryAnalytics.job_hist_uuid                            as JobHistUuid,
      JobHistoryAnalytics.job_uuid                                 as JobUuid,
      JobHistoryAnalytics.report_id                                as ReportId,
      JobHistoryAnalytics.job_name                                 as JobName,
      JobHistoryAnalytics.job_count                                as JobCount,
      JobHistoryAnalytics.job_catalog_entry                        as JobCatalogEntry,
      JobHistoryAnalytics.job_template_name                        as JobTemplateName,
      JobHistoryAnalytics.start_timestamp                          as StartTimestamp,
      JobHistoryAnalytics.end_timestamp                            as EndTimestamp,
      JobHistoryAnalytics.duration_ms                              as DurationMs,
      JobHistoryAnalytics.file_uuid                                as FileUuid,
      JobHistoryAnalytics.output_format                            as OutputFormat,
      JobHistoryAnalytics.message                                  as Message,
      JobHistoryAnalytics.retry_count                              as RetryCount,
      @Semantics.user.createdBy: true
      JobHistoryAnalytics.created_by                               as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      JobHistoryAnalytics.created_at                               as CreatedAt,
      @Semantics.user.lastChangedBy: true
      JobHistoryAnalytics.last_changed_by                          as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      JobHistoryAnalytics.last_changed_at                          as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      JobHistoryAnalytics.local_last_changed_at                    as LocalLastChangedAt,

      case JobHistoryAnalytics.job_status
          when 'F' then 3  // Finished = Green
          when 'S' then 5  // Scheduled = Blue
          when 'A' then 1  // Failed, Cancel = Red
          else 0
          end                                                      as JobStatusCriticality,

      case JobHistoryAnalytics.job_status
          when 'F' then 'Finished'
          when 'A' then 'Failed'
          when 'S' then 'Scheduled'
          when 'R' then 'Running'
          else JobHistoryAnalytics.job_status
          end                                                      as JobStatus,

      // convert UTC to UTC+7
      tstmp_to_dats( cast( JobHistoryAnalytics.start_timestamp as abap.dec(15,0) ),
                     abap_user_timezone( $session.user, $session.client, 'INITIAL' ),
                     $session.client,
                     'INITIAL' )                                   as ExecutionDate,

      cast( 1 as abap.int4 )                                       as JobCountTotal,

      // Tạo URL tải file động dựa trên DrsFile OData V4 (Ép UUID sang chuỗi Format chuẩn 8-4-4-4-12)
      // Mở rộng thêm tham số IsActiveEntity=true (do DrsFile có Draft Framework nên OData Engine yêu cầu đủ 2 keys: FileUuid & IsActiveEntity)
      cast( case when _File.FileName is null then ''
            else concat( '/sap/opu/odata4/sap/zui_drs_main_o4/srvd/sap/zsd_drs_main/0001/DrsFile(FileUuid=',
                 concat( substring( bintohex( JobHistoryAnalytics.file_uuid ), 1, 8 ),
                 concat( '-',
                 concat( substring( bintohex( JobHistoryAnalytics.file_uuid ), 9, 4 ),
                 concat( '-',
                 concat( substring( bintohex( JobHistoryAnalytics.file_uuid ), 13, 4 ),
                 concat( '-',
                 concat( substring( bintohex( JobHistoryAnalytics.file_uuid ), 17, 4 ),
                 concat( '-',
                 concat( substring( bintohex( JobHistoryAnalytics.file_uuid ), 21, 12 ),
                               ',IsActiveEntity=true)/FileContent'
                       ) ) ) ) ) ) ) ) ) ) end as abap.char(255) ) as FileDownloadUrl,

      _JobConfig.JobId                                             as JobId,
      _JobConfig.JobText                                           as JobText,
      _JobConfig.RunType                                           as RunType,
      _JobConfig.SubscrId                                          as SubscrId,
      _File.FileName                                               as FileName,
      _File.FileSizeDisplay                                        as FileSizeDisplay,
      _File.CreatedAt                                              as FileCreatedAt,
      _File.CreatedBy                                              as FileCreatedBy
}
