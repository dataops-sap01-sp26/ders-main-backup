// ═══════════════════════════════════════════════════════════════════════════════
// ROOT INTERFACE ENTITY: Report Catalog
// PURPOSE: Master list of available reports (US-E1-001, US-E1-007)
// NAMING: ZIR_ = Z + I(Interface) + R(Root) per FPT Naming Convention
// ═══════════════════════════════════════════════════════════════════════════════
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Report Catalog - Root Entity'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true

define root view entity ZIR_DRS_CATALOG
  as select from zdrs_catalog as Catalog

  -- Association to Value Tables
  association [0..1] to zdrs_vt_module as _Module on $projection.ModuleId = _Module.module_id

{
      // ═══════════════════════════════════════════════════════════════════════════
      // PRIMARY KEY
      // ═══════════════════════════════════════════════════════════════════════════
      key report_id               as ReportId,

      // ═══════════════════════════════════════════════════════════════════════════
      // CLASSIFICATION
      // ═══════════════════════════════════════════════════════════════════════════
      module_id                   as ModuleId,

      // ═══════════════════════════════════════════════════════════════════════════
      // REPORT METADATA
      // ═══════════════════════════════════════════════════════════════════════════
      report_name                 as ReportName,
      description                 as Description,
      long_text                   as LongText,

      // ═══════════════════════════════════════════════════════════════════════════
      // TECHNICAL CONFIGURATION
      // ═══════════════════════════════════════════════════════════════════════════
      cds_view_name               as CdsViewName,
      report_class                as ReportClass,

      // ═══════════════════════════════════════════════════════════════════════════
      // STATUS
      // ═══════════════════════════════════════════════════════════════════════════
      is_active                   as IsActive,
      sort_order                  as SortOrder,
      
      // Virtual field for UI criticality (3=Green/Active, 1=Red/Inactive)
      case is_active when 'X' then 3 else 1 end as StatusCriticality,

      // ═══════════════════════════════════════════════════════════════════════════
      // ADMINISTRATIVE FIELDS (Managed by RAP)
      // ═══════════════════════════════════════════════════════════════════════════
      created_by                  as CreatedBy,
      created_at                  as CreatedAt,
      last_changed_by             as LastChangedBy,
      last_changed_at             as LastChangedAt,
      local_last_changed_at       as LocalLastChangedAt,

      // ═══════════════════════════════════════════════════════════════════════════
      // ASSOCIATIONS
      // ═══════════════════════════════════════════════════════════════════════════
      _Module
}
