@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job Status Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #CUSTOMIZING
}
define view entity ZI_VH_DRS_JOB_STATUS
  as select from zdrs_jobstat_vt
{
      @UI.lineItem: [{ position: 10 }]
  key value           as JobStatus,

      @UI.lineItem: [{ position: 20 }]
      job_status_text as JobStatusText
}
