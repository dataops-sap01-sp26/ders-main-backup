@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Shift Direction Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #CUSTOMIZING
}
define view entity ZI_VH_DRS_SHIFT_DIRECTION
  as select from zdrs_shiftdir_vt
{
  key value          as Value,
      shift_dir_text as ShiftDirectionText
}
