@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'File Root Entity'
define view entity ZI_DRS_FILE
  as select from zdrs_file as File
  association to parent ZR_DRS_JOB_CONFIG as _JobConfig on $projection.JobUuid = _JobConfig.JobUuid
{
  key file_uuid    as FileUuid,
      job_uuid     as JobUuid,
      file_name    as FileName,
      mime_type    as MimeType,
      @Semantics.largeObject: {
        mimeType: 'MimeType',
        fileName: 'FileName',
        contentDispositionPreference: #ATTACHMENT
        }
      file_content as FileContent,
      file_size    as FileSize,

      @Semantics.user.createdBy: true
      created_by   as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at   as CreatedAt,
      
      // Association
      _JobConfig
}
