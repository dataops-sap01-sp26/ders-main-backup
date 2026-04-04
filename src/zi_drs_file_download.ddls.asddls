@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Standalone File Entity for Download'
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: false

define view entity ZI_DRS_FILE_DOWNLOAD
  as select from zdrs_file as File
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
      file_size_display as FileSizeDisplay,

      @Semantics.user.createdBy: true
      created_by   as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at   as CreatedAt
}
