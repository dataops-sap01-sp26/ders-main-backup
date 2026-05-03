// Root projection of the Report Catalog used by the Fiori UI service binding.
// UI annotations are provided by the metadata extension of the same name.
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Report Catalog'
@Metadata.allowExtensions: true
@Search.searchable: true

define root view entity ZCR_DRS_CATALOG
  provider contract transactional_query
  as projection on ZIR_DRS_CATALOG
{
  key ReportId,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_DRS_MODULE', element: 'ModuleId' } }]
      ModuleId,

      ReportName,
      Description,
      LongText,

      CdsViewName,
      ReportClass,

      IsActive,
      SortOrder,
      StatusCriticality,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,

      _Module
}
