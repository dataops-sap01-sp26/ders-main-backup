@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'File Interface Entity'
define view entity ZI_DRS_FILE
  as select from zdrs_file as File
  association        to parent ZIR_DRS_JOB_CONFIG as _JobConfig  on $projection.JobUuid = _JobConfig.JobUuid
  association [0..*] to ZI_DRS_JOB_HISTORY        as _JobHistory on $projection.FileUuid = _JobHistory.FileUuid
{
  key file_uuid                                                                   as FileUuid,
      job_uuid                                                                    as JobUuid,
      file_name                                                                   as FileName,
      mime_type                                                                   as MimeType,
      @Semantics.largeObject: {
        mimeType: 'MimeType',
        fileName: 'FileName',
        contentDispositionPreference: #ATTACHMENT
        }
      file_content                                                                as FileContent,
      file_size                                                                   as FileSize,
      file_size_display                                                           as FileSizeDisplay,
      @Semantics.user.createdBy: true
      created_by                                                                  as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at                                                                  as CreatedAt,

      cast( substring( cast( created_at as abap.char(23) ), 1, 8 ) as abap.dats ) as FileCreationDate,

      // Association
      _JobConfig,
      _JobHistory
}
