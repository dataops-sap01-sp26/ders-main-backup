// Root interface entity exposing the Report Catalog master list
// (one row per report registered for the DRS Fiori application).
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Report Catalog - Root Entity'
@Metadata.allowExtensions: true

define root view entity ZIR_DRS_CATALOG
  as select from zdrs_catalog as Catalog

  association [0..1] to zdrs_vt_module as _Module on $projection.ModuleId = _Module.module_id

{
  key report_id                                 as ReportId,
      module_id                                 as ModuleId,
      report_name                               as ReportName,
      description                               as Description,
      long_text                                 as LongText,
      cds_view_name                             as CdsViewName,
      report_class                              as ReportClass,
      is_active                                 as IsActive,
      sort_order                                as SortOrder,

      // Criticality value for IsActive: 3 = positive (active), 1 = negative (inactive).
      case is_active when 'X' then 3 else 1 end as StatusCriticality,

      created_by                                as CreatedBy,
      created_at                                as CreatedAt,
      last_changed_by                           as LastChangedBy,
      last_changed_at                           as LastChangedAt,
      local_last_changed_at                     as LocalLastChangedAt,

      _Module
}
