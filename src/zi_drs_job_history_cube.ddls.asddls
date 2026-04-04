@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job History Cube for Analytics'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true
@Analytics.dataCategory: #CUBE
@Analytics.internalName: #LOCAL

define view entity ZI_DRS_JOB_HISTORY_CUBE
  as select from ZI_DRS_JOB_HISTORY_FACT
{
  key JobHistUuid,
      JobUuid,
      ReportId,
      JobName,
      JobCount,
      JobCatalogEntry,
      JobTemplateName,
      StartTimestamp,
      EndTimestamp,
      DurationMs,
      FileUuid,
      OutputFormat,
      Message,
      RetryCount,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,
      JobStatusCriticality,
      JobStatus,
      JobDate,
      @Aggregation.default: #SUM
      JobCountTotal,
      JobId,
      JobText,
      RunType,
      SubscrId,
      FileName,
      FileDownloadUrl,
      FileSizeDisplay,
      FileCreatedAt,
      FileCreatedBy
}
