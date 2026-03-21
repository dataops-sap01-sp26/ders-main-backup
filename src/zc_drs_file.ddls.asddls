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
          CreatedBy,
          CreatedAt,
          @ObjectModel.virtualElement: true
          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_FILE_SIZE_CALC'
          @EndUserText.label: 'File Size'
  virtual FileSizeDisplay : abap.char(20),

          /* Associations */
          _JobConfig : redirected to parent ZC_DRS_JOB_CONFIG
}
