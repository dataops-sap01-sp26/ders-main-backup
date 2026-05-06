@AccessControl.authorizationCheck: #CHECK
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
          FileCreationDate,

          /* Associations */
          _JobConfig : redirected to parent ZCR_DRS_JOB_CONFIG
}
