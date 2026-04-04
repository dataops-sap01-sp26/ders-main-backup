@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job History Query for Analytics'
@Metadata.ignorePropagatedAnnotations: false
@Analytics.dataCategory: #FACT
@Analytics.internalName: #LOCAL

define view entity ZI_DRS_JOB_HISTORY_FACT
  as select from    zdrs_job_history     as JobHistoryAnalytics
    left outer join ZIR_DRS_JOB_CONFIG   as _JobConfig    on JobHistoryAnalytics.job_uuid = _JobConfig.JobUuid
    left outer join ZI_DRS_FILE_DOWNLOAD as _FileDownload on JobHistoryAnalytics.file_uuid = _FileDownload.FileUuid
{
  key JobHistoryAnalytics.job_hist_uuid                       as JobHistUuid,
      JobHistoryAnalytics.job_uuid                            as JobUuid,
      JobHistoryAnalytics.report_id                           as ReportId,
      JobHistoryAnalytics.job_name                            as JobName,
      JobHistoryAnalytics.job_count                           as JobCount,
      JobHistoryAnalytics.job_catalog_entry                   as JobCatalogEntry,
      JobHistoryAnalytics.job_template_name                   as JobTemplateName,
      JobHistoryAnalytics.start_timestamp                     as StartTimestamp,
      JobHistoryAnalytics.end_timestamp                       as EndTimestamp,
      JobHistoryAnalytics.duration_ms                         as DurationMs,
      JobHistoryAnalytics.file_uuid                           as FileUuid,
      JobHistoryAnalytics.output_format                       as OutputFormat,
      JobHistoryAnalytics.message                             as Message,
      JobHistoryAnalytics.retry_count                         as RetryCount,
      @Semantics.user.createdBy: true
      JobHistoryAnalytics.created_by                          as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      JobHistoryAnalytics.created_at                          as CreatedAt,
      @Semantics.user.lastChangedBy: true
      JobHistoryAnalytics.last_changed_by                     as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      JobHistoryAnalytics.last_changed_at                     as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      JobHistoryAnalytics.local_last_changed_at               as LocalLastChangedAt,

      case JobHistoryAnalytics.job_status
          when 'F' then 3  // Finished = Green
          when 'S' then 5  // Scheduled = Blue
          when 'A' then 1  // Failed, Cancel = Red
          else 0
          end                                                 as JobStatusCriticality,

      case JobHistoryAnalytics.job_status
          when 'F' then 'Finished'
          when 'A' then 'Failed'
          when 'S' then 'Scheduled'
          when 'R' then 'Running'
          else JobHistoryAnalytics.job_status
          end                                                 as JobStatus,

      // convert UTC to UTC+7
      tstmp_to_dats( cast( JobHistoryAnalytics.start_timestamp as abap.dec(15,0) ),
                     abap_user_timezone( $session.user, $session.client, 'INITIAL' ),
                     $session.client,
                     'INITIAL' )                              as JobDate,

      cast( 1 as abap.int4 )                                  as JobCountTotal,

      // Tạo URL tải file động dựa trên Standalone OData V4 (Ép UUID sang chuỗi Format chuẩn 8-4-4-4-12)
      cast( case when _FileDownload.FileName is null then ''
            else concat( '/sap/opu/odata4/sap/zui_drs_file_download_o4/srvd/sap/zsd_drs_file_download/0001/FileDownloadSet(',
                 concat( substring( bintohex( JobHistoryAnalytics.file_uuid ), 1, 8 ),
                 concat( '-',
                 concat( substring( bintohex( JobHistoryAnalytics.file_uuid ), 9, 4 ),
                 concat( '-',
                 concat( substring( bintohex( JobHistoryAnalytics.file_uuid ), 13, 4 ),
                 concat( '-',
                 concat( substring( bintohex( JobHistoryAnalytics.file_uuid ), 17, 4 ),
                 concat( '-',
                 concat( substring( bintohex( JobHistoryAnalytics.file_uuid ), 21, 12 ),
                               ')/FileContent'
                       ) ) ) ) ) ) ) ) ) ) end as abap.char(255) ) as FileDownloadUrl,


      _JobConfig.JobId                                        as JobId,
      _JobConfig.JobText                                      as JobText,
      _JobConfig.RunType                                      as RunType,
      _JobConfig.SubscrId                                     as SubscrId,
      _FileDownload.FileName                                  as FileName,
      _FileDownload.FileSizeDisplay                           as FileSizeDisplay,
      _FileDownload.CreatedAt                                 as FileCreatedAt,
      _FileDownload.CreatedBy                                 as FileCreatedBy
}
