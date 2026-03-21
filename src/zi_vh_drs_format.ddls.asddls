// ═══════════════════════════════════════════════════════════════════════════════
// VALUE HELP: Format (XLSX, CSV, PDF)
// PURPOSE: F4 help for output format fields
// ═══════════════════════════════════════════════════════════════════════════════
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Format Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true

define view entity ZI_VH_DRS_FORMAT
  as select from zdrs_vt_format
{
      @ObjectModel.text.element: ['FormatName']
      @UI.hidden: true
      key format_id   as FormatId,

      @Search.defaultSearchElement: true
      @Semantics.text: true
      format_name     as FormatName,

      mime_type       as MimeType,
      file_ext        as FileExtension,
      sort_order      as SortOrder
}
where
  is_active = 'X'
