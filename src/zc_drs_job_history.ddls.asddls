@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job History Projection'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true

define view entity ZC_DRS_JOB_HISTORY
  as projection on ZI_DRS_JOB_HISTORY
{
  key     JobHistUuid,
          JobUuid,
          FileUuid,
          _File.FileName,
          _File.MimeType,
          @Semantics.largeObject: {
            mimeType: 'MimeType',
            fileName: 'FileName',
            contentDispositionPreference: #ATTACHMENT
            }
          _File.FileContent,
          _File.FileSize,
          _File.FileSizeDisplay,
          _File.CreatedAt as FileCreatedAt,
          _File.CreatedBy as FileCreatedBy,
          ReportId,
          JobName,
          JobCount,
          JobCatalogEntry,
          JobTemplateName,
          JobStatus,
          JobStatusCriticality,
          StartTimestamp,
          EndTimestamp,
          DurationMs,
          OutputFormat,
          Message,
          RetryCount,
          CreatedBy,
          CreatedAt,
          LastChangedBy,
          LastChangedAt,
          LocalLastChangedAt,
          JobDate,

          /* Associations */
          _Catalog   : redirected to ZCR_DRS_CATALOG,
          _File      : redirected to ZC_DRS_FILE,
          _JobConfig : redirected to parent ZCR_DRS_JOB_CONFIG

}
