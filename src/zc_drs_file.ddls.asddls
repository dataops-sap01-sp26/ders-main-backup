@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'File Projection'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true
define view entity ZC_DRS_FILE
  as projection on ZI_DRS_FILE
{
  key     FileUuid,
          JobUuid,
          FileName,
          MimeType,
          FileContent,
          FileSize,
          FileSizeDisplay,
          CreatedBy,
          CreatedAt,
          JobDate,

          /* Associations */
          _JobConfig  : redirected to parent ZCR_DRS_JOB_CONFIG,
          _JobHistory : redirected to ZC_DRS_JOB_HISTORY
}
