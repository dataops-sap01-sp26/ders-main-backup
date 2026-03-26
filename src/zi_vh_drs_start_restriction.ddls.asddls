@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Start Restriction Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #CUSTOMIZING
}
define view entity ZI_VH_DRS_START_RESTRICTION
  as select from zdrs_strt_res_vt
{
  key value            as Value,
      start_restr_text as StartRestrictionText
}
