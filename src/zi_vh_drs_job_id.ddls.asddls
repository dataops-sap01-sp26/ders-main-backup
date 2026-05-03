@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job ID Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@Search.searchable: true
define view entity ZI_VH_DRS_JOB_ID
  as select from zdrs_job_config
{
      @UI.hidden: true
      key job_uuid,
      
      @EndUserText.label: 'Job ID'
      @UI.lineItem: [{ position: 10 }]
      job_id   as JobId,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @EndUserText.label: 'Job Name'
      @UI.lineItem: [{ position: 20 }]
      job_name as JobName,
 
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @EndUserText.label: 'Description'
      @UI.lineItem: [{ position: 30 }]
      job_text as JobText,
      
      @UI.hidden: true
      created_by  as CreatedBy
}
