// ═══════════════════════════════════════════════════════════════════════════════
// VALUE HELP: Module
// PURPOSE: F4 help for ModuleId field
// ═══════════════════════════════════════════════════════════════════════════════
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Module Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true

define view entity ZI_VH_DRS_MODULE
  as select from zdrs_vt_module
{
      @ObjectModel.text.element: ['ModuleName']
      @UI.hidden: true
  key module_id   as ModuleId,

      @Search.defaultSearchElement: true
      @Semantics.text: true
      module_name as ModuleName,

      description as Description,
      sort_order  as SortOrder
}
where
  is_active = 'X'
